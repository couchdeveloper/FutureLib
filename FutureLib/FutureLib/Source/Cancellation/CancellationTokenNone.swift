//
//  CancellationTokenNone.swift
//  FutureLib
//
//  Created by Andreas Grosam on 20/09/15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Foundation


public struct CancellationTokenNone : CancellationTokenType {

    public init() {}
    
    public var isCancellationRequested : Bool { return false }
    
    public func onCancel(on executor: AsyncExecutionContext, cancelable: Cancelable, _ f: (Cancelable)->()) {}
    public func onCancel(on executor: AsyncExecutionContext, _ f: ()->()) {}
}