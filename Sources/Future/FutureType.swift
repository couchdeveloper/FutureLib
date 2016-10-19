//
//  FutureType.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



// MARK: FutureError

/**
Defines errors which belong to the domain "Future".

There are only a few errors which can be raised from operations. Programmer
errors are usually caught by assertions.
*/
public enum FutureError: Int, Error {
    /// Specifies an invalid type conversion.
    case invalidCast = -1
    /// Specifies that a predicate or filter function didn't find any matching futures.
    case noSuchElement = -2
}

/// Equality operator for `FutureError` and `ErrorType`.
public func == (lhs: FutureError, rhs: Error) -> Bool {
    if let e = rhs as? FutureError {
        return lhs.rawValue == e.rawValue
    } else {
        return false
    }
}

/// Equality operator for `ErrorType` and `FutureError`.
public func == (lhs: Error, rhs: FutureError) -> Bool {
    if let e = lhs as? FutureError {
        return e.rawValue == rhs.rawValue
    } else {
        return false
    }
}


// MARK: - Protocol FutureType
/**
The protocol `FutureType` defines the minimal set of basic functions, properties
an types which are required to be implemented by generic class `Future<T>`.

Extends `FutureBaseType`.


The complete set of functions describing a future will be implemented by protocol
extensions for `FutureType` by means of this basic set of types and operations
and by the common requirements for a future.

The type `ValueType` will be provided by the call-site and does not need to adhere
to particular constraints. The type `ResultType` is the internal representation
of the value of a future. Usually, it is some instance of an `Either` type. In
FutureLib this will be implemented by the generic enum `Try<T>` where `T` is
`ValueType`. In order to define the required functions in the `FutureType` protocol
extension we require the _concrete_ type of `ResultType` (later this may be
changed that it requires a type contraint - e.g. a protocol - only).

The property `result` and the method `onComplete` must be defined in generic
class `Future<T>`, where `T` is `ValueType`.


Note: Most functions are implemented in the protocol extension.
*/
public protocol FutureType: FutureBaseType {

    associatedtype ValueType
    associatedtype ResultType

    /**
     If `self` is completed returns its result, otherwise it returns `nil`.

     - returns: An optional `Try`
     */
    var result: ResultType? { get }


    /**
     Executes the closure `f` on the given execution context when `self` is
     completed passing `self`'s result as an argument.

     If `self` is not yet completed and if the cancellation token is cancelled
     the function `f` will be "unregistered" and immediately called with an argument
     `CancellationError.Cancelled` error. Note that the passed argument is NOT
     the `self`'s result and that `self` is not yet completed!

     The method retains `self` until it is completed or all continuations have
     been unregistered. If there are no other strong references and all continuations
     have been unregistered, `self` is being deinitialized.

     - parameter ec: The execution context where the function `f` will be executed.
     - parameter ct: A cancellation token.
     - parameter f: A function taking the result of the future as its argument.
     */
    func onComplete<U>(ec: ExecutionContext,
        ct: CancellationTokenType,
        f: @escaping (ResultType) -> U)

}


// MARK: - Protocol CompletableFutureType
/**
 This protocol extends the protocol `FutureType` which defines methods to complete
 a future. A client of a future cannot complete a future - thus a client has no
 access to it. This API can only be used by classes and functions in "internal
 scope", e.g. `FutureType` extension methods and class `Promise`.

 This protocol also defines the minimal set of operations required to complete a
 future which must be implemented in generic class `Future<T>`.
 */
internal protocol CompletableFutureType: FutureType {

    /**
     Completes `self` with the given result. If `self` is already completed the
     method has no effect.

     - parameter result: A result with which `self` will be completed.
     - returns: `true` if the future has been completed as an effect of the method,
                otherwise `false`.
    */
    func tryComplete(_ result: ResultType) -> Bool

    /**
     Completes pending `self` with the given result.

     - parameter result: A result with which `self` will be completed.
     - precondition: `self` MUST NOT be completed.
     */
    func complete(_ result: ResultType)

    /**
     Completes pending `self` with the given result.

     - parameter result: A result with which `self` will be completed.
     - precondition: `self` MUST NOT be completed.
     - precondition: Current execution context MUST be the gobal sync object.
     */
    func _complete(_ result: ResultType)

    func complete(_ value: ValueType)
    func _complete(_ value: ValueType)
    func complete(_ error: Error)
    func _complete(_ error: Error)

}



// MARK: - Extension CompletableFutureType
/**
 Define useful functions in terms of the protocol `CompletableFutureType`.
 */
