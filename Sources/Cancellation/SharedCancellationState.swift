//
//  SharedCancellationState.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


internal struct HandlerRegistry<T> {
    //typealias ClosureType = (T) -> ()
    typealias HandlerId = Int
    typealias Handler = (HandlerId, (T) -> ())
    
    private var handlers: [Handler] = []
    private var _id: Int = 0

    var count: Int { return self.handlers.count }
    
    mutating func register(_ f: @escaping (T) -> ()) -> HandlerId {
        let id = _id
        self.handlers.append((id, f))
        _id += 1
        return id
    }

    mutating func unregister(_ id: HandlerId) -> Handler? {
        guard let callback = self.handlers.filter( { callback in
            callback.0 == id
        }).first else {
            return nil
        }
        return callback
    }

    func resume(_ value: T) {
        execute(withParameter: value)
    }
    
    func execute(withParameter value: T) {
        self.handlers.forEach { (_, f) in
            f(value)
        }
    }
    
    mutating func invalidate() {
        self.handlers = []
    }
}


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
internal enum BinaryFuture {
    internal typealias ClosureRegistryType = HandlerRegistry<Bool>

    case pending(_: ClosureRegistryType)
    case completed(_: Bool)

    fileprivate init() {
        self = .pending(ClosureRegistryType())
    }

    fileprivate init(value: Bool) {
        self = .completed(value)
    }

    fileprivate var isCompleted: Bool {
        switch self {
        case .completed: return true
        default: return false
        }
    }

    fileprivate var value: Bool? {
        switch self {
        case .completed(let v): return v
        default: return nil
        }
    }

    fileprivate mutating func complete(value: Bool) {
        switch self {
        case .pending(let handlers):
            handlers.resume(value)
            self = .completed(value)
        case .completed: break
        }
    }

    fileprivate mutating func register(_ f: @escaping (Bool)->()) -> Int {
        var result: Int = -1
        switch self {
        case .pending(var cr):
            result = cr.register(f)
            self = .pending(cr)

        case .completed(let cancelled): 
            f(cancelled)
        }
        return result
    }

    /**
     Unregister the closure previously registered with `register`.

     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    fileprivate func unregister(_ id: Int) {
        switch self {
        case .pending(var cr):
            _ = cr.unregister(id)
        default: break
        }
    }

}

private var queueIDKey = DispatchSpecificKey<ObjectIdentifier>()
private let syncQueue: DispatchQueue = {
    let queue = DispatchQueue(label: "cancellation.sync_queue")
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
internal final class SharedCancellationState: ManagedBuffer<(), BinaryFuture> {

    final class func create() -> SharedCancellationState {
        return SharedCancellationState.create(minimumCapacity: 1) { managedBuffer in
            managedBuffer.withUnsafeMutablePointerToElements { future in                
                future.initialize(to: BinaryFuture())
            }
        } as! SharedCancellationState
    }
    
    deinit {
        // Ensure members will be deinitialized on the sync queue. In most practical
        // circumstances, this is effectively a no-op since almost always the future 
        // has been completed and all handlers are deallocated already. Nonetheless
        // this requires access to the future which must be synchronized. If the
        // future is not completed, handlers may exists which will be released
        // while the future is deinitialized.
        // Since deinit requires synchronized access to future, we need to make
        // deinitialization explicit.
        // Since we cannot determine whether deinit is beeing called within syncQueue 
        // or any other execution context - we need to check it explicitly and
        // switch accordingly:
        if isSynchronized() {
            self.withUnsafeMutablePointerToElements { future in
                future.deinitialize()
            }
        } else {
            syncQueue.sync {      
                self.withUnsafeMutablePointerToElements { future in
                    future.deinitialize()
                }
            }
        }
    }
    
    final var isCompleted: Bool {
        return syncQueue.sync {
            return withUnsafeMutablePointerToElements { future in                
                future.pointee.isCompleted
            }
        }
    }

    final var isCancelled: Bool {
        return syncQueue.sync {
            return withUnsafeMutablePointerToElements { future in
                if let value = future.pointee.value {
                    return value == true
                } else {
                    return false
                } 
            }
        }
    }

    final func cancel() {
        syncQueue.async {
            self.withUnsafeMutablePointerToElements { future in                 
                future.pointee.complete(value: true)
            }
        }
    }

    final func invalidate() {
        syncQueue.async {
            self.withUnsafeMutablePointerToElements { future in                 
                future.pointee.complete(value: false)
            }
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
            return self.withUnsafeMutablePointerToElements { future in 
                return future.pointee.register { cancelled in
                    executor.execute {
                        f(cancelled)
                    }
                }
            }                 
        }
    }

    /**
     Unregister the closure previously registered with `register`.

     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    final func unregister(_ id: Int) {
        syncQueue.async {
            self.withUnsafeMutablePointerToElements { future in                 
                future.pointee.unregister(id)
            }
        }
    }

    final func onCancel(on executor: ExecutionContext,
        cancelable: Cancelable,
        f: (Cancelable)->()) -> Int {
        return syncQueue.sync {
            return self.withUnsafeMutablePointerToElements { future in
                return future.pointee.register { cancelled in
                    if cancelled {
                        executor.execute {
                            f(cancelable)
                        }
                    }
                    _ = self // keep a reference in order to prevent from premature deinitialization
                }
            }            
        }
    }

    final func onCancel(on executor: ExecutionContext, f: ()->()) -> Int {
        return syncQueue.sync {
            return self.withUnsafeMutablePointerToElements { future in
                return future.pointee.register { cancelled in
                    if cancelled {
                        executor.execute(f)
                    }
                    _ = self // keep a reference in order to prevent from premature deinitialization
                }
            }
        }
    }

}
