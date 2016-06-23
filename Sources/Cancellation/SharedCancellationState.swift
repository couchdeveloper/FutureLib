//
//  SharedCancellationState.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


/**
 A BinaryFuture can have the following states:
  - pending, or
  - completed with a boolean value
 
 In the _pending_ case, the value contains an array of closures. In the 
 _completed_ state, the value contains a boolean value which is true, if `self`
 has been cancelled, and `false` if `self` has been completed without a
 cancellation request.
 
 The cancellation state can register cancellation handlers if it is in the 
 pending state. Otherwise, it will be executed immediately. Registered handlers 
 will be executed when `self` will be completed.  
 
 After completing `self` all handlers will run and will be subsequently released.
*/
private enum BinaryFuture {
    typealias ClosureRegistryType = ClosureRegistry<Bool>

    case pending(_: ClosureRegistryType)
    case completed(_: Bool)

    private init() {
        self = .pending(ClosureRegistryType())
    }

    private init(value: Bool) {
        self = .completed(value)
    }

    private var isCompleted: Bool {
        switch self {
        case .completed: return true
        default: return false
        }
    }

    private var value: Bool? {
        switch self {
        case .completed(let v): return v
        default: return nil
        }
    }

    private mutating func complete(value: Bool) {
        switch self {
        case .pending(let handlers):
            handlers.resume(value)
            self = .completed(value)
        case .completed: break
        }
    }

    private mutating func register(_ f: (Bool)->()) -> Int {
        var result: Int = -1
        switch self {
        case .pending(var cr):
            result = cr.register(f)
            self = .pending(cr)

        case .completed(let cancelled): f(cancelled)
        }
        return result
    }

    /**
     Unregister the closure previously registered with `register`.

     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    private func unregister(_ id: Int) {
        switch self {
        case .pending(var cr):
            _ = cr.unregister(id)
        default: break
        }
    }

}

private var queueIDKey = DispatchSpecificKey<ObjectIdentifier>()
private let syncQueue: DispatchQueue = {
    let queue = DispatchQueue(label: "cancellation.sync_queue", attributes: DispatchQueueAttributes.serial)
    queue.setSpecific(key: queueIDKey, value: ObjectIdentifier(queue))
    return queue
}()
private func isSynchronized() -> Bool {
    return DispatchQueue.getSpecific(key: queueIDKey) == ObjectIdentifier(syncQueue) 
}



/**
 A `CancellationState` represents the state of a cancellation request and its
 cancellation token. Both share the identical value which is wrapped into a
 `SharedCancellationState` object.
 
*/
internal final class SharedCancellationState {

    private let future = UnsafeMutablePointer<BinaryFuture>(allocatingCapacity: 1)

    init() {
        future.initialize(with: BinaryFuture())
    }
    
    deinit {
        // We cannot determine whether deinit is beeing called within syncQueue or any other context!
        if isSynchronized() {
            future.deinitialize(count: 1)
        } else {
            let ptr = future
            syncQueue.sync {      
                ptr.deinitialize(count: 1)
            }
        }
    }
    
    final var isCompleted: Bool {
        return syncQueue.sync {
            self.future.pointee.isCompleted
        }
    }

    final var isCancelled: Bool {
        return syncQueue.sync {
            if let value = self.future.pointee.value {
                return value == true
            } else {
                return false
            } 
        }
    }

    final func cancel() {
        let ptr = future
        syncQueue.async {
            ptr.pointee.complete(value: true)
        }
    }

    final func invalidate() {
        let ptr = future
        syncQueue.async {
            ptr.pointee.complete(value: false)
        }
    }

    /**
     Register a closure which will be called when `self` has been completed.

     - parameter on: An execution context where function `f` will be executed.
     - parameter f: The closure which will be executed.
     - returns: An id which represents the registered closure which can be used
     to unregister it again.
     */
    final func register(on executor: ExecutionContext, f: (Bool)->()) -> Int {
        return syncQueue.sync {
            return self.future.pointee.register { cancelled in
                executor.execute {
                    f(cancelled)
                }
            }
        }
    }

    /**
     Unregister the closure previously registered with `register`.

     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    final func unregister(_ id: Int) {
        let ptr = future
        syncQueue.async {
            ptr.pointee.unregister(id)
        }
    }

    final func onCancel(on executor: ExecutionContext,
        cancelable: Cancelable,
        f: (Cancelable)->()) -> Int {
        return syncQueue.sync {
            return self.future.pointee.register { cancelled in
                if cancelled {
                    executor.execute {
                        f(cancelable)
                    }
                }
                _ = self // keep a reference in order to prevent from premature deinitialization
            }
        }
    }

    final func onCancel(on executor: ExecutionContext, f: ()->()) -> Int {
        return syncQueue.sync {
            return self.future.pointee.register { cancelled in
                if cancelled {
                    executor.execute(f)
                }
                _ = self // keep a reference in order to prevent from premature deinitialization
            }
        }
    }

}
