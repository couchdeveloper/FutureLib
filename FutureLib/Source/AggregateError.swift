//
//  AggregateError.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


import Foundation

/**
 An error which encapsulates a sequence of errors.
 */
public struct AggregateError : ErrorType {
    
    let errors: AnySequence<ErrorType>
    
    init(_ errors: AnySequence<ErrorType>) {
        self.errors = errors
    }
    
}


// MARK: Extension CustomStringConvertible

extension AggregateError : CustomStringConvertible {
    
    /**
     - returns: A description of `self`.
     */
    public var description: String {
        var s = "AggregateError with errors:"
        errors.forEach {
            s.appendContentsOf("\n\t\($0 as NSError)")
        }
        return s
    }
}
