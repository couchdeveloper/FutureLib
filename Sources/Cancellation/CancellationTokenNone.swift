//
//  CancellationTokenNone.swift
//  FutureLib
//
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import Dispatch


/// A special Cancellation Token implementation which represents a token which
/// cannot be cancelled.
public struct CancellationTokenNone: CancellationTokenType {

    /// Initializes a `CancellationTokenNone`.
    ///
    /// - returns: An instance of a CancellationTokenNone.
    public init() {}

    /// Returns always `false`.
    public var isCancellationRequested: Bool { return false }
    
    /// Returns always `true`.
    public var isCompleted: Bool { return true }
    
    
    /// A NoOp function.
    ///
    /// - parameter queue:      unused
    /// - parameter cancelable: unused
    /// - parameter f:          unused
    ///
    /// - returns: `nil`.
    public func onComplete(queue: DispatchQueue = DispatchQueue.global(), f: @escaping (Bool) -> ()) -> EventHandlerIdType? {
        return nil 
    }
    

    /// A NoOp function.
    ///
    /// - parameter queue:      unused
    /// - parameter cancelable: unused
    /// - parameter f:          unused
    ///
    /// - returns: `nil`.
    public func onCancel(queue: DispatchQueue = DispatchQueue.global(),
        cancelable: Cancelable,
        f: @escaping (Cancelable)->()) -> EventHandlerIdType? { 
        return nil 
    }

    /// A NoOp function.
    ///
    /// - parameter queue: unused
    /// - parameter f:     unused
    ///
    /// - returns: `nil`.
    public func onCancel(queue: DispatchQueue = DispatchQueue.global(),
        f: @escaping ()->()) -> EventHandlerIdType? { 
        return nil 
    }

//    /// A NoOp function.
//    ///
//    /// - parameter queue: unused
//    /// - parameter f:     unused
//    ///
//    /// - returns:  always -1.
//    public func register(queue: DispatchQueue = DispatchQueue.global(),
//        f: @escaping (Bool)->()) -> Int { return -1 }
//
//    /// A NoOp function.
//    ///
//    /// - parameter id: unused
//    public func unregister(id: Int) { }
}
