//
//  CancellationError.swift
//
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//




/// Defines a "Cancellation Error". 
/// This will be used when a task or operation has been cancelled.
public struct CancellationError: Error, Equatable, CustomStringConvertible {
    
    /// The message `self` has been initialized with.
    public var message: String

    
    /// Initializes a `CancellationError` with a given message string.
    ///
    /// - parameter message: A string describing the error. The default value equals `"Operation cancelled"`.
    ///
    /// - returns: A `CancellationError` instance.
    public init(message: String = "Operation cancelled") {
        self.message = message
    }
    
    /// Returns a string representation of the error.
    public var description: String {
        return "CancellationError: \(self.message)"
    }
}


/// Equality operator for `CancellationError`.
/// 
/// The operands are considered _equal_ if their descriptions compare equal. 
/// - parameter lhs: The left-hand operand.
/// - parameter rhs: The right-hand operand.
///
/// - returns: Returns `true` if the operands are equal.
public func ==(lhs: CancellationError, rhs: CancellationError) -> Bool {
    return lhs.message == rhs.message
}


///  Equality operator for `CancellationError` and `ErrorType`.
/// 
/// - parameter lhs: A cancellation error.
/// - parameter rhs: An error.
///
/// - returns: `true` if `rhs` is a `CancellationError` and their descriptions compare equal.
public func ==(lhs: CancellationError, rhs: Error) -> Bool {
    if let e = rhs as? CancellationError {
        return lhs == e
    } else {
        return false
    }
}


/// Equality operator for `ErrorType` and `CancellationError`.
///
/// - parameter lhs: An error.
/// - parameter rhs: A cancellation error.
///
/// - returns: `true` if `lhs` is a `CancellationError` and their descriptions compare equal.
public func ==(lhs: Error, rhs: CancellationError) -> Bool {
    if let e = lhs as? CancellationError {
        return e == rhs
    } else {
        return false
    }
}