internal extension CompletableFutureType {

    // Complete `self` with the deferred value of `other`.
    // The method does not retain `self`.
    internal final func completeWith<FT: FutureType>(_ other: FT) where FT.ResultType == ResultType {
        other.onComplete(ec: ConcurrentAsync(),
            ct: CancellationTokenNone()) { [weak self] otherResult in
            self?.complete(otherResult as ResultType)
        }
    }

}



// MARK: Extension FutureType

/**
 Implements the bulk of operations defining a Future in terms of `ResultType`,
 `ValueType` and the protocols defined above.
 */
public extension FutureType where ResultType == Try<ValueType> {

    /**
     - returns `true` if `self` has been completed, otherwise `false`.
     */
    public final var isCompleted: Bool {
        return result != nil
    }


    /**
     - returns: `true` if `self` has been completed with a success value, otherwise
     `false`.
     */
    public final var isSuccess: Bool {
        return result?.isSuccess ?? false
    }


    /**
     - returns: `true` if `self` has been completed with an error, otherwise `false`.
     */
    public final var isFailure: Bool {
        return result?.isFailure ?? false
    }


    /**
     Blocks the current thread until `self` is completed. If `self` has
     been completed with success returns the success value of its result,
     otherwise throws the error value.

     - returns:  the success value of its result.
     - throws:   the error value of its result.
     */
    public final func get() throws -> ValueType {
        return try get(CancellationTokenNone())
    }


    /**
     Blocks the current thread until `self` is completed or a cancellation
     has been requested.

     If the cancellation token has been cancelled, it throws an `CancellationError.Cancelled`
     error, otherwise if `self` has been completed with success returns the
     success value of its result, otherwise throws the error value.

     - parameter ct: A cancellation token which can be used
     to resume the blocked thread through throwing a CancellationError.Cancelled
     error.

     - returns:  the success value of its result.
     - throws:   the error value of its result or a `CancellationError.Cancelled` error.
     */
    public final func get(_ ct: CancellationTokenType) throws -> ValueType {
        while !ct.isCancellationRequested {
            if let r = self.result {
                switch r {
                case .success(let v): return v
                case .failure(let e): throw e
                }
            }
            wait(ct)
        }
        throw CancellationError()
    }


    /**
     Executes the continuation `f` which takes a parameter `value` of type `T` on
     the given execution context when `self` has been completed with a success value
     passing the success value as the argument.

     Retains `self` until it is completed.

     - parameter ec: An asynchronous execution context for the function `f`.
     - parameter ct: A cancellation token which will be monitored.
     - parameter f: A function taking a parameter `value` of type `T`.
     */
    public final func onSuccess(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (ValueType) -> ()) {
        onComplete(ec: ec, ct: ct) { result in
            if case .success(let value) = result {
                f(value)
            }
        }
    }


    /**
     Executes the continuation `f` which takes a parameter `error` of type `ErrorType`
     on the given execution context when `self` has been completed with a failure
     value passing the error as the argument.

     Retains `self` until it is completed.

     - parameter ec: An asynchronous execution context for the function `f`.
     - parameter ct: A cancellation token which will be monitored.
     - parameter f: A function taking a parameter `error` of type `ErrorType` as parameter.
     */
    public final func onFailure(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (Error) -> ()) {
        onComplete(ec: ec, ct: ct) { result in
            if case .failure(let error) = result {
                f(error)
            }
        }
    }


    /**
     Returns a new future which will be completed with the return value of the
     function `f` applied to the success value of `self` when `self` has been
     completed successfully. If `self` has been completed with an error or if the
     function `f` throws an error, the returned future will be completed with the
     same error.

     When `self` completes successfully, the function `f` will be executed on the
     given execution context.

     If the cancellation token has been cancelled before `self` has been completed,
     the function `f` will be _unregistered_ from `self` and the returned future
     will be completed with a `CancellationError.Cancelled` error.

     - Note:
     - Holds a strong refence to `self` until `self` is completed.
     - Does not hold a strong reference to the returned future.
     
     - parameter ec: An asynchronous execution context for the function `f`.
     - parameter ct: A cancellation token which will be monitored.
     - parameter f:  A throwing mapping function `f` which takes a value of type `T`
     and returns a result of type `U`.
     - returns: A new future.
     */
    public final func map<U>(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (ValueType) throws -> U)
        -> Future<U> {
        typealias RU = Try<U>
        // Caution: the mapping function must be called even when the returned
        // future has been deinitialized prematurely!
        let returnedFuture = Future<U>()
        onComplete(ec: ec, ct: ct) { [weak returnedFuture] result in
            let r: RU = result.map(f)
            returnedFuture?.complete(r)
        }
        return returnedFuture
    }


