//
//  Synchronize.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


private var queueIDKey = 0


/**
    A Synchronization object which uses a serial dispatch_queue to enforce
    "Synchronize-With" and "Happens-Before" relationship.
*/
struct Synchronize {

    let syncQueue: dispatch_queue_t

    /**
        Initialize a Synchronize struct with a given name.

        - parameter name: A name which should be unique.
    */
    init(name: String) {
        // Using a *serial* queue seems to safe CPU cycles. However, since the queue
        // is shared among all futures, using a serial queue might be prone to
        // dead-locks. For example: on that queue the execution context's `execute()`
        // method will be executed. If this `execute()` method schedules its closure
        // - given as an argument - synchronously, it may unintentionally and unexpectedly
        // block or even dead-lock.
        syncQueue = dispatch_queue_create(name,
            dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,
                QOS_CLASS_USER_INTERACTIVE, 0))

        // Use the pointer value to syncQueue as the context in order to have
        // a unique context:
        let context = UnsafeMutablePointer<Void>(Unmanaged<dispatch_queue_t>.passUnretained(syncQueue).toOpaque())
        dispatch_queue_set_specific(syncQueue, &queueIDKey, context, nil)
    }


    /**
        Returns true if the current thread is synchronized with the syncQueue.
    */
    func isSynchronized() -> Bool {
        let context = UnsafeMutablePointer<Void>(Unmanaged<dispatch_queue_t>.passUnretained(syncQueue).toOpaque())
        return dispatch_get_specific(&queueIDKey) == context
    }




    //private func readSync<T>(f: @autoclosure ()->T) -> T {
    //    var v: T
    //    dispatch_sync(s_sync_queue) { v = closure() }
    //    return v
    //}

    /// The function readSyncSafe executes the closure on the synchronization execution
    /// context and waits for completion.
    /// The closure can safely read the objects associated to the context. However,
    /// the closure must not modify the objects associated to the context.
    /// If the current execution context is already the synchronization context the
    /// function directly calls the closure. Otherwise it dispatches it on the synchronization
    /// context.
    /// - parameter f: The closure.
    func readSyncSafe(/*@noescape*/ f: () -> ()) {
        if isSynchronized() {
            f()
        } else {
            dispatch_sync(syncQueue, f)
        }
    }

    /// The function readSync executes the closure on the synchronization execution
    /// context and waits for completion.
    /// The current execution context must not already be the synchronization context,
    /// otherwise the function will dead lock.
    /// The closure can safely read the objects associated to the context. However,
    /// the closure must not modify the objects associated to the context.
    /// The closure will be dispatched on the synchronization context and waits for completion.
    /// - parameter f: The closure.
    func readSync(/*@noescape*/ f: () -> ()) {
        assert(!isSynchronized(), "Will deadlock")
        dispatch_sync(syncQueue, f)
    }

    /// The function writeAsync asynchronously executes the closure on the synchronization
    /// execution context and returns immediately.
    /// The closure can safely modify the objects associated to the context. No other
    /// concurrent read or write operation can interfere.
    /// - parameter f: The closure.
    func writeAsync(f: () -> ()) {
        dispatch_barrier_async(syncQueue, f)
    }

    /// The function writeSync executes the closure on the synchronization execution
    /// context and waits for completion.
    /// The closure can modify the objects associated to the context. No other
    /// concurrent read or write operation can interfere.
    /// The current execution context must not already be the synchronization context,
    /// otherwise the function will dead lock.
    /// - parameter f: The closure.
    func writeSync(/*@noescape*/ f: () -> ()) {
        assert(!isSynchronized(), "Will deadlock")
        dispatch_barrier_sync(syncQueue, f)
    }



}
