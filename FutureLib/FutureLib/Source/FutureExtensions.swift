//
//  FutureExtensions.swift
//  FutureLib
//
//  Created by Andreas Grosam on 07/08/15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Foundation

// A collecition of useful utility functions based on Future

private enum ResultError : Int, ErrorType {
    
    case Undefined = 0
    
}


/**
    A couple of convenience methods which return a completed future without
    requiring a promise object.
*/
extension Future {
    
    static public func failed(error: ErrorType) -> Future<ValueType> {
        return Future<ValueType>(error: error)
    }
    
    
    static public func succeeded(value: ValueType) -> Future<ValueType> {
        return Future<ValueType>(value: value)
    }
    

    static public func failedAfter(delay: Double, cancellationToken: CancellationTokenType = CancellationTokenNone(), error: ErrorType) -> Future<ValueType> {
        let returnedFuture = Future<ValueType>()
        let timer = Timer(delay: delay, tolerance: 0, cancellationToken: cancellationToken, queue: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f: { _ in
            returnedFuture.resolve(Result<ValueType>(error: error))
        })
        cancellationToken.onCancel(on: GCDAsyncExecutionContext()) {
            returnedFuture.resolve(Result<ValueType>(error: CancellationError.Cancelled))
        }
        timer.start()
        return returnedFuture
    }
    
    
    static public func succeededAfter(delay: Double, cancellationToken: CancellationTokenType = CancellationTokenNone(), value: ValueType) -> Future<ValueType> {
        let returnedFuture = Future<ValueType>()
        let timer = Timer(delay: delay, tolerance: 0, cancellationToken: cancellationToken, queue: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f: { _ in
            returnedFuture.resolve(Result<ValueType>(value))
        })
        cancellationToken.onCancel(on: GCDAsyncExecutionContext()) {
            returnedFuture.resolve(Result<ValueType>(error: CancellationError.Cancelled))
        }
        timer.start()
        return returnedFuture
    }
    
}



extension CollectionType where Generator.Element: FutureType {
    
    public typealias ResultType = Result<Generator.Element.ValueType>
    
    public func whenAllComplete<U>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationTokenType = CancellationTokenNone(),
        f: AnySequence<ResultType> -> U)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        onAllComplete(on: ec, cancellationToken: cancellationToken) { results -> Void in
            returnedFuture.resolve(Result(f(results)))
            return ()
        }
        return returnedFuture
    }
    
    
    
    public func  onAllComplete<U>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationTokenType = CancellationTokenNone(),
        f: AnySequence<ResultType> -> U)
    {
        let sync_queue = dispatch_queue_create("private sync queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0))
        let private_ec = GCDAsyncExecutionContext(sync_queue)
        private_ec.execute {
            var count = 0
            for future in self {
                ++count
                future.onComplete(on: private_ec, cancellationToken: cancellationToken) { r in
                    if --count == 0 {
                        let results = AnySequence(self.map {$0.result!})
                        ec.execute {
                            f(results)
                        }
                    }
                }
            }
        }
        return ()
    }
    
    
    public func onFirstSuccess<U>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        f: (Int, ResultType) -> U)
    {
        let cts = CancellationRequest()
        let ct = cts.token
        cancellationToken.onCancel {
            cts.cancel()
        }
        let sync_queue = dispatch_queue_create("private sync queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0))
        let private_ec = GCDAsyncExecutionContext(sync_queue)
        private_ec.execute {
            for (i, future) in self.enumerate() {
                future.onComplete(on: private_ec, cancellationToken: ct) { r in
                    switch (r) {
                    case .Success:
                        // It is ensured that the given closure will be called only once by asking the cts.
                        if !cts.isCancellationRequested {
                            ec.execute {
                                f(i, r)
                            }
                            cts.cancel()
                        }
                        break
                    case .Failure: break
                    }
                }
            }
        }
        return ()
    }
    

    public func onFirstFailure<U>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        f: [ResultType] -> U)
    {
        fatalError("not yet implemented")
    }
    

    
    public func whenFirstSuccess<U>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        f: [ResultType] -> U)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        fatalError("not yet implemented")
        return returnedFuture
    }
    
    
    public func onFirstFailure<U>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        f: [ResultType] -> U)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        fatalError("not yet implemented")
        return returnedFuture
    }
    

}

