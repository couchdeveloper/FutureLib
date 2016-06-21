//
//  TestError.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


// Error type

enum TestError: Int, ErrorProtocol {
    case failed
    case failed2
    case failed3
}

//func == (lhs: TestError, rhs: TestError) -> Bool { return lhs.isEqual(rhs) }

func == (lhs: TestError, rhs: ErrorProtocol) -> Bool {
    if let e = rhs as? TestError {
        return lhs.rawValue == e.rawValue
    }
    else {
        return false
    }
}

func == (lhs: ErrorProtocol, rhs: TestError) -> Bool {
    if let e = lhs as? TestError {
        return e.rawValue == rhs.rawValue
    }
    else {
        return false
    }
}
