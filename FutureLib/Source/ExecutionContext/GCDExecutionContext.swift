//
//  GCDExecutionContext.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


public struct GCDSyncExecutionContext : ExecutionContext {
    
    public let queue: dispatch_queue_t
    
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        queue = q
    }
    
    /**
     Schedules the closure `f` for execution on its dispatch queue.
     
     - parameter f: A closure which is being scheduled.
     */
    public func execute(f: ()->()) {
        dispatch_sync(queue,f)
    }
    
}

public struct GCDAsyncExecutionContext : ExecutionContext {
    
    public let queue: dispatch_queue_t
    
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        queue = q
    }
    
    /**
     Schedules the closure `f` for execution on its dispatch queue.
     
     - parameter f: A closure which is being scheduled.
     */
    public func execute(f: ()->()) {
        dispatch_async(queue,f)
    }
    
}


public struct GCDBarrierSyncExecutionContext : ExecutionContext {
    
    public let queue: dispatch_queue_t
    
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        queue = q
    }
    
    /**
     Schedules the closure `f` for execution on its dispatch queue.
     
     - parameter f: A closure which is being scheduled.
     */
    public func execute(f: ()->()) {
        dispatch_barrier_sync(queue,f)
    }
    
}

public struct GCDBarrierAsyncExecutionContext : ExecutionContext {
    
    public let queue: dispatch_queue_t
    
    public init(_ q: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
        queue = q
    }
    
    /**
     Schedules the closure `f` for execution on its dispatch queue.
     
     - parameter f: A closure which is being scheduled.
     */
    public func execute(f: ()->()) {
        dispatch_barrier_async(queue,f)
    }
    
}


