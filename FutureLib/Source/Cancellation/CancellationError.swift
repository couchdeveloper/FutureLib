//
//  CancellationError.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



/**
 An error used when a task or operation has been cancelled.
*/
public enum CancellationError : Int, ErrorType {
    case Cancelled = -1
}


public func == (lhs: CancellationError, rhs: ErrorType) -> Bool {
    if let e = rhs as? CancellationError {
        return lhs.rawValue == e.rawValue
    }
    else {
        return false
    }
}

public func == (lhs: ErrorType, rhs: CancellationError) -> Bool {
    if let e = lhs as? CancellationError {
        return e.rawValue == rhs.rawValue
    }
    else {
        return false
    }
}