    /**
     Returns a new future which will be completed with the eventual result of the
     future returned from function `f` which will be applied to the success value
     of `self` when `self` has been completed successfully. If `self` has been
     completed with an error the returned future will be completed with the same
     error.

     When `self` completes successfully, the function `f` will be executed on the
     given execution context.

     If the cancellation token has been cancelled before `self` has been completed,
     the function `f` will be _unregistered_ from `self` and the returned future
     will be completed with a `CancellationError.Cancelled` error.

     - Note:
       - Holds a strong refence to `self` until `self` is completed.
       - Does not hold a strong reference to the returned future.

     - parameter ec: An asynchronous execution context for the function `f`.
     - parameter ct: A cancellation token which will be monitored.
     - parameter f: A mapping function of type `T -> Future<U>` defining the continuation.
     - returns: A new future.
    */
    public final func flatMap<U>(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (ValueType) throws -> Future<U>)
        -> Future<U> {
        // Caution: the mapping function must be called even when the returned
        // future has been deinitialized prematurely!
        let returnedFuture = Future<U>()
        onComplete(ec: ConcurrentAsync(), ct: ct) { [weak returnedFuture] result in
            switch result {
            case .success(let value):
                ec.schedule(task: { return try f(value) }, onStart: { future in
                    returnedFuture?.completeWith(future)
                })
            case .failure(let error):
                returnedFuture?.complete(error)
            }
        }
        return returnedFuture
    }


    /**
     Returns a new future which will be completed with a tuple whose first element
     value is the success value of `self` and the second element value is the
     success value of the future `other`. If any of the futures fails, the returned
     future will be completed with the first error occuring.

     - parameter ct: A cancellation token which will be monitored.
     - parameter other: The second future.
    */
    public final func zip<U>(
        _ other: Future<U>,
        ct: CancellationTokenType = CancellationTokenNone())
        -> Future<(ValueType, U)> 
    {
        return flatMap(ct: ct) { selfValue -> Future<(ValueType, U)> in
            return other.map(ct: ct) { otherValue in
                return (selfValue, otherValue)
            }
        }
    }


    /**
     Returns a new future which will be completed with `self`'s success value or
     with the return value of the mapping function `f` when `self` failes.

     If `self` has been completed with an error the continuation `f` will be executed
     on the given execution context with this error. The returned future (if it still
     exists) will be completed with the returned value of the continuation function,
     or with the error thrown from it.
     Otherwise, when `self` has been completed with success, the returned future
     (if it still exists) will be completed with the same value.

     Retains `self` until it is completed.

     - parameter ec: An asynchronous execution context.
     - parameter ct: A cancellation token.
     - parameter f: A closure with signature `ErrorType throws -> T`.
     - returns: A new future.
     */
    public final func recover(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (Error) throws -> ValueType)
        -> Future<ValueType> {
        let returnedFuture = Future<ValueType>()
        onComplete(ec: ConcurrentAsync(), ct: ct) { [weak returnedFuture] result in
            // Caution: the mapping function must be called even when the returned
            // future has been deinitialized prematurely!
            switch result {
            case .success(let value):
                returnedFuture?.complete(value)
            case .failure(let error):
                ec.execute {
                    do {
                        let value = try f(error)
                        returnedFuture?.complete(value)
                    } catch let err {
                        returnedFuture?.complete(err)
                    }
                }
            }
        }
        return returnedFuture
    }


    /**
     Returns a new future which will be completed with `self`'s success value or
     with the deferred result of the mapping function `f` when `self` failes.

     If `self` has been completed with an error the continuation `f` will be executed
     on the given execution context with this error. The returned future (if it still
     exists) will be resolved with the returned future of the continuation function.
     Otherwise, when `self` has been completed with success, the returned future
     (if it still exists) will be fulfilled with the same value.
     Retains `self` until it is completed.

     - parameter ec: An asynchronous execution context.
     - parameter ct: A cancellation token.
     - parameter f: A closure which takes an error of type `ErrorType` and returns
     a deferred value by means of a future of type `future<T>`.
     - returns: A new future.
     */
    public final func recoverWith(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (Error) throws -> Future<ValueType>)
        -> Future<ValueType> {
        let returnedFuture = Future<ValueType>()
        onComplete(ec: ConcurrentAsync(), ct: ct) { [weak returnedFuture] result in
            // Caution: the mapping function must be called even when the returned
            // future has been deinitialized prematurely!
            switch result {
            case .success(let value):
                returnedFuture?.complete(value)
            case .failure(let error):
                ec.schedule(task: { return try f(error) }, onStart: { future in
                    returnedFuture?.completeWith(future)
                })
            }
        }
        return returnedFuture
    }


