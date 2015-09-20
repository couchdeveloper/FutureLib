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


extension CollectionType where Generator.Element: FutureType {
    
    typealias ResultType = Result<Generator.Element.ValueType>
    
    func whenAllComplete<U>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        f: [ResultType] -> U)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        onAllComplete(on: ec, cancellationToken: cancellationToken) { results -> Void in
            returnedFuture.resolve(Result(f(results)))
            return ()
        }
        return returnedFuture
    }
    
    
    
    func onAllComplete<U>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        f: [ResultType] -> U)
    {
        let sync_queue = dispatch_queue_create("private sync queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0))
        let private_ec = GCDAsyncExecutionContext(sync_queue)
        private_ec.execute {
            var count = 0
            for future in self {
                ++count
                future.onComplete(on: private_ec, cancellationToken: cancellationToken) { r in
                    if --count == 0 {
                        let results = self.map {$0.result!}
                        ec.execute {
                            f(results)
                        }
                    }
                }
            }
        }
        return ()
    }
    
    
    func onFirstSuccess<U>(
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

    func onFirstFailure<U>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        f: [ResultType] -> U)
    {
    }
    

    
    func whenFirstSuccess<U>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        f: [ResultType] -> U)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        return returnedFuture
    }
    
    func onFirstFailure<U>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        f: [ResultType] -> U)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        return returnedFuture
    }
    

}

