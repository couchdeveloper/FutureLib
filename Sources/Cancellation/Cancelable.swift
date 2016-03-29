//
//  Cancelable.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


/**
    A `Cancelable` is an instance of a class, executing a potentially lengthy
    operation or task, or providing a service, all of which can be cancelled.

    Calling cancel on a `Cancelable` _may eventually_ cancel it. Due to the inherently
    asynchronous behavior of canceling a task there is no guarantee that after
    requesting a cancellation the Cancelable becomes _immediately_ "cancelled".
    There is even no guarantee that the Cancelable becomes eventually cancelled
    at all - it may fail or succeed afterward.

    The contract a `Cancelable` should fulfill says that after receiving a cancel
    signal - and if it's still executing - a `Cancelable` _should as soon as possible_
    cancel its operation. However, a `Cancelable` may also succeed or fail before
    this cancel request becomes effective. When the `Cancelable` is already in a
    finished state, calling cancel on it has no effect.

    If a `Cancelable` is an operation which signals its eventual result via a promise,
    and a cancellation has been requested, it should reject its promise *after* its
    operation is actually cancelled with a corresponding error reason. The clients
    can get a cancellation signal through registering an error handler on the
    corresponding future of the promise.
*/
public protocol Cancelable: class {

    /**
     Requests a cancellation. An implementation should as soon as possible
     cancel the operation or service. If the cancelable is already finished,
     no action should be performed.
    */
    func cancel()

    /**
     Requests a cancellation with a given error provided by the client. An
     implementation should as soon as possible cancel the operation or service.
     If the cancelable is already finished, no action should be performed.

     - parameter error: The error that can be used to reason about the cancellation.
    */
    func cancel(error: ErrorType)
}
