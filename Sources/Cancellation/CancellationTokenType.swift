//
//  CancellationTokenType.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


/**
    The `CancellationTokenType` defines the methods and behavior for a concrete
    implementation of a `CancellationToken`. A cancellation token is associated to
    a corresponding `CancellationRequest` with a one-to-one relationship.

    A cancellation token's state is either "undefined", "cancelled" or "not cancelled".

    A cancellation token is passed from a client to a potentially long lasting task or
    operation when the client creates this task. The task will observe the state of
    the cancellation token or registers a handler function which let it know when
    the client has requested a cancellation.  When a client requested a cancellation
    the task should take the appropriate steps to cancel/terminate its operation. It
    may however also to decide _not_ to cancel its operation, for example when there
    are yet other clients still waiting for the result. One cancellation token may be
    shared by many observers.
*/
public protocol CancellationTokenType {

    /**
     - returns: `true` if `self`'s associated CancellationRequest has requested
     a cancellation. Otherwise, it returns `false`.
    */
    var isCancellationRequested: Bool { get }


    /**
     Executes the closure `f` on the given execution context when `self` has been
     completed with a boolean value which means either "cancelled" or "not cancelled".

     - parameter on: An execution context where the closure will be scheduled on.

     - parameter f: The closure which takes a booelan parameter. If it equals `true`
        a cancellation has been requested, otherwise it has been completed with
        "not cancelled".
     
     - returns: A unique id which represents the handler being registered. Use the returned id to unregister the handler.
    */
    func register(on executor: ExecutionContext, f: (Bool)->()) -> Int


    /**
     Unregister the closure previously registered with `onCancel`.

     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    func unregister(_ id: Int)


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

     - returns: A unique id which represents the handler being registered. Use the returned id to unregister the handler.
    */
    func onCancel(on executor: ExecutionContext, cancelable: Cancelable, f: (Cancelable)->()) -> Int


    /**
     Executes closure `f` on the given execution context when its associated
     `CancellationRequest` has been cancelled.

     **Caution:** An implementation MUST not retain `self` when registering a
     closure .

     **Remarks:**

     Having a reference to the cancellation token or registering a closure does not
     retain the corresponding cancellation request. If the cancellation request
     will be deinitialized, the registered closures will not execute, but they will
     be deinitialized as well.

     If the corresponding cancellation request has been cancelled the closure
     `f` will be dispatched immediately on the specified execution context.


     - parameter on: An execution context where the closure will be scheduled on.

     - parameter f:  The closure which will be executed when a cancellation has
     been requested.

     - returns: A unique id which represents the handler being registered. Use the returned value to unregister the handler.
    */
    func onCancel(on executor: ExecutionContext, f: ()->()) -> Int


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

     - returns: A unique id which represents the handler being registered.
    */
    public final func onCancel(_ cancelable: Cancelable, f: (Cancelable)->()) -> Int {
        return self.onCancel(on: ConcurrentAsync(), cancelable: cancelable, f: f)
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

     - returns: A unique id which represents the handler being registered.
    */
    public final func onCancel(_ f: ()->()) -> Int {
        return self.onCancel(on: ConcurrentAsync(), f: f)
    }



}
