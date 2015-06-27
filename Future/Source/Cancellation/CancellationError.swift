//
//  CancellationError.swift
//  Future
//
//  Created by Andreas Grosam on 26/06/15.
//
//

import Foundation


/**
    An error type that represents a cancellation which operations can use to
    reject or complete promises or forward it to clients when they have been
    cancelled.
*/
public class CancellationError : NSError {
    
    /**
        A designated initializer which creates a CancellationError with an underlying error.
        The domain equals "Cancellation" and the error code equals -1. The userInfo will have
        a key `NSLocalizedFailureReasonErrorKey` whose value equals "Operation Canclled".
    */
    public init(underlyingError: ErrorType) {
        super.init(domain: "Cancellation", code: -1,
            userInfo: [NSLocalizedFailureReasonErrorKey:"Operation Cancelled",
                NSUnderlyingErrorKey: underlyingError as NSError])
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    /**
        A designated initializer which creates a CancellationError.
        The domain equals "Cancellation" and the error code equals -1.
    */
    public init(_ : Int = 0) {
        super.init(domain: "Cancellation", code: -1,
            userInfo: [NSLocalizedFailureReasonErrorKey:"Operation Cancelled"])
    }
    
}

