//
//  SharedCancellationState.swift
//
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import Dispatch

// MARK: - Public

/// A concrete implementation of an `EventHandlerIdType` encapsulates an
/// event handler (aka closure) and its associated containter (that is, an 
/// _event hanler registry_) where it has been registered. A client can simply 
/// unregister the handler by calling `invalidate()` for the event handler id 
/// value.
/// Unregistering a handler from its registry is recommended when the associated 
/// task has been finished without being cancelled. Since the handler will never 
/// run anymore, unregistering ensures that resources tied to the handler will
/// be released propperly.
///
/// A value of an event handler id will be obtained when registering a handler
/// with an _event handler registry_.
public protocol EventHandlerIdType {
    
    /// Unregisters the associated event handler from its container. That is, 
    /// after calling `invalidate()` it will not be called anymore when its 
    /// container will be resumed.
    /// If the event handler is already unregistered, the function shall have
    /// no effect.
    func invalidate()
}




// -----------------------------------------------------------------------------
// MARK: - Internal 

//internal struct EventHandlerIdNone: EventHandlerIdType {
//    internal func invalidate() {}
//}



fileprivate struct EventHandlerId: EventHandlerIdType {
    fileprivate typealias HandlerId = CancellationState.HandlerId
    
    private weak var cancellationState: CancellationState?
    private var id: HandlerId
    
    
    fileprivate init(cancellationState: CancellationState, id: HandlerId) {
        self.cancellationState = cancellationState
        self.id = id
    }
    
    /**
     Unregisters the handler for a cancellation token previously registered with `onCancel`.
     */
    internal func invalidate() {
        cancellationState?.unregister(id: id)
    }
}






private let syncQueue = DispatchQueue(label: "cancellation.sync_queue")

internal final class CancellationState {
    
    private typealias Future = BinaryFuture<HandlerRegistry<Bool>>
    
    internal typealias HandlerId = Future.HandlerId
    
    private var future = Future()
    
    
    final var isCompleted: Bool {
        return syncQueue.sync {
            self.future.isCompleted
        }
    }
    
    
    final var isCancelled: Bool {
        return syncQueue.sync {
            switch self.future {
            case .pending: return false
            case .completed(let cancelled): return cancelled
            }
        }
    }
    
    
    final func cancel() {
        syncQueue.async {
            self.future.complete(true)
        }
    }
    
    
    final func invalidate() {
        syncQueue.async {
            self.future.complete(false)
        }
    }
    
    final var count: Int {
        return syncQueue.sync {
            self.future.count
        }
    }
    
    
    /**
     Register a closure which will be called when `self` has been completed with 
     its argument set to the current value of the completion state (either `true`
     or `false`). If `self` is already completed, the closure will be immediately 
     called synchronously and registering will be skipped.
     
     - parameter f: The closure which defines the event handler to be executed
     when `self` is completed.
     
     - returns: An optional handler id. If `self` was completed it returns `nil`
     otherwise it returns a value which represents the registered event handler 
     which can be later used to unregister the event handler again.  
     */
    final func register(f: @escaping (Bool)->()) -> HandlerId? {
        return syncQueue.sync {
            return self.future.onComplete { cancelled in
                f(cancelled)
            }
        }
    }
    
    
    /**
     Unregister the closure previously registered with `register`.
     
     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    final func unregister(id: HandlerId) {
        syncQueue.async {
            self.future.unregister(id: id)
        }
    }
    
    final func onComplete(f: @escaping (Bool)->()) -> EventHandlerIdType? {
        return syncQueue.sync {
            if let handlerId = self.future.onComplete(f: { cancelled in
                f(cancelled)
                _ = self // Keep a reference to `self` in order to prevent premature
                         // deinitialization.                
                }) {
                return EventHandlerId(cancellationState: self, id: handlerId)
            } else {
                return nil
            }
        }
    }

    final func onCancel(f: @escaping ()->()) -> EventHandlerIdType? {
        return self.onComplete { cancelled in
            if cancelled {
                f()
            }
        }
    }
    
    
    
    final func onCancel(cancelable: Cancelable, f: @escaping (Cancelable)->()) -> EventHandlerIdType? {
        return syncQueue.sync {
            if let handlerId = self.future.onComplete(f: { [weak cancelable] cancelled in
                if cancelled {
                    if let cancelable = cancelable {
                        f(cancelable)
                    }
                }
                _ = self // Keep a reference to `self` in order to prevent premature
                         // deinitialization.                
            }) {
                return EventHandlerId(cancellationState: self, id: handlerId)
            } else {
                return nil
            }
        }
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
fileprivate enum BinaryFuture<HR: HandlerRegistryType> where HR.Param == Bool {
    fileprivate typealias HandlerId = HR.HandlerId
    
    case pending(_: HR)
    case completed(_: Bool)
    
    fileprivate init() {
        self = .pending(HR())
    }
    
    fileprivate init(value: Bool) {
        self = .completed(value)
    }
    
    fileprivate var isCompleted: Bool {
        if case .completed = self {
            return true
        } else {
            return false
        }
    }
    
    fileprivate var value: Bool? {
        if case .completed(let value) = self {
            return value
        } else {
            return nil
        }
    }
    
    fileprivate mutating func complete(_ value: Bool) {
        if case .pending(let registry) = self {
            registry.execute(withParameter: value)
            self = .completed(value)
        }
    }
    
    fileprivate mutating func onComplete(f: @escaping (Bool)->()) -> HandlerId? {
        switch self {
        case .pending(var registry):
            let result = registry.register(f: f)
            self = .pending(registry)
            return result
            
        case .completed(let cancelled): 
            f(cancelled)
            return nil
        }
    }
    
    fileprivate func unregister(id: HandlerId) {
        if case .pending(var registry) = self {
            _ = registry.unregister(id: id)
        }
    }
    
    fileprivate var count: Int {
        switch self {
        case .pending(let registry):
            return registry.count
        case .completed: 
            return 0
        }
    }
    
}







