//
//  Result.swift
//  Future
//
//  Created by Andreas Grosam on 24.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//



///**
//    Enum ResultError defines errors which will be thrown by a Result if an 
//    exceptional error occurs.
//*/
//public enum ResultError : Int, ErrorType {
//    case Faulted = -1
//}


/**
    The generic type `Result` represents the result of a computation which
    either yields a value of type `T` or an error of type `NSError`.
*/
public enum Result<T>{
    
    typealias ValueType = T
    
    case Success(ValueType)
    case Failure(ErrorType)
    
    /**
        Creates and initializes a Result with the given value `v`.
    
        - parameter v: The value with which Result will be initialzed.
    */
    public init(_ v: T) {
        self = Success(v)
    }
    
    /**
        Creates and initializes a Result with the given error `error`.
    
        - parameter error: The error with which Result will be initialzed.
    */
    public init(_ error: ErrorType) {
        self = Failure(error)
    }
    
    /**
        Creates and initializes a Result with the return value of the given
        closure. When the closure fails and throws and error, the result will be
        initialized with the error thrown from the closure.
    */
    public init(_ f: Void throws -> T) {
        do {
            self = Success(try f())
        }
        catch let ex  {
            self = Failure(ex)
        }
    }
    
    
    public var isSuccess: Bool {
        get {
            switch self {
            case .Success: return true
            case .Failure: return false
            }
        }
    }
    

    public var isFailure: Bool {
        get {
            switch self {
            case .Success: return false
            case .Failure: return true
            }
        }
    }
    

    public func map<U>(@noescape f: T -> U) -> Result<U> {
        switch self {
        case .Success(let s):
            return Result<U>(f(s))
        case .Failure(let error):
            return Result<U>(error)
        }
    }
    
    public func flatMap<U>(@noescape f:T -> Result<U>) -> Result<U> {
        switch self {
        case .Success(let value):
            return f(value)
        case .Failure(let error):
            return Result<U>(error)
        }
    }
    
    
    /**
        Returns the Success value of self if it succeeded. Otherwise throws
        the Failure value.
    */
    public func value() throws -> T {
        switch self {
            case .Success(let value): return value
            case .Failure(let error):
                throw error // NSError(domain: "ResultError", code: ResultError.Faulted.rawValue, userInfo: [NSUnderlyingErrorKey: error])
        }
    }
}


/**
    Implements the CustomStringConvertible and CustomDebugStringConvertible protocol.
*/
extension Result : CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        switch self {
            case .Success(let s): return "Success with \(s)"
            case .Failure(let error): return "Failure with \(error)"
        }
    }
    public var debugDescription: String {
        return self.description
    }
}


///**
//    Implements operator== for Result<T> whose ValueType conforms to Equatable.
//*/
//public func ==<T:Equatable>(lhs: Result<T>, rhs: Result<T>) -> Bool {
//    switch lhs {
//    case .Success(let v_left):
//        switch rhs {
//        case .Success(let v_right): return v_left == v_right
//        case .Failure: return false
//        }
//    case .Failure(let e_left):
//        switch rhs {
//        case .Success: return false
//        case .Failure(let e_right): return (e_left as NSError).isEqual(e_right as NSError) // TODO: this looks like a hack!
//        }
//    }
//}
//



