//
//  GCDExecutionContext.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


/**
 `GCDSyncExecutionContext` is an execution context which executes its workloads 
 on a GCD dispatch queue. Submitting closures to `self` will be a synchronous function.
 */
public struct GCDSyncExecutionContext: ExecutionContext {

    /// - returns: The dispatch queue.
    public let queue: dispatch_queue_t

    /**
     Initializes a `GCDSyncExecutionContext` with the given dispatch queue.
     
     If the dispatch queue is not specified a global dispatch queue will be used
     whose QOS is set to `QOS_CLASS_DEFAULT`.
     
     - parameter q: A dispatch queue.
     */
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        queue = q
    }

    /**
     Schedules the closure `f` for execution on its dispatch queue using the
     `dispatch_sync` function.

     - parameter f: A closure which is being scheduled.
     */
    public func execute(f: ()->()) {
        dispatch_sync(queue, f)
    }

}


/**
 `GCDAsyncExecutionContext` is an execution context which executes its workloads
 on a GCD dispatch queue. Submitting closures to `self` will be an asynchronous function.
 */
public struct GCDAsyncExecutionContext: ExecutionContext {

    /// - returns: The dispatch queue.
    public let queue: dispatch_queue_t

    /**
     Initializes a `GCDAsyncExecutionContext` with the given dispatch queue.
     
     If the dispatch queue is not specified a global dispatch queue will be used
     whose QOS is set to `QOS_CLASS_DEFAULT`.
     
     - parameter q: A dispatch queue.
     */
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        queue = q
    }

    /**
     Schedules the closure `f` for execution on its dispatch queue using the
     `dispatch_async` function.

     - parameter f: A closure which is being scheduled.
     */
    public func execute(f: ()->()) {
        dispatch_async(queue, f)
    }

}


/**
 `GCDBarrierSyncExecutionContext` is an execution context which executes its workloads
 as a "barrier operation" on a GCD dispatch queue. Submitting closures to `self`
 will be a synchronous function.
 */
public struct GCDBarrierSyncExecutionContext: ExecutionContext {

    /// - returns: The dispatch queue.
    public let queue: dispatch_queue_t

    /**
     Initializes a `GCDBarrierSyncExecutionContext` with the given dispatch queue.
     
     If the dispatch queue is not specified a global dispatch queue will be used
     whose QOS is set to `QOS_CLASS_DEFAULT`.
     
     - parameter q: A dispatch queue.
    */
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        queue = q
    }

    /**
     Schedules the closure `f` for execution on its dispatch queue using the
     `dispatch_barrier_sync` function.

     - parameter f: A closure which is being scheduled.
     */
    public func execute(f: ()->()) {
        dispatch_barrier_sync(queue, f)
    }

}

/**
 `GCDBarrierAsyncExecutionContext` is an execution context which executes its workloads
 as a "barrier operation" on a GCD dispatch queue. Submitting closures to `self`
 will be an asynchronous function.
 */
public struct GCDBarrierAsyncExecutionContext: ExecutionContext {

    /// - returns: The dispatch queue.
    public let queue: dispatch_queue_t

    /**
     Initializes a `GCDBarrierAsyncExecutionContext` with the given dispatch queue.
     
     If the dispatch queue is not specified a global dispatch queue will be used
     whose QOS is set to `QOS_CLASS_DEFAULT`.
     
     - parameter q: A dispatch queue.
     */
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        queue = q
    }

    /**
     Schedules the closure `f` for execution on its dispatch queue using the
     `dispatch_barrier_async` function.

     - parameter f: A closure which is being scheduled.
     */
    public func execute(f: ()->()) {
        dispatch_barrier_async(queue, f)
    }

}
