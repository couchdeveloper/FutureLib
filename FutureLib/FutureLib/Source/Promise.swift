//
//  Promise.swift
//  FutureLib
//
//  Created by Andreas Grosam on 11.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//

import Dispatch



/// Initialize and configure a Logger - mainly for debugging and testing
#if DEBUG
    private let Log = Logger(category: "Promise", verbosity: Logger.Severity.Debug)
    #else
    private let Log = Logger(category: "Promise", verbosity: Logger.Severity.Error)
#endif


extension Promise : ResolverType {

    func unregister<T:Resolvable>(resolvable: T) -> () {
    }

}



/**
    The class Promise complements the class Future in that it provides the API to
    create and resolve a future indirectly through a Promise instance.

    When a Promise instance will be created it creates its associated future which
    can be accessed through the property `future`. Once the future has been retrieved,
    the Promise subsequently holds only a weak reference to the future. That means, 
    if there is no other strong reference to the future and if the future does not 
    have any continuations or if it has been resolved, the future will be destroyed.

    The resolver is the only instance that should resolve the future. However, if
    the returned future is cancelable, other objects may cancel the future. Since 
    canceling a future will remove its continuations and provided there are no other
    strong references to the future, it may be destroyed before the resolver finishes
    its task.
*/
public class Promise<T>
{
    public typealias ValueType = T
    
    private var _future: Future<T>?
    private weak var _weakFuture: Future<T>?
    
    /**
        Initializes the promise whose future is pending.
    
        - parameter resolver: The resolver object which will eventually resove the future.
    */
    public init() {
        _future = Future<T>(resolver: self)
        _weakFuture = _future
    }
    
    /**
        Initializes the promise whose future is fulfilled with value.
    
        - parameter value: The value which fulfills the future.
    */
    public init(_ value : ValueType) {
        _future = Future<T>(value, resolver: self)
        _weakFuture = _future
    }
    
    /**
        Initializes the promise whose future is rejected with error.
    
        - parameter error: The error which rejects the future.
    */
    public init(error : ErrorType) {
        _future = Future<T>(error, resolver: self)
        _weakFuture = _future
    }
    
    /**
        Returns the future.
    
        The first call will "weakyfy" the reference to the future. If there is no
        strong reference elsewhere, subsequent calls will return nil.
    
        - returns: If this is the first call, returns the future. Otherwise it may return nil.
    
        TODO: must be thread-safe
    */
    public final var future : Future<T>? {
        if let future = _weakFuture {
            _future = nil;
            return future
        }
        return nil
    }
    
    
    /**
        Fulfilles the promise's future with value.

        - parameter vaule: The value which resolves the future.
    */
    public final func fulfill(value:T) {
        if let future = _weakFuture {
            future.resolve(Result(value))
        }
        else {
            Log.Warning("Cannot resolve the future: the future has been destroyed prematurely.")
        }
    }
    
    
    /**
        Rejects the promise's future with error.
    
        - parameter error: The error which rejects the future.
    */
    public final func reject(error : ErrorType) {
        if let future = _weakFuture {
            future.resolve(Result(error))
        }
        else {
            Log.Warning("Cannot reject the future: the future has been destroyed prematurely.")
        }
    }
    
    
    // Cancellation
    
    /**
        Registers the continuation `f` with a parameter `error` which will be executed on the
        given execution context when `self`'s future has been cancelled. Self's future will
        transition to the `Cancelled` state only when it is still pending and when it has an
        associated cancellation token which has been cancelled and when it has no continuations 
        or all continuations have been cancelled.
        The continuation will be called with a copy of the error of `self`'s future.
        Retains `self` until it is completed.

        - parameter f: A closure taking an error as parameter.
    */
    internal final func onCancel(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: ErrorType -> ())
    {
//        if let future = _weakFuture {
//            future.onCancel(on: executor, f)
//        }
    }
    
    
    
}

