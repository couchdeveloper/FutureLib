//
//  Result.swift
//  Future
//
//  Created by Andreas Grosam on 24.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//

import Foundation

public enum Result<T> {
    
    typealias ValueType = T
    
    case Success([T])
    case Failure(NSError)
    
    
    public init(_ v: T) {
        self = Success([v])
    }
    public init(_ error: NSError) {
        self = Failure(error)
    }
    
    public func map<U>(f: T -> U) -> Result<U> {
        switch self {
        case .Success(let s):
            return Result<U>(f(s[0]))
        case .Failure(let error):
            return Result<U>(error)
        }
    }
    
    public func flatMap<U>(f:T -> Result<U>) -> Result<U> {
        switch self {
        case .Success(let value):
            return f(value[0])
        case .Failure(let error):
            return Result<U>(error)
        }
    }
}

extension Result : Printable, DebugPrintable {
    public var description: String {
        switch self {
            case .Success(let s): return "Success with \(s[0])"
            case .Failure(let error): return "Failure with \(error)"
        }
    }
    public var debugDescription: String {
        return self.description
    }
}

