//
//  TestError.swift
//  FutureLib
//
//  Created by Andreas Grosam on 21/09/15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Foundation


// Error type

enum TestError : ErrorType {
    case Failed
    
    internal func isEqual(other: TestError) -> Bool {
        return true
    }
    internal func isEqual(other: ErrorType) -> Bool {
        if let _ = other as? TestError {
            return true
        }
        else {
            return false
        }
    }
}

