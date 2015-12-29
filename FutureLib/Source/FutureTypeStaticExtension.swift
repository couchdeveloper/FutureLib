//
//  FutureTypeStaticExtension.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//




/**
 A couple of convenience methods which return a completed future without
 requiring a promise object.
 */
extension FutureType {

    /**
     Creates a future which is completed with `error`.
     - parameter error: The error with which the future will be completed.
     - returns: A completed future.
     */
    static public func failed(error: ErrorType) -> Future<ValueType> {
        return Future<ValueType>(error: error)
    }


    /**
     Creates a future which is completed with `value`.
     - parameter value: The value with which the future will be completed.
     - returns: A completed future.
     */
    static public func succeeded(value: ValueType) -> Future<ValueType> {
        return Future<ValueType>(value: value)
    }


    /**
     Creates a pending future which will be completed with the given error after
     the specified delay. If there is a cancellation requested before the delay
     expires, the returned future will be completed with `CancellationError.Cancelled`.
     
     - parameter delay: The delay in seconds.
     - parameter cancellationToken: A cancellation token which will be monitored.
     - parameter error: The error with which the future will be completed after the delay.
     - returns: A new future.
     */
    static public func failedAfter(delay: Double, cancellationToken: CancellationTokenType = CancellationTokenNone(), error: ErrorType)
        -> Future<ValueType>
    {
        let returnedFuture = Future<ValueType>()
        let cid = cancellationToken.onCancel(on: GCDAsyncExecutionContext()) {
            returnedFuture.complete(Result<ValueType>(error: CancellationError.Cancelled))
        }
        // Perhaps, we should capture returnedFuture weakly?!
        let timer = Timer(delay: delay, tolerance: 0, cancellationToken: cancellationToken) { _ in
            returnedFuture.complete(Result<ValueType>(error: error))
            cancellationToken.unregister(cid)
        }
        timer.resume()
        return returnedFuture
    }


    /**
     Creates a pending future which will be completed with the given value after
     the specified delay. If there is a cancellation requested before the delay
     expires, the returned future will be completed with `CancellationError.Cancelled`.
     
     - parameter delay: The delay in seconds.
     - parameter cancellationToken: A cancellation token which will be monitored.
     - parameter value: The value with which the future will be completed after the delay.
     - returns: A future.
     */
    static public func succeededAfter(delay: Double, cancellationToken: CancellationTokenType = CancellationTokenNone(), value: ValueType)
        -> Future<ValueType>
    {
        let returnedFuture = Future<ValueType>()
        let cid = cancellationToken.onCancel(on: GCDAsyncExecutionContext()) {
            returnedFuture.complete(Result<ValueType>(error: CancellationError.Cancelled))
        }
        // Perhaps, we should capture returnedFuture weakly?!
        let timer = Timer(delay: delay, tolerance: 0, cancellationToken: cancellationToken) { _ in
            returnedFuture.complete(Result<ValueType>(value))
            cancellationToken.unregister(cid)
        }
        timer.resume()
        return returnedFuture
    }

}



