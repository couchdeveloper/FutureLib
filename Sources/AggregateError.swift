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

    public var errors: [ErrorType]

    public init() {
        self.errors = [ErrorType]()
    }
    
    public init(error: ErrorType) {
        self.errors = [error]
    }
    
    public init(_ errors: AnySequence<ErrorType>) {
        self.errors = [ErrorType](errors)
    }
    
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
