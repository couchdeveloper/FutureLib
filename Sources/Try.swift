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
    associatedtype ValueType

    /**
     Creates and initializes `self` with the given value `v`.

     - parameter v: The value with which `self` will be initialized.
     */
    init(_ v: ValueType)

    /**
     Creates and initializes `self` with the given error `error`.

     - parameter error: The error with which `self` will be initialized.
     */
    init(error: ErrorProtocol)

    /**
     Creates and initializes a `Try` with the return value of the given
     closure. When the closure fails and throws and error, the result will be
     initialized with the error thrown from the closure.

     - parameter f: A closure whose result will initialize `self`.
     */
    init( _ f: @noescape (Void) throws -> ValueType)

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

    /// Represents the success value of `self`.
    case success(ValueType)
    /// Represents the error value of `self`.
    case failure(ErrorProtocol)

    /**
     Creates and initializes `self` with the given value `v`.

     - parameter v: The value with which `self` will be initialized.
     */
    public init(_ v: T) {
        self = success(v)
    }

    /**
     Creates and initializes `self` with the given error `error`.

     - parameter error: The error with which `self` will be initialized.
     */
    public init(error: ErrorProtocol) {
        self = failure(error)
    }

    /**
     Creates and initializes a `Try` with the return value of the given
     closure. When the closure fails and throws an error, the result will be
     initialized with the error thrown from the closure.

     - parameter f: A closure whose result will initialize `self`.
     */
    public init(_ f: @noescape (Void) throws -> T) {
        do {
            self = success(try f())
        } catch let ex {
            self = failure(ex)
        }
    }

    /**
     Creates and initializes a `Try` with the return value of the given
     closure.

     - parameter f: A closure whose result will initialize `self`.
     */
    public init(_ f: @noescape (Void) -> T) {
        self = success(f())
    }


    /**
     - returns: `true` if self is a `Success`, other wise `false`.
    */
    public var isSuccess: Bool {
        if case .success = self { return true } else { return false }
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
        case .success(let value): return value
        case .failure(let error):
            throw error
        }
    }

    
    /**
     If `self` is `Success` returns a new result with the throwing mapping function
     `f` applied to the value of `Success`. If `f` throws an error, the new result
     will be initialized with this error. Otherwise, returns a new result with the
     value of `Failure`.

     - parameter f: The maping function.
     - returns: A `Try<U>`.
     */
    public func map<U>(_ f: @noescape (T) throws -> U) -> Try<U> {
        switch self {
        case .success(let value):
            return Try<U>({ try f(value) })
        case .failure(let error):
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
    public func flatMap<U>(_ f: @noescape (T) -> Try<U>) -> Try<U> {
        switch self {
        case .success(let value):
            return f(value)
        case .failure(let error):
            return Try<U>(error: error)
        }
    }   


    /**
     Applies the given function `f` if this is a `Failure`, otherwise returns `self`
     if this is a `Success`. If the function `f` throws an error, returns a `Try`
     initialized with the same failure value.
     This is like `flatMap` for the failure value.
     
     - parameter f: The function applied to the failure value.     
     - returns: A `Try`.
    */
    public func recoverWith(_ f: @noescape (ErrorProtocol) throws -> Try) -> Try {
        switch self {
        case .success: return self
        case .failure(let error):
            do {
                return try f(error)
            } catch {
                return Try(error: error)
            }
        }
    }
    

    /**
     Applies the given function `f` if this is a `Failure`, otherwise returns `self`
     if this is a `Success`.  If the function `f` throws an error, returns a `Try`
     initialized with the same failure value.
     This is like `map` for the failure value.
     
     - parameter f: The function applied to the failure value.     
     - returns: A `Try`.     
    */
    public func recover(_ f: @noescape (ErrorProtocol) throws -> T) -> Try {
        switch self {
        case .success: return self
        case .failure(let error):
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
        case .success(let value): return .some(value)
        case .failure: return .none
        }
    }

}


extension Try where T: TryType {
    /**
     Transforms a nested `Try`, ie, a `Try` of type `Try<Try<T>>`,
     into an un-nested `Try`, ie, a `Try` of type `Try<T>`.
     
     returns: A value of type `Try`.
     */
    public func flatten() -> T {
        switch self {
        case .success(let value): return value
        case .failure(let error): return T(error: error)
        }
    }

}



/**
 Implements the CustomStringConvertible and CustomDebugStringConvertible protocol.
 */
extension Try: CustomStringConvertible, CustomDebugStringConvertible {

    /// Returns a description of `self`.
    public var description: String {
        switch self {
            case .success(let s): return "Success with \(s)"
            case .failure(let error): return "Failure with \(error)"
        }
    }

    /// Returns a debug description of `self`.
    public var debugDescription: String {
        return self.description
    }
}
