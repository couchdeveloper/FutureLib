//
//  FutureOperators.swift
//  FutureLib
//
//  Created by Andreas Grosam on 08.12.15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


private let sync_queue = dispatch_queue_create("private sync queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0))
private let syncExecutionContext = GCDAsyncExecutionContext(sync_queue)


func _flatten<A,B,C>(tuple: (A, B), _ c: C) -> (A,B,C) {
    return (tuple.0, tuple.1, c)
}

func _flatten<A, C>(tuple: (A), _ c: C) -> (A,C) {
    return (tuple, c)
}




public func ||<T>(left: Future<T>, right: Future<T>) -> Future<(T)> {
    let promise = Promise<(T)>()
    let cr = CancellationRequest()
    left.onComplete(on: syncExecutionContext, cancellationToken: cr.token) { resultLeft in
        switch resultLeft {
        case .Failure(let leftError):
            right.onComplete(on: syncExecutionContext, cancellationToken: cr.token) { resultRight in
                switch resultRight {
                case .Failure(let rightError):
                    promise.reject(AggregateError(AnySequence([leftError, rightError])))
                case .Success(let rightValue):
                    promise.fulfill(rightValue)
                }
            }
        case .Success(let leftValue):
            promise.fulfill(leftValue)
            cr.cancel()
        }
    }
    return promise.future!
    
}



public func &&<T,U>(left: Future<T>, right: Future<U>) -> Future<(T,U)> {
    let promise = Promise<(T,U)>()
    let cr = CancellationRequest()
    left.onComplete(on: syncExecutionContext, cancellationToken: cr.token) { resultLeft in
        switch resultLeft {
        case .Success(let leftValue):
            right.onComplete(on: syncExecutionContext, cancellationToken: cr.token) { resultRight in
                switch resultRight {
                case .Success(let rightValue):
                    let ftuple = _flatten(leftValue, rightValue)
                    promise.fulfill(ftuple)
                case .Failure(let error):
                    promise.reject(error)
                }
            }
        case .Failure(let error):
            promise.reject(error)
            cr.cancel()
        }
    }
    return promise.future!
}


public func &&<A,B,C>(left: Future<(A,B)>, right: Future<C>) -> Future<(A,B,C)> {
    let promise = Promise<(A,B,C)>()
    let cr = CancellationRequest()
    left.onComplete(on: syncExecutionContext, cancellationToken: cr.token) { resultLeft in
        switch resultLeft {
        case .Success(let leftValue):
            right.onComplete(on: syncExecutionContext, cancellationToken: cr.token) { resultRight in
                switch resultRight {
                case .Success(let rightValue):
                    let ftuple = _flatten(leftValue, rightValue)
                    promise.fulfill(ftuple)
                case .Failure(let error):
                    promise.reject(error)
                }
            }
        case .Failure(let error):
            promise.reject(error)
            cr.cancel()
        }
    }
    return promise.future!
}