    /**
     Returns a new Future which is completed with the result of function `s` applied
     to the successful result of `self` or with the result of function `f` applied
     to the error value of `self`.
     If `s` throws an error, the returned future will be completed with the same
     error.
     - parameter ec: An asynchronous execution context for function `s` and `f`.
     - parameter ct: A cancellation token.
     - parameter s: A closure with signature `ValueType throws -> U` which is applied
     to the success value of `self`.
     - parameter f: A closure with signature `ErrorType -> ErrorType` which is applied
     to the error value of `self`.
     - returns: A new future.
     */
    public final func transform<U>(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        s: @escaping (ValueType) throws -> U,
        f: @escaping (Error) -> Error)
        -> Future<U> 
    {
        let returnedFuture = Future<U>()
        onComplete(ec: ec, ct: ct) { [weak returnedFuture] result in
            // Caution: the mapping function must be called even when the returned
            // future has been deinitialized prematurely!
            switch result {
            case .failure(let error):
                returnedFuture?.complete(f(error))
            case .success(let value):
                ec.execute {
                    do {
                        returnedFuture?.complete(try s(value))
                    } catch let err {
                        returnedFuture?.complete(err)
                    }
                }
            }
        }
        return returnedFuture
    }


    /** 
     Returns a new Future by applying the specified function to the result of `self`. 
     If `f` throws an error, the returned future will be completed with the same
     error.
     
     - parameter ec: An asynchronous execution context for function `f`.
     - parameter ct: A cancellation token.
     - parameter f: A function that transforms the result of this future
     - returns: A new `Future` that will be completed with the transformed value.
    */
    public final func transform<U>(
        ec: ExecutionContext = ConcurrentAsync(), 
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (Try<ValueType>) throws -> Try<U>) -> Future<U> 
    {
        let returnedFuture = Future<U>()
        onComplete(ec: ec, ct: ct) { [weak returnedFuture] result in
            // Caution: the mapping function must be called even when the returned
            // future has been deinitialized prematurely!
            do {
                let r = try f(result)
                returnedFuture?.complete(r)
            } catch {
                returnedFuture?.complete(error)
            }
        }
        return returnedFuture
    }
    
    /** 
     Returns a new Future by applying the specified function, which produces a Future, 
     to the result of this Future. If `f` throws an error, the returned future will 
     be completed with the same error.

     - parameter ec: An asynchronous execution context for function `f`.
     - parameter ct: A cancellation token.
     - parameter f: A function that transforms the result of this future.
     - returns: A new `Future` that will be completed with the transformed value.
    */
    public final func transformWith<U>(
        ec: ExecutionContext = ConcurrentAsync(), 
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (Try<ValueType>) throws -> Future<U>) 
        -> Future<U> 
    {
        let returnedFuture = Future<U>()
        onComplete(ec: ec, ct: ct) { [weak returnedFuture] result in
            // Caution: the mapping function must be called even when the returned
            // future has been deinitialized prematurely!
            do {
                let future: Future<U> = try f(result)
                returnedFuture?.completeWith(future)
            } catch {
                returnedFuture?.complete(error)
            }
        }
        return returnedFuture
    }
    
    
    /**
     Returns a new future which is completed with the success value of `self` if
     the function `predicate` applied to the value returns `true`. Otherwise, the
     returned future will be completed with the error `FutureError.NoSuchElement`.

     If `self` will be completed with an error or if the predicate throws an error,
     the returned future will be completed with the same error.

     - parameter ec: An asynchronous execution context for function `predicate`.
     - parameter ct: A cancellation token.
     - parameter predicate: A closure with signature `ValueType throws -> Bool` which is
                    applied to the success value of `self`.
    */
    public final func filter(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        predicate: @escaping (ValueType) throws -> Bool)
        -> Future<ValueType>
    {
        return map(ec: ec, ct: ct) { value in
            if try predicate(value) {
                return value
            } else {
                throw FutureError.noSuchElement
            }
        }
    }

}
