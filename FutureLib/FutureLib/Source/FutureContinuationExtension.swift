//
//  FutureContinuationExtension.swift
//  FutureLib
//
//  Created by Andreas Grosam on 01.08.15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch




// MARK: then

extension Future {
    
    //    /**
    //        Registers a continuation with a success handler `onSuccess` which takes a value
    //        of type `T` and an error handler `onError` which takes an error of type `ErrorType`
    //        Both handlers return a result of type `Result<R>`.
    //
    //        If `self` has been fulfilled with a value the success handler `onSuccess` will be executed
    //        on the given execution context with a copy of the value. The returned future (if it
    //        still exists) will be resolved with the result of the success handler function.
    //        Otherwise, when `self` has been rejected with an error, the error handler `onError` will
    //        be executed on the given execution context with this error. The returned future (if it
    //        still exists) will be resolved with the result of the error handler function.
    //        Retains `self` until it is completed.
    //
    //        - parameter on: An asynchronous execution context.
    //        - parameter f: A closure defining the continuation.
    //        - returns: A future.
    //    */
    //    public final func then<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil,
    //            onSuccess: T -> Result<R>,
    //            onError: ErrorType -> Result<R>)
    //    -> Future<R>
    //    {
    //        let returnedFuture = Future<R>(resolver: self)
    //        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] result in
    //            if let strongReturnedFuture = returnedFuture {
    //                let r: Result<R>
    //                switch result {
    //                case .Success(let value):
    //                    r = onSuccess(value)
    //                case .Failure(let error):
    //                    r = onError(error)
    //                }
    //                strongReturnedFuture.resolve(r)
    //            }
    //        }
    //        return returnedFuture
    //    }
    
    
    /**
    Registers the continuation `f` which takes a parameter `value` of type `T` which will
    be executed on the given execution context when `self` has been fulfilled.
    The continuation will be called with a copy of `self`'s result value.
    Retains `self` until it is completed.
    
    Alias: `func onSuccess(executor: ExecutionContext, _ f: T -> ())`
    
    - parameter on: The execution context where the closure f will be executed.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure taking a parameter `value` of type `T`.
    */
    public final func then(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> ())
    {
        onSuccess(on: executor, cancellationToken:cancellationToken, f)
    }
    
    public final func then(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> ())
    {
        onSuccess(on: executor, f)
    }
    
    
    
    /**
    Registers the continuation `f` which takes a value of type `T` and returns
    a value of type `R`.
    
    If `self` has been fulfilled with a value the continuation `f` will be executed
    on the given execution context with a copy of the value. The returned future (if it
    still exists) will be fulfilled with the returned value of the continuation function.
    Otherwise, when `self` has been completed with an error, the returned future (if it
    still exists) will be rejected with the same error.
    Retains `self` until it is completed.
    
    - parameter on: An asynchronous execution context.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure defining the continuation.
    - returns: A future.
    */
    public final func then<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> R)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    executor.execute { [value] in
                        strongReturnedFuture.resolve(Result(f(value)))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture
    }

    public final func then<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> R)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    executor.execute { [value] in
                        strongReturnedFuture.resolve(Result(f(value)))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture
    }
    
    /**
    Registers the continuation `f` which takes a value of type `T` and returns
    an error of type `ErrorType`.
    
    If `self` has been fulfilled with a value the continuation `f` will be executed
    on the given execution context with a copy of the value. The returned future (if it
    still exists) will be rejected with the returned error of the continuation function.
    Otherwise, when `self` has been completed with an error, the returned future (if it
    still exists) will be rejected with the same error.
    Retains `self` until it is completed.
    
    - parameter on: An asynchronous execution context.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure defining the continuation.
    - returns: A future.
    */
    public final func then(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> ErrorType)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    executor.execute { [value] in
                        strongReturnedFuture.resolve(Result(f(value)))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture
    }

    public final func then(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> ErrorType)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    executor.execute { [value] in
                        strongReturnedFuture.resolve(Result(f(value)))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture
    }
    
    /**
    Registers the continuation `f` which takes a value of type `T` and returns
    a result of type `Result<R>`.
    
    If `self` has been fulfilled with a value the continuation function `f` will be executed
    on the given execution context with a copy of the value. The returned future (if it
    still exists) will be resolved with the returned result of the continuation function.
    Otherwise, when `self` has been completed with an error, the returned future (if it
    still exists) will be rejected with the same error.
    Retains `self` until it is completed.
    
    - parameter on: An asynchronous execution context.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure defining the continuation.
    - returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned result.
    */
    public final func then<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> Result<R>)
        -> Future<R>
    {
        return map(on: executor, cancellationToken: cancellationToken, f)
    }
    
    public final func then<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> Result<R>)
        -> Future<R>
    {
        return map(on: executor, f)
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
    
    - parameter on: An asynchronous execution context.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure defining the continuation.
    - returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned future.
    */
    public final func then<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> Future<R>)
        -> Future<R>
    {
        return flatMap(on: executor, cancellationToken: cancellationToken, f);
    }
    
    public final func then<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> Future<R>)
        -> Future<R>
    {
        return flatMap(on: executor, f);
    }
    

    
    
    
}


// MARK: catch

extension Future {
    
