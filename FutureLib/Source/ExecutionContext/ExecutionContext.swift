//
//  ExecutionContext.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch



/**
    An `ExecutionContext` can execute "unit of works". A "unit of work" is either
    a _closure_ or a _task_ represented by a `Future`. The "unit of work" will be
    first enqueued, then executed and finally dequeued from the `ExecutionContext`
    when it has been completed. A closure will always completely execute on its 
    `ExecutionContext`. On the other hande, a _task_ only executes the prolog
    and possibly its epilog on this `ExecutionContext` - but the main work will 
    usually execute asynchronously on a private `ExecutionContext`.

    Executing the "unit of work" performs either synchronously or asynchronously 
    with respect to the call-site. An `ExecutionContext` can also possibly execute 
    more than one "unit of works" concurrently.

    Additionally, an `ExecutionContext` _can_ be used to describe concurrency 
    constraints for shared variables which will be accessed from operations performed 
    in more than one closures executed on the _same_ `ExecutionContext`. Concurrency
    constraints are only meaningful for closures, since those actually execute on
    the given `ExecutionContext`. For _tasks_ other properties may be more important, 
    for example the maximum concurrent tasks which can be executed in one 
    `ExecutionContext`.

    In order to define concurency constraints, an `ExecutionContext` may (implicitly)
    define a "synchronizes-with" and a "happens-before" relationship between operations 
    performed on different closures which execute on the _same_ execution context - 
    but not necessarily on the same thread.

    The ”Synchronizes-with” and "happens-before" relationship describes ways in
    which the memory effects of the program statements are guaranteed to become
    visible to other threads. In other words, if there is a synchronizes-with"
    and a "happens-before" relationship, then operations performed on different 
    closures accessing shared variables is considered "thread-safe".

    The most simple way to achieve a "synchronizes-with" and a "happens-before"
    relationship is to let closures execute on the same thread - the thread
    identified as the _execution context_. Other ways to achieve this is to
    use mutex/critical sections, dispatch_queues etc.


    > Note: The FutureLib is completely agnostic to those properties of concrete 
    implementations of an `ExecutionContext`.

*/
public protocol ExecutionContext {
    
    /**
     Schedules the closure `f` for execution on the Execution Context.
     
     - parameter f: A closure which is being scheduled.
    */
    func execute(f: () -> ())
    
    
    /**
     Submits a task `task` for execution on the execution context. When the task has been
     started and a future has been returned, the closure `start` will be called
     with the task's future as the argument.

     - parameter task: A closure which is being scheduled.
     
     - parameter start: A closure that is called when the `task` is being scheduled.
     */
    func schedule<FT: FutureType>(task: () -> FT, start: FT -> ())

    
    /**
     Submits a task `task` for exection on the execution context and returns a
     new future which will be completed with the future returned from the given task
     when it has been started.
     
     - parameter task: A closure which is being scheduled.
     
     - parameter start: A closure that is called when the `task` is being scheduled.
     */
    func schedule<FT: FutureType>(task: () -> FT) -> Future<FT>
    
}


//public protocol SyncExecutionContext : ExecutionContext { }
//public protocol AsyncExecutionContext : ExecutionContext { }
//public protocol BarrierSyncExecutionContext : SyncExecutionContext { }
//public protocol BarrierAsyncExecutionContext : AsyncExecutionContext { }


public extension ExecutionContext {
    
    /**
     Default implementation.
     Immediately start the task on the execution context.
    
     - parameter task: A closure which is being scheduled.
     - parameter start: A closure that is called when the `task` is being scheduled.
     */
    final func schedule<FT: FutureType>(task: () -> FT, start: FT -> ()) {
        execute {
            start(task())
        }
    }


    final func schedule<FT: FutureType>(task: () -> FT) -> Future<FT> {
        let returnedFuture = Future<FT>()
        schedule(task) { returnedFuture.complete(Result<FT>($0)) }
        return returnedFuture
    }

    
}



public struct MainThreadAsync : ExecutionContext {
    public init() {}
    public func execute(f: () -> ()) {
        dispatch_async(dispatch_get_main_queue(), f)
    }
}


public struct MainThreadSync : ExecutionContext {
    public init() {}
    public func execute(f: () -> ()) {
        dispatch_sync(dispatch_get_main_queue(), f)
    }
}


public struct ConcurrentAsync : ExecutionContext {
    public init() {}
    public func execute(f: () -> ()) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), f)
    }
}

public struct ConcurrentSync : ExecutionContext {
    public init() {}
    public func execute(f: () -> ()) {
        dispatch_sync(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), f)
    }
}


/**
    A private concrete implementation of the protocol `SyncExecutionContext` which
    synchronously executes a given closure on the _current_ execution context.
    This class is used internally by FutureLib.
*/
internal struct SynchronousCurrent : ExecutionContext {
    
    
    /**
     Synchronously executes the given closure `f` on its execution context.
     
     - parameter f: The closure takeing no parameters and returning ().
    */
    internal func execute(f: ()->()) {
        f()
    }
    
    internal func schedule<FT: FutureType>(task: () -> FT, start: FT -> ()) {
        start(task())
    }
 
    
}



