//
//  FutureBaseType.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


// MARK: - Protocol FutureBaseType

/**
 A protocol for a Future declaring the basic methods which do not depend on
 the `ValueType` of the future. This protocol can be used in polymorphic containers
 or sequences of futures.
*/
public protocol FutureBaseType : class {

    var isCompleted: Bool { get }
    var isSuccess:   Bool { get }
    var isFailure:   Bool { get }

    /**
     Returns a new future with the result of the mapping function `f` applied to 
     the tuple (`self`, ct). `self` is passed as a `FutureBaseType` and `ct` is
     the cancellation token given in the parameters. If the mapping function 
     throws an error the returned future will be completed with the same error.
     
     If the cancellation token is already cancelled or if it will be cancelled
     before `self` has been completed, the returned future will be completed with
     a `CancellationError.Cancelled` error. Note that cancelling a continuation
     will not complete `self`! Instead the mapping function `f` will be "unregistered"
     and called with a tuple of the pending `self` and the cancelled `ct` as its
     argument. Otherwise, executes the closure `f` on the given execution context
     when `self` is completed passing a tuple of the completed `self` and the
     cancellation token as the argument.
     
     The method retains `self` until it is completed or all continuations have
     been unregistered. If there are no other strong references and all continuations
     have been unregistered, `self` is being deinitialized.
     
     - parameter ec: The execution context where the function `f` will be executed.
     - parameter ct: A cancellation token.
     - parameter f: A closure with signature `FutureBaseType throws -> U` which will be called with `self` as its argument.
     */
    func continueWith<U>(ec ec: ExecutionContext,
        ct: CancellationTokenType,
        f: (FutureBaseType) throws -> U)
        -> Future<U>

    
    /**
     Returns a new future with the deferred result of the mapping function `f` 
     applied to the tuple (`self`, ct). `self` is passed as a `FutureBaseType` 
     and `ct` is the cancellation token given in the parameters.
     
     If the cancellation token is already cancelled or if it will be cancelled
     before `self` has been completed, the returned future will be completed with
     a `CancellationError.Cancelled` error. Note that cancelling a continuation
     will not complete `self`! Instead the mapping function `f` will be "unregistered"
     and called with a tuple of the pending `self` and the cancelled `ct` as its
     argument. Otherwise, executes the closure `f` on the given execution context
     when `self` is completed passing a tuple of the completed `self` and the
     cancellation token as the argument.
     
     The method retains `self` until it is completed or all continuations have
     been unregistered. If there are no other strong references and all continuations
     have been unregistered, `self` is being deinitialized.
     
     - parameter ec: The execution context where the function `f` will be executed.
     - parameter ct: A cancellation token.
     - parameter f: A closure with signature `FutureBaseType -> Future<U>` which will be called with `self` as its argument.
     */
    func continueWith<U>(ec ec: ExecutionContext,
        ct: CancellationTokenType,
        f: (FutureBaseType) -> Future<U>)
        -> Future<U>

    

    /**
     Returns a new future which is completed with the unwrapped return value of the 
     type cast operator `as? S` applied to `self`'s success value. If the cast fails, 
     the returned future will be completed with a `FutureError.InvalidCast` error.
     
     - returns: A new future.
     */
    func mapTo<S>(ct: CancellationTokenType) -> Future<S>
    
    
    
    /**
     Blocks the current thread until after Self is completed.
     returns: Self
    */
    func wait() -> Self

    
    /**
     Blocks the current thread until after Self is completed or a cancellation has
     been requested. Throws a CancellationError.Cancelled error if the cancellation
     token has been cancelled before Self has been completed.

     - parameter cancellationToken: A cancellation token where the call-site can request a
                        a cancellation.
     - returns: Self if Self has been completed before a cancellation has been requested.
    */
    //func wait(cancellationToken: CancellationToken) throws -> Self
    func wait(cancellationToken: CancellationTokenType) -> Self

}


extension FutureBaseType {
    
    public final func continueWith<U>(ec ec: ExecutionContext, f: FutureBaseType throws -> U) -> Future<U> {
        return self.continueWith(ec: ec, ct: CancellationTokenNone(), f: f)
    }
    
    public final func continueWith<U>(f: FutureBaseType throws -> U) -> Future<U> {
        return self.continueWith(ec: ConcurrentAsync(), ct: CancellationTokenNone(), f: f)
    }
    
    public final func continueWith<U>(ct ct: CancellationTokenType, f: (FutureBaseType) throws -> U) -> Future<U> {
        return self.continueWith(ec: ConcurrentAsync(), ct: ct, f: f)
    }

    public final func continueWith<U>(ec ec: ExecutionContext, f: FutureBaseType -> Future<U>) -> Future<U> {
        return self.continueWith(ec: ec, ct: CancellationTokenNone(), f: f)
    }
    
    public final func continueWith<U>(f: FutureBaseType -> Future<U>) -> Future<U> {
        return self.continueWith(ec: ConcurrentAsync(), ct: CancellationTokenNone(), f: f)
    }
    
    public final func continueWith<U>(ct ct: CancellationTokenType, f: (FutureBaseType) -> Future<U>) -> Future<U> {
        return self.continueWith(ec: ConcurrentAsync(), ct: ct, f: f)
    }

    
    
}




