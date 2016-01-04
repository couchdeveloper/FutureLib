//
//  FutureTypeThenExtension.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



// MARK: then

extension FutureType where ResultType == Result<ValueType> {


    /**
     Registers the continuation `f` which takes a parameter `value` of type `T` which will
     be executed on the given execution context when `self` has been fulfilled.
     The continuation will be called with a copy of `self`'s result value.
     Retains `self` until it is completed.

     Alias: `func onSuccess(executor: ExecutionContext, f: T -> ())`

     - parameter ec: The execution context where the closure f will be executed.
     - parameter cancellationToken: A cancellation token.
     - parameter f: A closure taking a parameter `value` of type `T`.
     */
    public final func then(
        ec ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationTokenType = CancellationTokenNone(),
        f: ValueType -> ()) {
        onSuccess(ec: ec, ct: cancellationToken, f: f)
    }


    /**
     Registers the throwing continuation `f` which takes a value of type `T` and
     returns either a value of type `U` or throws an error of type `ErrorType`.

     If `self` has been completed with a success value the continuation `f` will
     be executed on the given execution context with a copy of the value. The returned
     future (if it still exists) will be completed with the return value of the
     continuation function or with the error thrown by the continuation.
     Otherwise, when `self` has been completed with an error, the returned future
     (if it still exists) will be completed with the same error.

     Retains `self` until it is completed.

     - parameter ec: An asynchronous execution context.
     - parameter cancellationToken: A cancellation token.
     - parameter f: A closure defining the continuation.
     - returns: A future.
     */
    public final func then<U>(
        ec ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationTokenType = CancellationTokenNone(),
        f: ValueType throws -> U)
        -> Future<U> {
        return map(ec: ec, ct: cancellationToken, f: f)
    }




    /**
     Registers the continuation function `f` which takes a value of type `T` and returns
     a *deferred* value of type `R` by means of a `Future<R>`.

     If `self` has been fulfilled with a value the continuation function `f` will be executed
     on the given execution context with a copy of the value. The returned future (if it
     still exists) will be resolved with a future `Future<R>` returned from the continuation
     function `f`.
     Otherwise, when `self` has been completed with an error, the returned future (if it
     still exists) will be rejected with the samne error.
     Retains `self` until it is completed.

     - parameter ec: An asynchronous execution context.
     - parameter cancellationToken: A cancellation token.
     - parameter f: A closure defining the continuation.
     - returns: A future which will be either rejected with `self`'s error or resolved
                with the continuation function's returned future.
     */
    public final func then<U>(
        ec ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationTokenType = CancellationTokenNone(),
        f: ValueType -> Future<U>)
        -> Future<U> {
        return flatMap(ec: ec, ct: cancellationToken, f: f)
    }

}
