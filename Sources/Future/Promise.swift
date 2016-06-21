//
//  Promise.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch




/**
 Defines errors which belong to the domain "Promise".
*/
public enum PromiseError: Int, ErrorProtocol {

    /// Specifies that the promise has been deinitialized before its associated future has been completed.
    case brokenPromise = -1
    
    /// Specifies that the promise has been completed due to a timeout.
    case timeout = -2

}




/**
 A _promise_ complements a _future_ in that it provides the public API to
 create and complete a future _indirectly_ through an instance of a `Promise`.
 Note, that a future cannot be created neither can it be completed directly.

 When a `Promise` instance will be created it creates its _associated future_ which
 can be accessed through the property `future`.

 Usually, the promise will be created and solely owned by an object or a function
 that performs the underlying task which eventually _resolves_ the promise when
 the task is finished. When the promise will be resolved, it immediately completes
 its associated future accordingly.

 Once its future has been retrieved from the promise, the promise subsequently
 holds only a weak reference to its future. That means, if there is no other strong
 reference to the future and if the future does not have any continuations or if
 it has been completed, the future will be destroyed.

 The following example shows the typical use case:

 ```swift
 func asyncTask() -> Future<String> {
     let promise = Promise<String>()
     doSomethingAsyncWithCompletion { (result, error) -> Void in
         if let r = result {
             promise.fulfill(result)
         }
         else {
             promise.reject(error)
         }
     }
     return promise.future!
 }
 ```

 A promise can register a handler (a closure) which will be called when its
 associated future has been destroyed. A client can utilize this handler for example
 in order to cancel the underlying tasks - since when there is no future anymore,
 obviously there is nothing which is interested in the result anymore and the task
 can be aborted in order to release resources.
 */
public class Promise<T> {
    public typealias ValueType = T

    private var _future: RootFuture<T>?
    private weak var _weakFuture: RootFuture<T>?

    /**
     Initializes the promise whose future is pending.
     */
    public init() {
        _future = RootFuture<T>()
        _weakFuture = _future
    }

    /**
     Initializes the promise whose future is fulfilled with value.

     - parameter value: The value which fulfills the future.
     */
    public init(value: ValueType) {
        _future = RootFuture<T>(value: value)
        _weakFuture = _future
    }


    /**
     Initializes the promise whose future is rejected with error.

     - parameter error: The error which rejects the future.
     */
    public init(error: ErrorProtocol) {
        _future = RootFuture<T>(error: error)
        _weakFuture = _future
    }


    /**
     Deinitializes `self`. If `self` has not been resolved, the associated
     future will be completed with the error `PromiseError.BrokenPromise`.
     */
    deinit {
        if let future = _weakFuture {
            if future.sync.isSynchronized() {
                future._tryComplete(Try(error: PromiseError.brokenPromise))
            } else {
                future.tryComplete(Try(error: PromiseError.brokenPromise))
            }
        }
    }


    /**
     Sets the closure `f` which will be called when the future will be
     destroyed and is not yet completed. This will only happen when there are
     no continuations and no other strong references to the future - that is,
     no one will ever actually receive the eventual result of the promise.

     The closure `f` will be executed on a private execution context.

     A service provider can register a handler in order to get notified when
     the future gets prematurely destroyed. If the result is still not yet
     computed, this means that the future has abandoned its interest in the
     result. The service provider may then choose to cancel its operation.

     - parameter f: The closure
     */
    public final func onRevocation(_ f:()->()) {
        if let future = _weakFuture {
            future.onRevocation = f
        } else {
            DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(0))).async(execute: f)
        }
    }


    /**
     Returns the future.

     The first call will "weakyfy" the reference to the future. If there is no
     strong reference elsewhere, subsequent calls will return `nil`.

     - returns: If this is the first call, returns the future. Otherwise it may return `nil`.

     TODO: must be thread-safe
     */
    public final var future: Future<T>? {
        if let future = _weakFuture {
            _future = nil
            return future
        }
        return nil
    }


    /**
     Fulfill the promise with the given value.
     Subsequently completes `self`'s associated future with the same value.
     If the promise is already resolved or if its associated future has been
     prematurely deinitialized, the method has no effect.

     - parameter value: The value which the promise will be bound to.
     */
    public final func fulfill(_ value: T) {
        if let future = _weakFuture {
            future.complete(Try(value))
        }
    }


    /**
     Reject the promise with the given error.
     Subsequently completes `self`'s associated future with the same error.
     If the promise is already resolved or if its associated future has been
     prematurely deinitialized, the method has no effect.

     - parameter error: The error which the promise will be bound to.
    */
    public final func reject(_ error: ErrorProtocol) {
        if let future = _weakFuture {
            future.complete(Try(error: error))
        }
    }


    /**
     Resolve the promise with the given result and subsequently completes `self`'s 
     associated future with the same result. 
     
     If the promise is already resolved an assertion is triggered.
     
     If its associated future has been prematurely deinitialized, the method has 
     no effect.  

     - parameter result: The result which the promise will be bound to.
     */
    public final func resolve(_ result: Try<T>) {
        if let future = _weakFuture {
            future.complete(result)
        }
    }

    /**
     Attempt to resolve the promise with the given result. If the associated 
     future is not yet completed, subsequently completes `self`'s associated 
     future with the same result.
     If the promise is already resolved or if its associated future has been
     prematurely deinitialized, the method has no effect.
     
     - parameter result: The result which the promise will be bound to.
     */
    public final func tryResolve(_ result: Try<T>) {
        if let future = _weakFuture {
            _ = future.tryComplete(result)
        }
    }
    

    /**
     Resolve the promise with a deferred result represented by a future.
     When the future completes, completes `self`'s associated future with the
     same result.
     If the promise is already resolved or if its associated future has been
     prematurely deinitialized, the method has no effect.

     - parameter future: The future whose eventual result will complete `self`.
     */
    public final func resolve(_ future: Future<T>) {
        if let future = _weakFuture {
            future.completeWith(future)
        }
    }


}