    /**
    Registers the continuation `f` which takes an error of type `ErrorType`.
    
    If `self` has been rejected with an error the continuation `f` will be executed
    on the given execution context with this error.
    Retains `self` until it is completed.
    
    - parameter on: An asynchronous execution context.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure defining the continuation.
    */
    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: ErrorType -> ())
    {
        onFailure(on: executor, cancellationToken: cancellationToken) {
            f($0)
        }
    }

    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: ErrorType -> ())
    {
        onFailure(on: executor) {
            f($0)
        }
    }
    
    
    /**
    Registers the continuation `f` which takes an error of type `ErrorType` and returns
    a value of type `T`.
    
    If `self` has been rejected with an error the continuation `f` will be executed
    on the given execution context with this error. The returned future (if it still
    exists) will be fulfilled with the returned value of the continuation function.
    Otherwise, when `self` has been completed with success, the returned future (if it
    still exists) will be fullfilled with the same value.
    Retains `self` until it is completed.
    
    - parameter on: An asynchronous execution context.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure defining the continuation.
    - returns: A future.
    */
    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: ErrorType -> T)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result -> () in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute {
                        strongReturnedFuture.resolve(Result(f(error)))
                    }
                }
            }
        }
        return returnedFuture
    }

    
    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: ErrorType -> T)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result -> () in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute {
                        strongReturnedFuture.resolve(Result(f(error)))
                    }
                }
            }
        }
        return returnedFuture
    }
    
    /**
    Registers the continuation `f` which takes an error of type `ErrorType` and returns
    a result of type `Result<T>`.
    
    If `self` has been rejected with an error the continuation `f` will be executed
    on the given execution context with this error. The returned future (if it still
    exists) will be fulfilled with the returned result of the continuation function.
    Otherwise, when `self` has been completed with success, the returned future (if it
    still exists) will be fullfilled with the same value.
    Retains `self` until it is completed.
    
    - parameter on: An asynchronous execution context.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure defining the continuation.
    - returns: A future.
    */
    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: ErrorType -> Result<T>)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute {
                        strongReturnedFuture.resolve(f(error))
                    }
                }
            }
        }
        return returnedFuture
    }

    
    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: ErrorType -> Result<T>)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute {
                        strongReturnedFuture.resolve(f(error))
                    }
                }
            }
        }
        return returnedFuture
    }
    
    /**
    Registers the continuation `f` which takes an error of type `ErrorType` and returns
    an error type `ErrorType`.
    
    If `self` has been rejected with an error the continuation `f` will be executed
    on the given execution context with this error. The returned future (if it still
    exists) will be rejected with the returned error of the continuation function.
    Otherwise, when `self` has been completed with success, the returned future (if it
    still exists) will be fullfilled with the same value.
    Retains `self` until it is completed.
    
    - parameter on: An asynchronous execution context.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure defining the continuation.
    - returns: A future.
    */
    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: ErrorType -> ErrorType)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute {
                        strongReturnedFuture.resolve(Result(f(error)))
                    }
                }
            }
        }
        return returnedFuture
    }
    
    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: ErrorType -> ErrorType)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute {
                        strongReturnedFuture.resolve(Result(f(error)))
                    }
                }
            }
        }
        return returnedFuture
    }
    
    /**
    Registers the continuation `f` which takes an error of type `ErrorType` and returns
    a defered value by means of a future of type `future<T>`.
    
    If `self` has been rejected with an error the continuation `f` will be executed
    on the given execution context with this error. The returned future (if it still
    exists) will be resolved with the returned future of the continuation function.
    Otherwise, when `self` has been completed with success, the returned future (if it
    still exists) will be fullfilled with the same value.
    Retains `self` until it is completed.
    
    - parameter on: An asynchronous execution context.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A closure defining the continuation.
    - returns: A future.
    */
    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: ErrorType -> Future<T>)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.schedule(strongReturnedFuture) {
                        strongReturnedFuture.resolve(f(error))
                    }
                }
            }
        }
        return returnedFuture
    }
    
    public final func `catch`(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: ErrorType -> Future<T>)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.schedule(strongReturnedFuture) {
                        strongReturnedFuture.resolve(f(error))
                    }
                }
            }
        }
        return returnedFuture
    }

    
    
    
    
}


// MARK: - finally

extension Future {
    
    public final func finally(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: () -> ())
    {
        onComplete(on: executor, cancellationToken:cancellationToken) { _ -> () in
            f()
        }
    }
    
    public final func finally(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: () -> ())
    {
        onComplete(on: executor) { _ -> () in
            f()
        }
    }
    
    
    
    public final func finally<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: () -> R)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            let r = f()
            returnedFuture?.resolve(Result(r))
        }
        return returnedFuture
    }
    
    public final func finally<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: () -> R)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: executor) { [weak returnedFuture] _ in
            let r = f()
            returnedFuture?.resolve(Result(r))
        }
        return returnedFuture
    }
    
    
    public final func finally<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: () -> Result<R>)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            let r = f()
            returnedFuture?.resolve(r)
        }
        return returnedFuture
    }
    public final func finally<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: () -> Result<R>)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: executor) { [weak returnedFuture] _ in
            let r = f()
            returnedFuture?.resolve(r)
        }
        return returnedFuture
    }
    
    
    
    public final func finally(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: () -> ErrorType)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _  in
            let r = f()
            returnedFuture?.resolve(Result(r))
        }
        return returnedFuture
    }
    public final func finally(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: () -> ErrorType)
        -> Future<T>
    {
        let returnedFuture = Future<T>()
        onComplete(on: executor) { [weak returnedFuture] _  in
            let r = f()
            returnedFuture?.resolve(Result(r))
        }
        return returnedFuture
    }
    
    public final func finally<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: () -> Future<R>)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] _ -> () in
            if let strongReturnedFuture = returnedFuture {
                executor.schedule(strongReturnedFuture) {
                    let future = f()
                    strongReturnedFuture.resolve(future)
                }
            }
        }
        return returnedFuture
    }
    
    public final func finally<R>(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: () -> Future<R>)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] _ -> () in
            if let strongReturnedFuture = returnedFuture {
                executor.schedule(strongReturnedFuture) {
                    let future = f()
                    strongReturnedFuture.resolve(future)
                }
            }
        }
        return returnedFuture
    }
    
    
    
}



