//
//  ExecutionContext.swift
//  Future
//
//  Created by Andreas Grosam on 04/04/15.
//
//

import Foundation



struct Asynchronously {}
struct Synchronously {}

/// An ExecutionContext is a thing that can execute closures.
public protocol ExecutionContext {
    
    /// Asynchronuosly executes the given closure f on its execution context.
    ///
    /// :param: f The closure takeing no parameters and returning ().
    func execute(f:()->()) -> ()
}





// MARK: - ExecutionContext Extension


extension dispatch_queue_t : ExecutionContext {
    public func execute(f:()->()) -> () {
        dispatch_async(self, f)
    }
}


