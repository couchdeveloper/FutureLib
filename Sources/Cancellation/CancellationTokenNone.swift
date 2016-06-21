//
//  CancellationTokenNone.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

/**
 A special Cancellation Token implementation which represents a token which 
 cannot be cancelled.
 */
public struct CancellationTokenNone: CancellationTokenType {

    /// Initializes a `CancellationTokenNone`.
    public init() {}

    /// - returns: `false`.
    public var isCancellationRequested: Bool { return false }

    /// Does nothing and returns -1.
    public func onCancel(on executor: ExecutionContext,
        cancelable: Cancelable,
        f: (Cancelable)->()) -> Int { return -1 }

    /// Does nothing and returns -1.
    public func onCancel(on executor: ExecutionContext,
        f: ()->()) -> Int { return -1 }

    public func register(on executor: ExecutionContext,
        f: (Bool)->()) -> Int { return -1 }

    /// Does nothing.
    public func unregister(_ id: Int) { }
}
