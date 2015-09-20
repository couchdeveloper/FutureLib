//
//  ExecutionContext.swift
//  FutureLib
//
//  Created by Andreas Grosam on 04/04/15.
//
//

import Dispatch



/**
An ExecutionContext is a thing that can execute closures either synchronous-
ly or asynchronously with respect to the call-site. It's also a means to
establish concurrency rules for shared variables which will be accessed from
more than one closure executed on the same execution context.

An execution context may (implicitly) define a "synchronizes-with" and a
"happens-before" relationship between operations performed on different
closures which execute on the _same_ execution context - but not necessarily
on the same thread.

The ”Synchronizes-with” and "happens-before" relationship describes ways in
which the memory effects of the program statements are guaranteed to become
visible to other threads. In other words, if there is a synchronizes-with"
and a "happens-before" relationship, the rules about concurrency when
operations performed on different closures access shared variables, is
considered "thread-safe".

The most simple way to achieve a "synchronizes-with" and a "happens-before"
relationship is to let closures execute on the same thread - the thread
identified as the _execution context. Other ways to achieve this is to
use mutex/critical sections, dispatch_queues etc.
*/





public protocol ExecutionContext {
    
    func execute(f:()->())
    func schedule<T>(future : Future<T>, f : ()->())
}

public protocol SyncExecutionContext : ExecutionContext { }
public protocol AsyncExecutionContext : ExecutionContext { }
public protocol BarrierSyncExecutionContext : SyncExecutionContext { }
public protocol BarrierAsyncExecutionContext : AsyncExecutionContext { }


public extension ExecutionContext {

    public func schedule<T>(future : Future<T>, f:()->()) {
        execute(f)
    }

}


/**
    A private concrete implementation of the protocol `SyncExecutionContext` which
    synchronously executes a given closure on the _current_ execution context.
    This class is used internally by FutureLib.
*/
internal struct SynchronousCurrent : SyncExecutionContext {
    
    /**
    Synchronuosly executes the given closure `f` on its execution context.
    
    - parameter f: The closure takeing no parameters and returning ().
    */
    internal func execute(f:()->()) {
        f()
    }
}




//// For GCD

public struct GCDSyncExecutionContext : SyncExecutionContext {
    
    let _queue : dispatch_queue_t
    
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        _queue = q
    }
    
    public func execute(f:()->()) {
        dispatch_sync(_queue,f)
    }
    
}

public struct GCDAsyncExecutionContext : AsyncExecutionContext {
    
    let _queue : dispatch_queue_t
    
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        _queue = q
    }
    
    public func execute(f:()->()) {
        dispatch_async(_queue,f)
    }
    
}


public struct GCDBarrierSyncExecutionContext : BarrierSyncExecutionContext {
    
    let _queue : dispatch_queue_t
    
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        _queue = q
    }
    
    public func execute(f:()->()) {
        dispatch_barrier_sync(_queue,f)
    }
    
}

public struct GCDBarrierAsyncExecutionContext : BarrierAsyncExecutionContext {
    
    let _queue : dispatch_queue_t
    
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        _queue = q
    }
    
    public func execute(f:()->()) {
        dispatch_barrier_async(_queue,f)
    }
    
}




    /**
        Executes the given closure `f` on its execution context. The concrete 
        execution context should define whether the closure `f` is invoked 
        asynchronously or synchronously with respect to the caller through conforming 
        to either the protocol `AsynchronousTrait` respectively `SynchronousTrait`.
    
        `execute()` _must immediately_ schedule the closure - that is, it _must_
        not block. That implies, that for example in execution contexts where the
        number of concurrent tasks is limited must not block. Care should be taken
        for execution contexts which schedule the closure `f` _synchronously_ since
        it may happen that the execution of the closure will be deferred and thus
        `execute()` will block.

        The `execute` method will be itself called on a private synchronization
        context used internally by the future implementation. Due to potential
        blocking and dead-lock issues it is strongly discouraged to use a synchronous 
        context! So, unless you know what you are doing always use a context which
        schedules the closure `f` _asynchronously_!
    
        - parameter f: The closure taking no parameters and returning ().
    */
    
    
    /**
        Executes the given closure `f` on its execution context. The concrete 
        execution context should define whether the closure `f` is invoked 
        asynchronously or synchronously with respect to the caller through conforming 
        to either the protocol `AsynchronousTrait` respectively `SynchronousTrait`.
    
        This method assumes closure `f` executes an asycnhronous task which produces
        an "eventual result" represented by a Future. At the call-site the closure
        will import a `Promise` which gets resolved when the actual task completes. 
        The promise's corresponding `future` will be passed as an argument to the 
        `execute` method. A concrete implmentation can determine when the actual
        task has been completed by registering continuations for that future.
    
    
        - parameter future: A future provided by the call-site which represents
                            the eventual result produced by a task invoked by the
                            closure `f`.
                            Oftentimes the parameter can be ignored - unless for
                            certain implementations of execution contexts, for example
                            where the context executes asynchronous tasks where
                            the number of maximum concurrent tasks can be specified.
        
        - parameter f: The closure taking no parameters and returning ().
    */
    

