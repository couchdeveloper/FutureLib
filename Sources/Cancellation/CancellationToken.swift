//
//  CancellationToken.swift
//  FutureLib
//
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import Dispatch


/**
 The CancelationToken is passed from the client to a task when it creates the task
 to let it know when the client has requested a cancellation.
*/
internal struct CancellationToken: CancellationTokenType {
    internal typealias HandlerId = CancellationState.HandlerId
    
    private let _sharedState: CancellationState

    internal init(sharedState: CancellationState) {
        _sharedState = sharedState
    }


    /**
    Returns true if the client requested a cancellation.
    */
    internal var isCancellationRequested: Bool {
        return _sharedState.isCancelled
    }

    /**
     Returns `true` if a cancellation has been requested, or if its associated
     cancellation request has been deallocated.
    */
    internal var isCompleted: Bool {
        return _sharedState.isCompleted
    }


    /**
     Executes closure `f` on the given execution context when its associated
     `CancellationRequest` has been cancelled or when it deallocates.
     
     - Important:   
     An implementation MUST not strongly capture `self` whithin the closure.
     The cancelable SHOULD BE weakly captured.
     
     
     - Note: 
     Having a reference to the cancellation token or registering a closure does not
     retain the corresponding cancellation request. 
     
     - Note: 
     If a cancellation has already been requested the closure `f` will be dispatched 
     _immediately_ on the specified execution context.
     
     - parameter queue: A dispatch queue where the closure will be submitted.
     
     - parameter f:  The closure which will be executed when `self` has been
     completed.
     
     - returns: An optianal for a unique id which represents the handler being registered. If `self` is already completed, the handler will be executed synchronously instead of being registered, in which case the returned optional equals `nil`. Use the returned EventHandlerId to unregister the handler.
     */
    public func onComplete(queue: DispatchQueue = DispatchQueue.global(), f: @escaping (Bool) -> ()) -> EventHandlerIdType? {
        // TODO: implement
        return nil 
    }
    
    
    /**
     Registers the closure `f` which is invoked on a given execution context
     when its associated `CancellationRequest` has been cancelled and when the
     `cancelable` still exists.

     `Closure `f` will be called with the given cancelable as its argument.
     `self` and the `cancelable` shall not be retained.

     **Remarks:**

     Having a reference to the cancellation token or registering a closure does not
     retain the corresponding cancellation request. If the cancellation request
     will be deinitialized, the registered closures will not execute, but they will
     be deinitialized as well.

     A registered handler can be unregistered by calling `invalidate()` for the
     returned event handler id.
     
     If the corresponding cancellation request has been cancelled the closure
     `f` will be dispatched immediately on the specified execution context.

     - parameter on: An execution context where the closure will be scheduled on.

     - parameter cancelable: The "cancelable", that is - the object that registered
     this handler.

     - parameter f:  The closure which will be executed when a cancellation has
     been requested.

     - returns: A unique value which represents the handler being registered. Use the returned value to unregister the handler.
    */
    internal func onCancel(queue: DispatchQueue = DispatchQueue.global(), cancelable: Cancelable,
        f: @escaping (Cancelable)->())
    -> EventHandlerIdType? {
        return _sharedState.onCancel(cancelable: cancelable) { cancelable in
            queue.async {
                f(cancelable)
            }
        }
    }


    /**
     Registers the closure `f` which is invoked on a given execution context
     when its associated `CancellationRequest` has been cancelled and when the
     `cancelable` still exists.

     `Closure `f` will be called with the given cancelable as its argument.
     `self` and the `cancelable` shall not be retained.

     **Remarks:**

     Registering a closure does not retain the corresponding cancellation request.
     If the cancellation request will be deinitialized, the registered closures
     will not execute, but they will be deinitialized as well.

     A registered handler can be unregistered by calling `invalidate()` for the
     returned event handler id.
     

     If the corresponding cancellation request has been cancelled the closure
     `f` will be dispatched immediately on the specified execution context.

    - parameter queue: A dispatch queue where the closure will be submitted.

     - parameter f:  The closure which will be executed when a cancellation has
     been requested.

     - returns: A unique value which represents the handler being registered. Use the returned value to unregister the handler.
    */
    internal func onCancel(queue: DispatchQueue = DispatchQueue.global(), f: @escaping ()->()) -> EventHandlerIdType? {
        return _sharedState.onCancel {
            queue.async(execute: f)
        }
    }

    /**
     Executes the closure `f` on the given execution context when `self` has been
     completed with a boolean value which means either "cancelled" or "not cancelled".

     - parameter queue: A dispatch queue where the closure will be submitted.

     - parameter f: The closure which takes a booelan parameter. If it equals `true`
     a cancellation has been requested, otherwise it has been completed with
     "not cancelled".

     - returns: A unique value which represents the handler being registered. Use the returned value to unregister the handler.
     */
    internal func register(queue: DispatchQueue = DispatchQueue.global(), f: @escaping (Bool)->()) -> HandlerId? {
        return _sharedState.register { cancelled in
            queue.async {
                f(cancelled)
            }
        }
    }


    /**
     Unregister the closure previously registered with `onCancel`.

     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    internal func unregister(id: HandlerId) {
        _sharedState.unregister(id: id)
    }


}






