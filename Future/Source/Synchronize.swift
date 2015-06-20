//
//  Synchronize.swift
//  Future
//
//  Created by Andreas Grosam on 04/04/15.
//
//

import Foundation




private var queue_ID_key = 0



public struct Synchronize {
    
    public let sync_queue: dispatch_queue_t
    
    init(name: String) {
        sync_queue = dispatch_queue_create(name, DISPATCH_QUEUE_CONCURRENT)!
        let ptr = UnsafeMutablePointer<Void>(Unmanaged<dispatch_queue_t>.passUnretained(sync_queue).toOpaque())
        dispatch_queue_set_specific(sync_queue, &queue_ID_key, ptr, nil)
    }

    /// Returns true if the current execution context is the sync_queue
    public func on_sync_queue() -> Bool {
        let ptr = UnsafeMutablePointer<Void>(Unmanaged<dispatch_queue_t>.passUnretained(sync_queue).toOpaque())
        return dispatch_get_specific(&queue_ID_key) == ptr
    }



    
    //private func read_sync<T>(f: @autoclosure ()->T) -> T {
    //    var v: T
    //    dispatch_sync(s_sync_queue) { v = closure() }
    //    return v
    //}
    
    /// The function read_sync_safe executes the closure on the synchronization execution
    /// context and waits for completion.
    /// The closure can safely read the objects associated to the context. However,
    /// the closure must not modify the objects associated to the context.
    /// If the current execution context is already the synchronization context the
    /// function directly calls the closure. Otherwise it dispatches it on the synchronization
    /// context.
    public func read_sync_safe(f: ()->()) -> () {
        if on_sync_queue() {
            f()
        }
        else {
            dispatch_sync(sync_queue, f)
        }
    }
    
    /// The function read_sync executes the closure on the synchronization execution
    /// context and waits for completion.
    /// The current execution context must not already be the synchronization context,
    /// otherwise the function will dead lock.
    /// The closure can safely read the objects associated to the context. However,
    /// the closure must not modify the objects associated to the context.
    /// The closue will be dispatched on the synchronization context and waits for completion.
    public func read_sync(f: ()->()) -> () {
        dispatch_sync(sync_queue, f)
    }
    
    /// The function write_async asynchronously executes the closure on the synchronization
    /// execution context and returns immediately.
    /// The closure can safely modify the objects associated to the context. No other
    /// concurrent read or write operation can interfere.
    public func write_async(f: ()->()) -> () {
        dispatch_barrier_async(sync_queue, f)
    }
    
    /// The function write_sync executes the closure on the synchronization execution
    /// context and waits for completion.
    /// The closure can modify the objects associated to the context. No other
    /// concurrent read or write operation can interfere.
    /// The current execution context must not already be the synchronization context,
    /// otherwise the function will dead lock.
    public func write_sync(f: ()->()) -> () {
        dispatch_barrier_sync(sync_queue, f)
    }
    
    

}

