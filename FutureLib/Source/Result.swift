//
//  Result.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



/**
 The generic type `Result` represents the result of a computation which
 either yields a value of type `T` or an error of type `NSError`.
 */
public enum Result<T> {

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
     Creates and initializes a Result with the return value of the given
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
     If `self` is `Success` returns a new result with the throwing mapping function
     `f` applied to the value of `Success`. If `f` throws an error, the new result
     will be initialized with this error. Otherwise, returns a new result with the
     value of `Failure`.

     - parameter f: The maping function.
     - returns: A Result<U>.
     */
    @warn_unused_result
    public func map<U>(@noescape f: T throws -> U) -> Result<U> {
        switch self {
        case .Success(let value):
            return Result<U>({ try f(value) })
        case .Failure(let error):
            return Result<U>(error: error)
        }
    }


    /**
     If `self` is `Success` returns the mapping function `f` applied to the
     value of `Success`. Otherwise, returns a new Result with the value of
     `Failure`.

     - parameter f: The maping function.
     - returns: A Result<U>.
     */
    @warn_unused_result
    public func flatMap<U>(@noescape f: T -> Result<U>) -> Result<U> {
        switch self {
        case .Success(let value):
            return f(value)
        case .Failure(let error):
            return Result<U>(error: error)
        }
    }


    /**
     If `self` is `Success` returns the value of `Success`. Otherwise throws
     the value of `Failure`.

     - returns: `self`'s success value.
     - throws: `self`'s error value.
     */
    public func value() throws -> T {
        switch self {
            case .Success(let value): return value
            case .Failure(let error):
                throw error
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
