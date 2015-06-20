//
//  ExecutionContext.swift
//  Future
//
//  Created by Andreas Grosam on 04/04/15.
//
//

import Foundation



public protocol Asynchron {}
public protocol Synchron {}

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
    
    /**
        Executes the given closure `f` on its execution context. The concrete 
        execution context should define whether the call is invoked asynchronously 
        or synchronously through conforming to either the protocol `Asynchron` 
        respectively `Synchron`.

        - parameter f: The closure taking no parameters and returning ().
    */
    func execute(f:()->()) -> ()
}





// MARK: - ExecutionContext Extension


extension dispatch_queue_t : ExecutionContext, Asynchron {
    public func execute(f:()->()) -> () {
        dispatch_async(self, f)
    }
}




public struct AsyncExecutionContext : ExecutionContext, Asynchron {
    
    let _queue : dispatch_queue_t

    public init(queue: dispatch_queue_t) {
        _queue = queue
    }
    
    public func execute(f:()->()) -> () {
        dispatch_async(_queue, f)
    }
  
}

public struct SyncExecutionContext : ExecutionContext, Synchron {
    
    let _queue : dispatch_queue_t
    
    public init(queue: dispatch_queue_t) {
        _queue = queue
    }
    
    public func execute(f:()->()) -> () {
        dispatch_sync(_queue, f)
    }
    
}