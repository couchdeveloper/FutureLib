//
//  CancellationToken.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



/**
 The CancelationToken is passed from the client to a task when it creates the task 
 to let it know when the client has requested a cancellation.
*/
public struct CancellationToken: CancellationTokenType {

    private let _sharedState: SharedCancellationState

    internal init(sharedState: SharedCancellationState) {
        _sharedState = sharedState
    }


    /**
    Returns true if the client requested a cancellation.
    */
    public var isCancellationRequested: Bool {
        return _sharedState.isCancelled
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


     If the corresponding cancellation request has been cancelled the closure
     `f` will be dispatched immediately on the specified execution context.

     - parameter on: An execution context where the closure will be scheduled on.

     - parameter cancelable: The "cancelable", that is - the object that registered
     this handler.

     - parameter f:  The closure which will be executed when a cancellation has
     been requested.

     - returns: A unique id which represents the handler being registered. Use the returned value to unregister the handler.
    */
    public func onCancel(
        on executor: ExecutionContext = ConcurrentAsync(),
        cancelable: Cancelable,
        f: (Cancelable)->())
    -> Int {
        return _sharedState.onCancel(on: executor, cancelable: cancelable, f: f)
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

    - parameter on: An execution context where the closure will be scheduled on.

     - parameter f:  The closure which will be executed when a cancellation has
     been requested.

     - returns: A unique id which represents the handler being registered. Use the returned value to unregister the handler.
    */
    public func onCancel(
        on executor: ExecutionContext = ConcurrentAsync(),
        f: ()->())
    -> Int {
        return _sharedState.onCancel(on: executor, f: f)
    }

    /**
     Executes the closure `f` on the given execution context when `self` has been
     completed with a boolean value which means either "cancelled" or "not cancelled".

     - parameter on: An execution context where the closure will be scheduled on.

     - parameter f: The closure which takes a booelan parameter. If it equals `true`
     a cancellation has been requested, otherwise it has been completed with
     "not cancelled".

     - returns: A unique id identifying the registered closure. Use the returned value to unregister the handler.
     */
    public func register(on executor: ExecutionContext, f: (Bool)->()) -> Int {
        return _sharedState.register(on: executor, f: f)
    }


    /**
     Unregister the closure previously registered with `onCancel`.

     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    public func unregister(_ id: Int) {
        _sharedState.unregister(id)
    }


}
