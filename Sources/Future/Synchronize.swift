//
//  Synchronize.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch

private var queueIDKey = DispatchSpecificKey<ObjectIdentifier>()


/**
 A Synchronization object which uses a serial dispatch_queue to enforce
 "Synchronize-With" and "Happens-Before" relationship.
 
 - Bug: When submitting a closure with `syncQueue.async(flags: .barrier)` which 
 imports a variable, the imported object will not be released and will leak.
 To alleviate the issue, the sync queue will be created as a serial queue, and
 `writeAsync` must not submit the closure with flag `.barrier`.
         

*/
struct Synchronize {

    internal let syncQueue: DispatchQueue
    static let name: StaticString = "sync-queue"

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
        // TODO: syncQueue = DispatchQueue(label: name, attributes: [.qosUserInteractive, .concurrent])
        syncQueue = DispatchQueue(label: name)
        // Use the pointer value to syncQueue as the context in order to have
        // a unique context:
        let syncQueueId = ObjectIdentifier(syncQueue)
        syncQueue.setSpecific(key: queueIDKey, value: syncQueueId)
    }


    /**
        Returns true if the current thread is synchronized with `self`'s synchronization context.
    */
    func isSynchronized() -> Bool {
        let syncQueueId = ObjectIdentifier(syncQueue)
        return DispatchQueue.getSpecific(key: queueIDKey) == syncQueueId 
    }




    //private func readSync<T>(f: @autoclosure ()->T) -> T {
    //    var v: T
    //    dispatch_sync(s_sync_queue) { v = closure() }
    //    return v
    //}

    /// The function `readSyncSafe` ensures that the nonescaping closure `f` will be
    /// synchronoulsy executed on the synchronization context.
    /// The closure can safely read the objects associated with the context. However,
    /// the closure must not modify the objects associated with the context.
    /// - parameter f: The closure.
    func readSyncSafe( _ f: () -> ()) {
        if isSynchronized() {
            f()
        } else {
            syncQueue.sync(execute: f)
        }
    }

    /// The function `readSync` synchronously executes the closure `f` on the 
    /// synchronization context.
    /// The current execution context MUST NOT already be the synchronization context,
    /// otherwise the function will dead lock.
    /// The closure can safely read the objects associated to the context. However,
    /// the closure must not modify the objects associated to the context.
    /// - parameter f: The closure.
    func readSync(_ f: () -> ()) {
        assert(!isSynchronized(), "Will deadlock")
        syncQueue.sync(execute: f)
    }

    /// The function `writeAsync` asynchronously executes the closure on the synchronization
    /// context and returns immediately.
    /// The closure can safely modify the objects associated to the context. No other
    /// concurrent read or write operation can interfere.
    /// - parameter f: The closure.
    func writeAsync(_ f: @escaping () -> ()) {
        //FIXME: syncQueue.async(flags: .barrier, execute: f)
        syncQueue.async(execute: f)
    }

    /// The function writeSync executes the closure on the synchronization execution
    /// context and waits for completion.
    /// The closure can modify the objects associated to the context. No other
    /// concurrent read or write operation can interfere.
    /// The current execution context must not already be the synchronization context,
    /// otherwise the function will dead lock.
    /// - parameter f: The closure.
    func writeSync(_ f: () -> ()) {
        assert(!isSynchronized(), "Will deadlock")
        // FIXME: syncQueue.sync(flags: .barrier, execute: f)
        syncQueue.sync(execute: f)
    }



}
