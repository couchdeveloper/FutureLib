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


public enum PromiseError : Int, ErrorType {
    
    case BrokenPromise = -1
    
}


//extension Promise : ResolverType {
//
//    func unregister<T:Resolvable>(resolvable: T) -> () {
//    }
//
//}



private class RootFuture<T> : Future<T> {
    
    typealias nullary_func = () -> ()

    private var onRevocation : nullary_func?
    
    
    private override init() {
        super.init()
    }
    
    private override init(_ value:T) {
        super.init(value)
    }
    
    private override init(_ error:ErrorType) {
        super.init(error)
    }
    
    deinit {
        if let f = onRevocation {
            if (!isCompleted) {
                dispatch_async(dispatch_get_global_queue(0, 0), f)
            }
        }
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
    
    private var _future: RootFuture<T>?
    private weak var _weakFuture: RootFuture<T>?
    
    /**
        Initializes the promise whose future is pending.
    
        - parameter resolver: The resolver object which will eventually resove the future.
    */
    public init() {
        _future = RootFuture<T>()
        _weakFuture = _future
    }
    
    /**
        Initializes the promise whose future is fulfilled with value.
    
        - parameter value: The value which fulfills the future.
    */
    public init(_ value : ValueType) {
        _future = RootFuture<T>(value)
        _weakFuture = _future
    }
    
    /**
        Initializes the promise whose future is rejected with error.
    
        - parameter error: The error which rejects the future.
    */
    public init(error : ErrorType) {
        _future = RootFuture<T>(error)
        _weakFuture = _future
    }
    
    deinit {
        if let future = _weakFuture {
            if !future.isCompleted {
                future.resolve(Result(PromiseError.BrokenPromise))
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
    public final func onRevocation(f:()->()) {
        if let future = _weakFuture {
            future.onRevocation = f
        }
        else {
            dispatch_async(dispatch_get_global_queue(0, 0), f)
        }
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
    
    
    
    
    
}

