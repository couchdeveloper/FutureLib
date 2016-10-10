//
//  CancellationTokenType.swift
//  FutureLib
//
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import Dispatch


/**
 The protocol `CancellationTokenType` defines the methods and behavior for a 
 concrete implementation of a _cancellation token_. 
 
 A cancellation token is associated to a corresponding `CancellationRequest` 
 with a one-to-one relationship.
 
 A cancellation token starts out with an "undefined" state and can then be 
 completed with a value representing a "cancelled" or "not cancelled" state.
 Completion will be performed by its associated cancellation request value.
 Once a cancellation token is completed, it cannot change its state anymore.
 
 A cancellation token is passed from a client to a potentially long lasting task 
 when the client creates this task. The task may now observe the state of the 
 cancellation token via periodically polling its state, or it may _register_ a 
 handler function which will be invoked when the token gets completed. 
 
 When a client requested a cancellation the token will be completed accordingly.
 When this happens the task should take the appropriate steps to cancel/terminate 
 its operation. It may however also to decide _not_ to cancel its operation, for 
 example when there are yet other clients still waiting for the result. One 
 cancellation token may be shared by many observers.
*/
public protocol CancellationTokenType {

    /**
     - returns: `true` if `self`'s associated CancellationRequest has requested
     a cancellation. Otherwise, it returns `false`.
    */
    var isCancellationRequested: Bool { get }
    
    /**
     Returns `true` if `self` has been completed. A token will be completed when
     a client requests a cancellation via its cancellatoion request, when the
     cancellation request deallocates or when the cancellation token is inherently 
     not mutable (e.g. it is a `CancellationTokenNone`).
     */
    var isCompleted: Bool { get }
    
    
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
    func onComplete(queue: DispatchQueue, f: @escaping (Bool)->()) -> EventHandlerIdType?
    


    /**
     Executes closure `f` on the given execution context when its associated
     `CancellationRequest` has been cancelled.
     
     - Important:   
     An implementation MUST not strongly capture `self` whithin the closure.
     The cancelable SHOULD BE weakly captured.
     
     
     - Note: 
     Having a reference to the cancellation token or registering a closure does not
     retain the corresponding cancellation request. If the cancellation request
     will be deinitialized, the registered closures will not execute, but they will
     be deinitialized as well.
     
     - Note: 
     If the corresponding cancellation request has been cancelled the closure
     `f` will be dispatched immediately on the specified execution context.
     
     
     - parameter queue: A dispatch queue where the closure will be submitted.
     
     - parameter f:  The closure which will be executed when a cancellation has
     been requested.
     
     - returns: An optianal for a unique id which represents the handler being registered. If `self` is already completed, the handler will be executed synchronously instead of being registered, in which case the returned optional equals `nil`. Use the returned EventHandlerId to unregister the handler.
     */
    func onCancel(queue: DispatchQueue, f: @escaping ()->()) -> EventHandlerIdType?
        

    /**
     Registers the closure `f` which is invoked on a given execution context
     when its associated `CancellationRequest` has been cancelled and when the
     `cancelable` still exists.

     `Closure `f` will be called with the given cancelable as its argument.
     `self` and the `cancelable` shall not be retained.

     - Note: 
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

     - returns: An optianal for a unique id which represents the handler being registered. If `self` is already completed, the handler will be executed synchronously instead of being registered, in which case the returned optional equals `nil`. Use the returned EventHandlerId to unregister the handler.
    */
    func onCancel(queue: DispatchQueue, cancelable: Cancelable, f: @escaping (Cancelable)->()) -> EventHandlerIdType?
    
    
//    /**
//     Executes the closure `f` on the given execution context when `self` has been
//     _completed_ with a boolean value. If the boolean value equals `true` it means 
//     that the there was a cancellation requested, otherwise the associated cancelation 
//     request has been invalidated or deinitialized and thus a cancellation request
//     cannot occur anymore.
//     
//     - Important:   
//     An implementation MUST not strongly capture `self` whithin the closure.
//     The cancelable SHOULD BE weakly captured.
//     
//     - parameter queue: An dispatch queue where the closure will be submitted.
//     
//     - parameter f: The closure which takes a booelan parameter. If it equals `true`
//     a cancellation has been requested, otherwise it has been completed with
//     "not cancelled".
//     
//     - returns: A unique id which represents the handler being registered. Use the returned value to unregister the handler.
//     
//     */
//    func register(queue: DispatchQueue, f: @escaping (Bool)->()) -> Int
//    
//    
//    /**
//     Unregister the closure previously registered with `onCancel`.
//     
//     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
//     */
//    func unregister(id: Int)
//    
    

}



public extension CancellationTokenType {


    /**
     Registers the closure `f` which is invoked on a private execution context
     when its associated `CancellationRequest` has been cancelled and when the
     `cancelable` still exists.

     `Closure `f` will be called with the given cancelable as its argument.
     `self` and the `cancelable` shall not be retained.

     **Remarks:**

     Having a reference to the cancellation token or registering a closure does not
     retain the corresponding cancellation request. If the cancellation request
     will be deinitialized, the registered closures will not execute, but they will
     be deinitialized as well.

     If the corresponding cancellation request has been cancelled the closure
     `f` will be dispatched immediately on the specified execution context.

     - parameter cancelable: The "cancelable", that is - the object that registered
     this handler.

     - parameter f:  The closure which will be executed when a cancellation has
     been requested.

     - returns: A unique id which represents the handler being registered. Use the returned EventHandlerId to unregister the handler.
    */
    public final func onCancel(cancelable: Cancelable, f: @escaping (Cancelable)->()) -> EventHandlerIdType? {
        return self.onCancel(queue: DispatchQueue.global(), cancelable: cancelable, f: f)
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

     If the corresponding cancellation request has been cancelled the closure
     `f` will be dispatched immediately on the specified execution context.

     - parameter f:  The closure which will be executed when a cancellation has
     been requested.

     - returns: A unique id which represents the handler being registered. Use the returned EventHandlerId to unregister the handler.
    */
    public final func onCancel(f: @escaping ()->()) -> EventHandlerIdType? {
        return self.onCancel(queue: DispatchQueue.global(), f: f)
    }


}


