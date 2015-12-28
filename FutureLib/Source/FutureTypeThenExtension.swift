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
     
     - parameter on: The execution context where the closure f will be executed.
     - parameter cancellationToken: A cancellation token.
     - parameter f: A closure taking a parameter `value` of type `T`.
    */
    public final func then(
        on executor: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationTokenType = CancellationTokenNone(),
        f: ValueType -> ())
    {
        onSuccess(ec: executor, ct: cancellationToken, f: f)
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
     
     - parameter on: An asynchronous execution context.
     - parameter cancellationToken: A cancellation token.
     - parameter f: A closure defining the continuation.
     - returns: A future.
    */
    public final func then<U>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationTokenType = CancellationTokenNone(),
        f: ValueType throws -> U)
        -> Future<U>
    {
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
     
     - parameter on: An asynchronous execution context.
     - parameter cancellationToken: A cancellation token.
     - parameter f: A closure defining the continuation.
     - returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned future.
    */
    public final func then<U>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationTokenType = CancellationTokenNone(),
        f: ValueType -> Future<U>)
        -> Future<U>
    {
        return flatMap(ec: ec, ct: cancellationToken, f: f)
    }

    
    
    
//    /**
//     Registers the continuations `onSuccess` and `onFailure`. When `self` has been 
//     completed with success `onSuccess` will be called with the success value of
//     `self`. Otherwise if `self` has been completed with a failure, the `onFailure`
//     closure will be called with the error value. The continuation will be executed
//     on the given execution context.
//
//     Retains `self` until it is completed.
//     
//     - parameter on: The execution context where the closure f will be executed.
//     - parameter cancellationToken: A cancellation token.
//     - parameter onSuccess: A closure with the signature `T throws -> ()`.
//     - parameter onFailure: A closure with the signature `ErrorType -> ()`.
//     */
//    public final func then(
//        on ec: ExecutionContext = GCDAsyncExecutionContext(),
//        cancellationToken: CancellationTokenType = CancellationTokenNone(),
//        onSuccess: T throws -> (),
//        onFailure: ErrorType -> ())
//    {
//        onComplete(on: ec, cancellationToken: cancellationToken) { result in
//            switch result {
//            case .Success(let value):
//                do {
//                    try onSuccess(value)
//                }
//                catch {}
//            case .Failure(let error):
//                onFailure(error)
//            }
//        }
//    }
    
    
//    /**
//     Returns a new future which will be completed with either the result of the 
//     mapping function `onSuccess` applied to `self`'s success value when `self`
//     has been successfully completed, or with the result of the mapping function 
//     `onFailure` applied to `self`'s failure value when `self` failed.
//     
//     The continuation will be executed on the given execution context. If the 
//     mapping function throws an error, the returned future will be completed with
//     the same error.
//     
//     Retains `self` until it is completed.
//     
//     - parameter on: An asynchronous execution context.
//     - parameter cancellationToken: A cancellation token.
//     - parameter onSuccess: A closure with the signature `T throws -> U`.
//     - parameter onFailure: A closure with the signature `ErrorType throws -> U`.
//     - returns: A new future.
//     */
//    public final func then<U>(
//        on ec: ExecutionContext = GCDAsyncExecutionContext(),
//        cancellationToken: CancellationTokenType = CancellationTokenNone(),
//        onSuccess: T throws -> U,
//        onFailure: ErrorType throws -> U)
//        -> Future<U>
//    {
//        let promise = Promise<U>()
//        onComplete(on: ec, cancellationToken: cancellationToken) { result in
//            switch result {
//            case .Success(let value):
//                do {
//                    promise.fulfill(try onSuccess(value))
//                }
//                catch let error {
//                    promise.reject(error)
//                }
//            case .Failure(let error):
//                do {
//                    promise.fulfill(try onFailure(error))
//                }
//                catch let error {
//                    promise.reject(error)
//                }
//            }
//        }
//        return promise.future!
//    }
    
    
    


//    /**
//     Returns a new future which will be completed with either the deferred result 
//     of the mapping function `onSuccess` applied to `self`'s success value when 
//     `self` has been successfully completed, or with the deferred result of the 
//     mapping function `onFailure` applied to `self`'s failure value when `self` 
//     failed.
//     
//     The continuation will be executed on the given execution context. 
//     
//     Retains `self` until it is completed.
//     
//     - parameter on: An asynchronous execution context.
//     - parameter cancellationToken: A cancellation token.
//     - parameter onSuccess: A closure with the signature `T -> Future<U>`.
//     - parameter onFailure: A closure with the signature `ErrorType -> Future<U>`.
//     - returns: A new future.
//     */
//    public final func then<U>(
//        on ec: ExecutionContext = GCDAsyncExecutionContext(),
//        cancellationToken: CancellationTokenType = CancellationTokenNone(),
//        onSuccess: T -> Future<U>,
//        onFailure: ErrorType -> Future<U>)
//        -> Future<U>
//    {
//        let promise = Promise<U>()
//        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { result in
//            switch result {
//            case .Success(let value):
//                ec.schedule({ return onSuccess(value) }) { future in
//                    promise.resolve(future)
//                }
//            case .Failure(let error):
//                ec.schedule({ return onFailure(error) }) { future in
//                    promise.resolve(future)
//                }
//            }
//        }
//        return promise.future!
//    }
    
    
    

}



