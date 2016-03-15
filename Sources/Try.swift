//
//  Try.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


/**
 Protocol `TryType` defines the interface for concrete generic implementations for
 types representing a `Try`. A _Try_  encapsulates _either_ a value whose type
 equals `ValueType` _or_ an error whose type conforms to `ErrorType`.
*/
public protocol TryType {
    /// The type of the value.
    typealias ValueType
    
    /**
     Creates and initializes `self` with the given value `v`.
     
     - parameter v: The value with which `self` will be initialized.
     */
    init(_ v: ValueType)
    
    /**
     Creates and initializes `self` with the given error `error`.
     
     - parameter error: The error with which `self` will be initialized.
     */
    init(error: ErrorType)
    
    /**
     Creates and initializes a `Try` with the return value of the given
     closure. When the closure fails and throws and error, the result will be
     initialized with the error thrown from the closure.
     
     - parameter f: A closure whose result will initialize `self`.
     */
    init(@noescape _ f: Void throws -> ValueType)
    
    /// - returns: `true` if self is a `Success`, other wise `false`.
    var isSuccess: Bool { get }
    
    /// - returns: `true` if self is a `Failure`, other wise `false`.
    var isFailure: Bool { get }
    
    
    /**
     If `self` is `Success` returns the value of `Success`. Otherwise throws
     the value of `Failure`.
     
     - returns: `self`'s success value.
     - throws: `self`'s error value.
     */
    func get() throws -> ValueType
    
    
    /**
     Converts the Try into an Optional<T>.
     - returns:  `None` if this is a `Failure` or a `Some` containing the value if `self`
     is a `Success`.
     */
    func toOption() -> ValueType?
    
    //func map<U>(@noescape f: ValueType throws -> U) -> TryType<U>
    //func flatMap<U>(@noescape f: ValueType -> TryType<U>) -> TryType<U>
    //func recoverWith(@noescape f: ErrorType throws -> TryType) -> TryType
    //func recover(f: ErrorType throws -> ValueType) -> TryType
}





/**
 The generic type `Try` represents the result of a computation which either 
 yields a value of type `T` or an error value whose type conforms to `ErrorType`.
 */
public enum Try<T>: TryType {

    public typealias ValueType = T

    case Success(ValueType)
    case Failure(ErrorType)

    /**
     Creates and initializes `self` with the given value `v`.

     - parameter v: The value with which `self` will be initialized.
     */
    public init(_ v: T) {
        self = Success(v)
    }

    /**
     Creates and initializes `self` with the given error `error`.

     - parameter error: The error with which `self` will be initialized.
     */
    public init(error: ErrorType) {
        self = Failure(error)
    }

    /**
     Creates and initializes a `Try` with the return value of the given
     closure. When the closure fails and throws and error, the result will be
     initialized with the error thrown from the closure.

     - parameter f: A closure whose result will initialize `self`.
     */
    public init(@noescape _ f: Void throws -> T) {
        do {
            self = Success(try f())
        } catch let ex {
            self = Failure(ex)
        }
    }

    /**
     Creates and initializes a `Try` with the return value of the given
     closure. 
     
     - parameter f: A closure whose result will initialize `self`.
     */
    public init(@noescape _ f: Void -> T) {
        self = Success(f())
    }
    

    /**
     - returns: `true` if self is a `Success`, other wise `false`.
    */
    public var isSuccess: Bool {
        if case .Success = self { return true } else { return false }
    }


    /**
     - returns: `true` if self is a `Failure`, other wise `false`.
     */
    public var isFailure: Bool {
        return !isSuccess
    }

    
    /**
     If `self` is `Success` returns the value of `Success`. Otherwise throws
     the value of `Failure`.
     
     - returns: `self`'s success value.
     - throws: `self`'s error value.
     */
    public func get() throws -> T {
        switch self {
        case .Success(let value): return value
        case .Failure(let error):
            throw error
        }
    }
    
    /**
     If `self` is `Success` returns a new result with the throwing mapping function
     `f` applied to the value of `Success`. If `f` throws an error, the new result
     will be initialized with this error. Otherwise, returns a new result with the
     value of `Failure`.

     - parameter f: The maping function.
     - returns: A Try<U>.
     */
    @warn_unused_result
    public func map<U>(@noescape f: T throws -> U) -> Try<U> {
        switch self {
        case .Success(let value):
            return Try<U>({ try f(value) })
        case .Failure(let error):
            return Try<U>(error: error)
        }
    }


    /**
     If `self` is `Success` returns the mapping function `f` applied to the
     value of `Success`. Otherwise, returns a new `Try` with the value of
     `Failure`.

     - parameter f: The maping function.
     - returns: A `Try<U>`.
     */
    @warn_unused_result
    public func flatMap<U>(@noescape f: T -> Try<U>) -> Try<U> {
        switch self {
        case .Success(let value):
            return f(value)
        case .Failure(let error):
            return Try<U>(error: error)
        }
    }

    
    /**
     Applies the given function `f` if this is a `Failure`, otherwise returns `self`
     if this is a `Success`.
     This is like `flatMap` for the exception.
    */
    public func recoverWith(@noescape f: ErrorType throws -> Try) -> Try {
        switch self {
        case .Success: return self
        case .Failure(let error): 
            do {
                return try f(error)            
            } catch {
                return Try(error: error)
            }
        }
    }
    
    /**
     Applies the given function `f` if this is a `Failure`, otherwise returns `self`
     if this is a `Success`.
     This is like map for the exception.
    */
    public func recover(@noescape f: ErrorType throws -> T) -> Try {
        switch self {
        case .Success: return self
        case .Failure(let error): 
            do {
                return try Try(f(error))
            } catch {
                return Try(error: error)
            }
        }
    }
    

    
    /**
     Converts the Try into an Optional<T>.
     - returns:  `None` if this is a `Failure` or a `Some` containing the value if `self`
     is a `Success`.
     */
    public func toOption() -> T?  {
        switch self {
        case .Success(let value): return .Some(value)
        case .Failure: return .None
        }
    }
    
}


extension Try where T: TryType {
    /**
     Transforms a nested `Try`, ie, a `Try` of type `Try<Try<T>>`,
     into an un-nested `Try`, ie, a `Try` of type `Try<T>`.
     */
    public func flatten() -> T {
        switch self {
        case .Success(let value): return value
        case .Failure(let error): return T(error: error)
        }
    }
    
}



/**
 Implements the CustomStringConvertible and CustomDebugStringConvertible protocol.
 */
extension Try : CustomStringConvertible, CustomDebugStringConvertible {
    
    /// Returns a description of `self`.
    public var description: String {
        switch self {
            case .Success(let s): return "Success with \(s)"
            case .Failure(let error): return "Failure with \(error)"
        }
    }

    /// Returns a debug description of `self`.
    public var debugDescription: String {
        return self.description
    }
}
