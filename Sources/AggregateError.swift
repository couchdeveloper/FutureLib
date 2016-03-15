//
//  AggregateError.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



/**
 An error encapsulating a sequence of errors.
 */
public struct AggregateError: ErrorType {

    /// Returns the errors that `self` aggregates as an array.
    public var errors: [ErrorType]

    /// Initializes an `AggregateError` with an empty list of errors.
    public init() {
        self.errors = [ErrorType]()
    }
    
    /// Initializes an `AggregateError` with a single error.
    public init(error: ErrorType) {
        self.errors = [error]
    }
    
    /// Initializes an `AggregateError` with a sequence of errors.
    public init(_ errors: AnySequence<ErrorType>) {
        self.errors = [ErrorType](errors)
    }
    
    /// Adds an error to `self`.
    public mutating func add(error: ErrorType) {
        errors.append(error)
    }
    
    
}


// MARK: Extension CustomStringConvertible

extension AggregateError: CustomStringConvertible {

    /**
     - returns: A description of `self`.
     */
    public var description: String {
        var s = "AggregateError with errors:"
        errors.forEach {
            s.appendContentsOf("\n\t\(String($0.dynamicType)).\(String($0))")
        }
        return s
    }
}


// MARK: Extension CustomDebugStringConvertible

extension AggregateError: CustomDebugStringConvertible {
    
    /**
     - returns: A description of `self`.
     */
    public var debugDescription: String {
        var s = "AggregateError with errors:"
        errors.forEach {
            s.appendContentsOf("\n\t\(String(reflecting: $0))")
        }
        return s
    }
}
