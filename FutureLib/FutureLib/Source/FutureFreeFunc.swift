//
//  FututrFreeFunc.swift
//  FutureLib
//
//  Created by Andreas Grosam on 16/06/15.
//
//

import Dispatch

/**
    Returns a future which will be completed with the result of function `f`
    which will be executed on the given execution context. Function `f` is usually
    a CPU-bound function computating a result which takes a significant time to
    complete.

    - parameter executor:   An execution context where the function `f` will be
                            executed.

    - parameter f:  A function takes no parameters and returns a value of type 
                    `Result<T>`.

    - returns:      A `Future` whose `ValueType` equals `T`.
*/
public func future<T>(on executor: ExecutionContext = GCDAsyncExecutionContext(), _ f:()->Result<T>) -> Future<T> {
    let returnedFuture :Future<T> = Future<T>()
    executor.execute() {
        switch f() {
        case .Success(let value): returnedFuture.resolve(Result(value))
        case .Failure(let error): returnedFuture.resolve(Result(error: error))
        }
    }
    return returnedFuture
}




/**
    Returns a future which will be completed with the result of function `f` 
    which will be executed on the given execution context. Function `f` is usually 
    a CPU-bound function computating a result which takes a significant time to
    complete.

    - parameter executor:   An execution context where the function `f` will be
                            executed.

    - parameter f:  A function takes no parameters, returns a value of type `T` 
                    and which may throw.

    - returns:      A `Future` whose `ValueType` equals the return type of the
                    function `f`.
*/
public func future<T>(on executor: ExecutionContext = GCDAsyncExecutionContext(), _ f:() throws -> T) -> Future<T> {
    let returnedFuture :Future<T> = Future<T>()
    executor.execute() {
        do {
            let value = try f()
            returnedFuture.resolve(Result(value))
        }
        catch let error {
            returnedFuture.resolve(Result(error: error))
        }
    }
    return returnedFuture
}

/**
    Returns a future which will be completed with the result of function `f`
    which will be executed on the given execution context. Function `f` is usually
    a CPU-bound function computating a result which takes a significant time to
    complete.

    - parameter executor:   An execution context where the function `f` will be
                            executed.

    - parameter f:          A function takes no parameters and which returns a  
                            value of type `T`.

    - returns:      A Future whose `ValueType` equals T.
*/
public func future<T>(on executor: ExecutionContext = GCDAsyncExecutionContext(), _ f:()-> T) -> Future<T> {
    let returnedFuture :Future<T> = Future<T>()
    executor.execute {
        returnedFuture.resolve(Result(f()))
    }
    return returnedFuture
}



/**
    Returns a future which will be completed with the result of function `f`
    which will be executed on the given execution context. Function `f` is usually
    a CPU-bound function computating a result which takes a significant time to
    complete.

    - parameter executor:   An execution context where the function `f` will be
    executed.

    - parameter f:  A function takes no parameters and returns a value of type
                    `T`.

    - returns:      A `Future` whose `ValueType` equals `T`.
*/
public func future<T>(
        on executor: ExecutionContext = GCDAsyncExecutionContext(),
        @autoclosure(escaping) _ f:() -> T)
-> Future<T>
{
    let returnedFuture = Future<T>()
    executor.execute() {
        returnedFuture.resolve(Result(f()))
    }
    return returnedFuture
}





