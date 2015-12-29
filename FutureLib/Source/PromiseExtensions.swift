//
//  PromiseExtensions.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch




public func promiseWithTimeout(timeout: Double) -> Promise<Void> {
    let promise = Promise<Void>.resolveAfter(timeout, result: Result<Void>(error: PromiseError.Timeout))
    return promise
}




extension Promise {
    
    
    /**
     Returns a future which will be completed with the return value of function `f`
     which will be executed on the given execution context. Function `f` is usually
     a CPU-bound function evaluating a result which takes a significant time to
     complete.
     
     If the funcion `f` throws, the returned future will be completed with the 
     error.
     
     - parameter ec:   An execution context where the function `f` will be
     executed.
     
     - parameter f:  A function with signature `() throws -> T`.
     
     - returns:      A `Future` whose `ValueType` equals `T`.
     */
    public static func future<T>(ec: ExecutionContext = GCDAsyncExecutionContext(), f: () throws -> T) -> Future<T> {
        let promise = Promise<T>()
        ec.execute() {
            promise.resolve(Result<T>(f))
        }
        return promise.future!
    }
    
    
    /**
     Returns a promise which will be resolved after the specfied delay with the
     given result.
     
     - parameter delay: The delay in seconds.
     - parameter result: The result with which the promise will be resolved.
     - returns: A new promise.
     */
    public static func resolveAfter(delay: Double, result: Result<T>) -> Promise {
        let promise = Promise<T>()
        let cr = CancellationRequest()
        let timer = Timer(delay: delay, tolerance: 0, cancellationToken: cr.token) { timer in
            promise.resolve(result)
        }
        timer.resume()
        promise.onRevocation {
            print("Target future disposed, timer will be cancelled") 
            cr.cancel()
        }
        return promise
    }


    
    
    /**
     Returns a promise which will be resolved after the specfied delay with the
     return value from the given function `f`. If `f` throws an error, the promise 
     will be resolved with the same error.
     
     - parameter delay: The delay in seconds.
     - parameter f: A throwing function.
     - returns: A new promise.
     */
    public static func resolveAfter(delay: Double, f: () throws -> ValueType) -> Promise {
        let promise = Promise<T>()
        let cr = CancellationRequest()
        let timer = Timer(delay: delay, tolerance: 0, cancellationToken: cr.token) { _ in
            promise.resolve(Result(f))
        }
        timer.resume()
        promise.onRevocation {
            print("Target future disposed, timer will be cancelled") 
            cr.cancel()
        }
        return promise
    }
    
    
}
