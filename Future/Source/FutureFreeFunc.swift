//
//  FututrFreeFunc.swift
//  Future
//
//  Created by Andreas Grosam on 16/06/15.
//
//

import Foundation


/**
    Asynchronously executes the closure f, which is usually a CPU-bound function
    computating a result which takes a significant time to complete, on a private
    execution context returning a future.

    - parameter f:  A closure which takes no parameters and which returns a value
                    of type Result<R> representing the result of the closure.

    - returns:      A Future whose ValueType equals the return type of the given
                    closure.
*/
public func future<R>(f:()->Result<R>) -> Future<R> {
    let returnedFuture :Future<R> = Future<R>(resolver: nil)
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
        switch f() {
        case .Success(let value): returnedFuture.resolve(Result(value))
        case .Failure(let error): returnedFuture.resolve(Result(error))
        }
    })
    return returnedFuture
}


/**
    Asynchronously executes the closure `f`, which is usually a CPU-bound function
    computating a result which takes a significant time to complete, on a private
    execution context returning a future.

    - parameter f:  A closure which takes no parameters and which returns a value
                    of type `R` representing the result of the closure. If the
                    closure fails it throws an error.

    - returns:      A `Future` whose `ValueType` equals the return type of the
                    given closure.
*/
public func future<R>(f:() throws -> R) -> Future<R> {
    let returnedFuture :Future<R> = Future<R>(resolver: nil)
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
        do {
            let value = try f()
            returnedFuture.resolve(Result(value))
        }
        catch let error {
            returnedFuture.resolve(Result(error as NSError))
        }
    })
    return returnedFuture
}



/**
    Asynchronously executes the closure `f`, which is usually a CPU-bound function
    computating a result which takes a significant time to complete, on the
    given execution context `executor` returning a future.

    - parameter executor:   An execution context where the closure `f` will be
                            executed.

    - parameter f:  A closure which takes no parameters and which returns a value
                    of type Result<R> representing the result of the closure.

    - returns:      A Future whose `ValueType` equals the return type of the given
                    closure.
*/
public func future<R>(on executor: ExecutionContext, f:()->Result<R>) -> Future<R> {
    let returnedFuture :Future<R> = Future<R>(resolver:nil)
    executor.execute() {
        switch f() {
        case .Success(let value): returnedFuture.resolve(Result(value))
        case .Failure(let error): returnedFuture.resolve(Result(error))
        }
    }
    return returnedFuture
}


/**
    Asynchronously executes the closure `f`, which is usually a CPU-bound function
    computating a result which takes a significant time to complete, on the given
    execution context returning a future.

    - parameter executor:   An execution context where the closure `f` will be
                            executed.

    - parameter f:  A closure which takes no parameters and which returns a value
                    of type `R` representing the result of the closure. If the
                    closure fails it throws an error.

    - returns:      A `Future` whose `ValueType` equals the return type of the
                    given closure.
*/
public func future<R>(on executor: ExecutionContext, f:() throws ->R) -> Future<R> {
    let returnedFuture :Future<R> = Future<R>(resolver: nil)
    executor.execute() {
        do {
            let value = try f()
            returnedFuture.resolve(Result(value))
        }
        catch let error {
            returnedFuture.resolve(Result(error as NSError))
        }
    }
    return returnedFuture
}




