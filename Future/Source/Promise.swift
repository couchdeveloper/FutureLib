//
//  Promise.swift
//  Future
//
//  Created by Andreas Grosam on 11.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//

import Foundation



// MARK: Promise

/// The class Promise complements the class Future in that it provides the API to
/// create and resolve a future indirectly through a Promise instance.
///
/// When a Promise instance will be created it creates its associated future which
/// can be accessed through the property `future`. Once the future has been retrieved,
/// the Promise subsequently holds only a weak reference to the future. That means, 
/// if there is no other strong reference to the future and if the future does not 
/// have any continuations or if it has been resolved, the future will be destroyed.
///
/// The resolver is the only instance that should resolve the future. However, if
/// the returned future is cancelable, other objects may cancel the future. Since 
/// canceling a future will remove its continuations and provided there are no other
/// strong references to the future, it may be destroyed before the resolver finishes
/// its task.
public class Promise<T> : Resolver
{
    public typealias ValueType = T
    
    private var _resolver : Resolver?
    private var _future: Future<T>?
    private weak var _weakFuture: Future<T>?
    
    /// Initializes the promise whose future is pending.
    ///
    /// :param: resolver The resolver object which will eventually resove the future.
    public init(_ resolver : Resolver? = nil) {
        _resolver = resolver
        _future = Future<T>(resolver: self)
    }
    
    /// Initializes the promise whose future is fulfilled with value.
    ///
    /// :param: value The value which fulfills the future.
    /// :param: resolver The resolver object which will eventually resove the future.
    public init(_ value:ValueType, _ resolver : Resolver) {
        _resolver = resolver
        _future = Future<T>(value, resolver: self)
    }
    
    /// Initializes the promise whose future is rejected with error.
    ///
    /// :param: error The error which rejects the future.
    public init(error:NSError) {
        _future = Future<T>(error, resolver: self)
    }
    
    /// Retrieves the future.
    ///
    /// The first call will "weakyfy" the reference to the future. If there is no
    /// strong reference elsewhere, subsequent calls will return nil.
    ///
    /// :returns: If this is the first call, returns the future. Otherwise it may return nil.
    ///
    /// TODO: must be thread-safe
    public var future : Future<T>? {
        if let future = _future {
            _weakFuture = future
            _future = nil;
            return future
        }
        else if let strongFuture = _weakFuture {
            return strongFuture
        }
        return nil
    }
    
    /// Implements the Resolver Protocol
    ///
    /// :returns: nil since a Promise is by itself not cancelable.
    public var cancelable : Cancelable? {
        return nil;
    }
    
    /// Returns the dependent resolver if any, otherwise returns nil.
    public var resolver : Resolver? {
        return nil // TODO implement
    }
    
    
    /// Fulfilles the promise's future with value.
    ///
    /// :param: vaule The value which resolves the future.
    public func fulfill(value:T) {
        if let future = _weakFuture {
            future.resolve(value)
        }
        else {
            Log.Warning("Cannot resolve the future: the future has been destroyed prematurely.")
        }
    }
    
    /// Rejects the promise's future with error.
    ///
    /// :param: error The error which rejects the future.
    public func reject(error:NSError) {
        if let future = _weakFuture {
            future.resolve(error)
        }
        else {
            Log.Warning("Cannot reject the future: the future has been destroyed prematurely.")
        }
    }
    
}

