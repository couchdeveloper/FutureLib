//
//  FututrFreeFunc.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch



/**
 Returns a future which will be completed with the result of function `f`
 which will be executed on the given execution context. Function `f` is usually
 a CPU-bound function evaluating a result which takes a significant time to
 complete.

 - parameter ec: An execution context where the function `f` will be executed.
 - parameter f: A function takes no parameters and returns a value of type `Try<T>`.
 - returns: A `Future` whose `ValueType` equals `T`.
 */
@available(*, deprecated=1.0)
public func future<T>(ec: ExecutionContext = GCDAsyncExecutionContext(),
    f: ()->Try<T>)
    -> Future<T> {
    let returnedFuture: Future<T> = Future<T>()
    ec.execute() {
        switch f() {
        case .Success(let value): returnedFuture.complete(Try(value))
        case .Failure(let error): returnedFuture.complete(Try(error: error))
        }
    }
    return returnedFuture
}


/**
 Returns a future which will be completed with the result of function `f`
 which will be executed on the given execution context. Function `f` is usually
 a CPU-bound function evaluating a result which takes a significant time to
 complete.

 - parameter ec: An execution context where the function `f` will be executed.
 - parameter f: A function takes no parameters, returns a value of type `T` and
                which may throw.
 - returns: A `Future` whose `ValueType` equals the return type of the function `f`.
 */
@available(*, deprecated=1.0)
public func future<T>(ec: ExecutionContext = GCDAsyncExecutionContext(),
    f: () throws -> T)
    -> Future<T> {
    let returnedFuture: Future<T> = Future<T>()
    ec.execute() {
        do {
            let value = try f()
            returnedFuture.complete(Try(value))
        } catch let error {
            returnedFuture.complete(Try(error: error))
        }
    }
    return returnedFuture
}


/**
 Returns a future which will be completed with the result of function `f`
 which will be executed on the given execution context. Function `f` is usually
 a CPU-bound function evaluating a result which takes a significant time to
 complete.

 - parameter ec:   An execution context where the function `f` will be
 executed.

 - parameter f:          A function takes no parameters and which returns a
 value of type `T`.

 - returns:      A Future whose `ValueType` equals T.
 */
@available(*, deprecated=1.0)
public func future<T>(ec: ExecutionContext = GCDAsyncExecutionContext(), f: () -> T)
    -> Future<T> {
    let returnedFuture: Future<T> = Future<T>()
    ec.execute {
        returnedFuture.complete(Try(f()))
    }
    return returnedFuture
}


/**
 Returns a future which will be completed with the result of function `f`
 which will be executed on the given execution context. Function `f` is usually
 a CPU-bound function evaluating a result which takes a significant time to
 complete.

 - parameter ec:   An execution context where the function `f` will be
 executed.

 - parameter f:  A function takes no parameters and returns a value of type
 `T`.

 - returns:      A `Future` whose `ValueType` equals `T`.
*/
@available(*, deprecated=1.0)
public func future<T>(
        ec: ExecutionContext = GCDAsyncExecutionContext(),
        @autoclosure(escaping) f: () -> T)
-> Future<T> {
    let returnedFuture = Future<T>()
    ec.execute() {
        returnedFuture.complete(Try(f()))
    }
    return returnedFuture
}
