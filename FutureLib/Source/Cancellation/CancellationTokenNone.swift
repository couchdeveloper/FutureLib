//
//  CancellationTokenNone.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Foundation


public struct CancellationTokenNone: CancellationTokenType {

    public init() {}

    public var isCancellationRequested: Bool { return false }

    public func onCancel(on executor: ExecutionContext,
        cancelable: Cancelable,
        f: (Cancelable)->()) -> Int { return -1 }

    public func onCancel(on executor: ExecutionContext,
        f: ()->()) -> Int { return -1 }

    public func register(on executor: ExecutionContext,
        f: (Bool)->()) -> Int { return -1 }

    public func unregister(id: Int) { }
}
