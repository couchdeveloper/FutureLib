//
//  CancellationError.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



/**
 Defines errors which belong to the domain "Cancellation". 
 This will be used when a task or operation has been cancelled.
*/
public enum CancellationError: Int, Error {
    
    /// Specifies that the task or operation has been cancelled.
    case cancelled = -1
}


/**
 Equality operator for `CancellationError` and `ErrorType`.
 */
public func == (lhs: CancellationError, rhs: Error) -> Bool {
    if let e = rhs as? CancellationError {
        return lhs.rawValue == e.rawValue
    } else {
        return false
    }
}

/**
 Equality operator for `ErrorType` and `CancellationError`.
 */
public func == (lhs: Error, rhs: CancellationError) -> Bool {
    if let e = lhs as? CancellationError {
        return e.rawValue == rhs.rawValue
    } else {
        return false
    }
}
