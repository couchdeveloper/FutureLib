//
//  CancellationError.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



/**
 An error used when a task or operation has been cancelled.
*/
public enum CancellationError: Int, ErrorType {
    
    // Indicates that the task or operation has been cancelled.
    case Cancelled = -1
}


/**
 Equality operator for `CancellationError` and `ErrorType`.
 */
public func == (lhs: CancellationError, rhs: ErrorType) -> Bool {
    if let e = rhs as? CancellationError {
        return lhs.rawValue == e.rawValue
    } else {
        return false
    }
}

/**
 Equality operator for `ErrorType` and `CancellationError`.
 */
public func == (lhs: ErrorType, rhs: CancellationError) -> Bool {
    if let e = lhs as? CancellationError {
        return e.rawValue == rhs.rawValue
    } else {
        return false
    }
}
