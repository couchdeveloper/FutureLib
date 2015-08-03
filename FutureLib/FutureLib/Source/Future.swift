//
//  Future.swift
//  FutureLib
//
//  Created by Andreas Grosam on 06.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//

import Dispatch

/// Initialize and configure a Logger - mainly for debugging and testing
#if DEBUG
    private let Log = Logger(category: "Future", verbosity: Logger.Severity.Debug)
#else
    private let Log = Logger(category: "Future", verbosity: Logger.Severity.Error)
#endif




// MARK: - Internal Protocol ResolverType

///**
//    A Resolver is an object whose responsibility is to eventually resolve
//    its associated Resolvable with a result value.
//
//    This protocol is only used internally by the FutureLib.
//*/
//internal protocol ResolverType {
//
//    func unregister<T:Resolvable>(resolvable: T) -> ()
//
//}


// MARK: - Internal Protocol Resolvable

///**
//    A `Resolvable` is an object which is initially created in a "pending" state 
//    and can transition to a "completed" state through "resolving" the resolvable 
//    with a result value (`Result<T>`). The resolvbale can be completed only once, 
//    and can not transition to another state afterward.
//    For a particular Resolvable, there is one and only one resolver at a time.
//
//    This protocol is only used internally by the FutureLib.
//*/
//internal protocol Resolvable {
//    
//    typealias ValueType
//    
//    func resolve(result : Result<ValueType>)
//    
//    var resolver: ResolverType? { get }
//
//}



//extension Future : Resolvable {
//    
//    /// Completes self with the given result.
//    internal final func resolve(result : Result<Future.ValueType>) {
//        sync.write_async {
//            self._resolve(result)
//        }
//    }
// 
//    /// Returns the resolver to which self depends on if any. It may return nil.
//    internal var resolver: ResolverType? { get { return _resolver } }
//    
//}


//extension Future : ResolverType {
//    
//    /// Undo registering the given resolvable.
//    internal final func unregister<T:Resolvable>(resolvable: T) -> () {
////        sync.read_sync_safe {
////            self.unregister(DummyContinuation<Void>())
////        }
//    }
//}




// MARK: - Class Future

private let sync = Synchronize(name: "Future.sync_queue")

/**
    A generic class `Future` which represents an eventual result.
*/
public class Future<T> {
    
    public typealias ValueType = T
    private typealias ContinuationRegistryType = ContinuationRegistry<Result<T>>
    
    private var _result: Result<T>?
    private var _cr : ContinuationRegistryType = ContinuationRegistryType.Empty
    
    
    // MARK: init/deinit
    
    internal init() {
        //Log.Debug("Future created with id: \(self.id).")
    }
    
    internal init(_ value:T) {
        _result = Result<T>(value)
        //Log.Debug("Fulfilled future created with id: \(self.id) with value \(value).")
    }
    
    internal init(_ error:ErrorType) {
        _result = Result<T>(error)
        //Log.Debug("Rejected future created with id: \(self.id) with error \(error).")
    }
    
    
    deinit {
        //  a future cannot be deinited when there are continuations:
        //assert(case _cr.Empty)
    }

    
    // MARK: utility
    
    /**
        Returns a unique Id for the future object.
    */
    internal final var id: UInt {
        return ObjectIdentifier(self).uintValue
    }

    /**
        Returns true if the future has been completed.
    */
    public final var isCompleted: Bool {
        var result = false
        sync.read_sync_safe() {
            result = self._result != nil
        }
        return result
    }

//    public var isSuccess throws:  Bool {
//        if let r = result {
//            switch r {
//                case .Success: return true
//                case .Failure: return false
//            }
//        }
//        else {
//            throw FutureError.NotCompleted
//        }
//    }

//    public var isFailure throws: Bool {
//        if let r = result {
//            switch r {
//            case .Success: return false
//            case .Failure: return true
//            }
//        }
//        else {
//            throw FutureError.NotCompleted
//        }
//    }
    
    
    /**
        If the future has been completed, returns its Result, ortherwise it
        returns `nil`.
    
        returns: An optional Result
    */
    public final var result: Result<T>? {
        var result: Result<T>? = nil
        sync.read_sync() {
            result = self._result
        }
        return result
    }
    

    /**
        Blocks the current thread until after self is completed, then returns the 
        eventual result of the future.
    
        If the future has been completed with success, returns the `Success`
        value of its result. If the future has been rejected, it throws the
        Failure value of its result.
    
        returns:    Returns the value of its result.
    */
    public final func value() throws -> T {
        // wait until completed:
        let sem : dispatch_semaphore_t = dispatch_semaphore_create(0)
        onComplete(on: SynchronousCurrent()) { _ in
            dispatch_semaphore_signal(sem)
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        switch self.result! {
            case .Success(let v): return v
            case .Failure(let e): throw e
        }
    }
    
    /**
        Blocks the current thread until after self is completed or
        if the cancellation token has been cancelled.
    
        If the future has been completed with success, it returns the `Success`
        value of its result. If the future has been rejected, it throws the
        Failure value of its result. When the cancellation token has been cancelled, 
        it throws an CancellationError.Cancelled error.
        
        - parameter cancellationToken: A cancellation token which can be used
        to resume the blocked thread through throwing a CancellationError.Cancelled
        error.
    
        returns:    Returns the value of its result.
    */
    public final func value(cancellationToken: CancellationToken) throws -> T {
        // wait until completed or cancelled:
        let sem : dispatch_semaphore_t = dispatch_semaphore_create(0)
        var r : Result<T>?
        onComplete(on: SynchronousCurrent()) { result in
            r = result
            dispatch_semaphore_signal(sem)
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        switch r! {
            case .Success(let v): return v
            case .Failure(let e): throw e
        }
    }
    
    

    
    // MARK: Private
    
    
    // Completes `self` with the given result.
    internal final func _resolve(result : Result<T>) {
        assert(sync.is_synchronized())
        if self._result == nil {
            self._result = result
            _cr.run(result)
            _cr = ContinuationRegistryType.Empty
        }
        else {
            // TODO: throw FutureError.AlreadyCompleted or fatalError ??
        }
    }

    
    // Registers a completion function for the given future `other` which
    // completes `self` when other completes with the same result. That is, future 
    // `other` becomes the resolver of `self` - iff `self` still exists. `self` 
    // should not be resolved by another resolver.
    // Retains `other` until `self` remains pending.
    // Alias for bind (aka resolveWith)
    internal final func resolve(other: Future) {
        sync.write_async() {
            self._resolve(other)
        }
    }
    
    // Registers a completion function for the given future `other` which
    // completes `self` when other completes with the same result. That is, future 
    // `other` becomes the resolver of `self` - iff `self` still exists. `self` 
    // should not be resolved by another resolver.
    // Retains `other` until `self` remains pending.
    // Alias for bind (aka resolveWith)
    internal final func _resolve(other: Future) {
        assert(sync.is_synchronized())
        // Note: unless Future is a protocol, we know that onComplete executes its
        // continuations on the Future class's sync_queue. So, we can use SynchronousCurrent()
        // as its execution context which executes on the sync_queue as required
        // for executing _register as an optimization.
        // Otherwise we would have to use SyncExecutionContext(queue: sync.sync_queue)
        other.onComplete(on:SynchronousCurrent()) { [weak self] otherResult -> () in
            self?._resolve(otherResult);
            return
        }
    }
    
    /// Completes self with the given result.
    internal final func resolve(result : Result<T>) {
        sync.write_async {
            self._resolve(result)
        }
    }
    
    
    
    
    // MARK: - Public
    
    /**
        Registers the closure `f` - the continuation - which will be executed on 
        the given execution context when it has been completed. 
    
        If the future is not yet completed and if the cancellation token is cancelled 
        the closure `f` will be called with an argument `CancellationError.Cancelled`
        error. Note that the passed argument is NOT the future's result and that
        the future is not yet completed!
    
        If the future is not yet completed and if the cancellation token is not
        cancelled the closure `f` will  be registered.
    
        Otherwise, if the future is already completed, the closure `f` will be called 
        using the given execution context.
    
        If the continuation has been registered and if the future is not yet completed
        while the cancellation token will be cancelled the continuation will be
        _unregistered_ . Unregistering a continuation will immediately call it with 
        an argument `CancellationError.Cancelled` - even though the future is not 
        yet completed.

        The method retains `self` until it is completed or all continuations have
        been unregistered. If there are no other strong references and all continuations
        have been unregistred, the future will deinit.

        - parameter on: The execution context where the closure `f` will be executed.
        - parameter cancellationToken: A cancellation token.
        - parameter f: A closure taking the result of the future as its argument.
    */
    public final func onComplete(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: Result<T> -> ())
    {
        sync.write_sync {
            if (cancellationToken.isCancellationRequested) {
                ec.execute{
                    f(Result<T>(CancellationError.Cancelled))
                }
                return
            }
            if let r = self._result {
                ec.execute {
                    f(r)
                }
            }
            else {
                let id = self._cr.register({ result in
                    ec.execute {
                        self
                        f(result)
                    }  // import `self` into the closure in order to keep a strong
                    // reference to self until after self will be completed.
                })
                cancellationToken.onCancel(on: GCDAsyncExecutionContext(sync.sync_queue)) {
                    switch self._cr {
                    case .Empty: break
                    case .Single, .Multiple:
                        let callback = self._cr.unregister(id)
                        assert(callback != nil)
                        ec.execute {
                            callback!.continuation(Result<T>(CancellationError.Cancelled))
                        }
                    }
                }
            }
        }
    }

    
    /**
        Registers the closure `f` - the continuation - which will be executed on
        the given execution context when it has been completed.
        
        If the future is not yet completed and if the cancellation token is cancelled
        the closure `f` will be called with an argument `CancellationError.Cancelled`
        error. Note that the passed argument is NOT the future's result and that
        the future is not yet completed!
        
        If the future is not yet completed and if the cancellation token is not
        cancelled the closure `f` will  be registered.
        
        Otherwise, if the future is already completed, the closure `f` will be called
        using the given execution context.
        
        If the continuation has been registered and if the future is not yet completed
        while the cancellation token will be cancelled the continuation will be
        _unregistered_ . Unregistering a continuation will immediately call it with
        an argument `CancellationError.Cancelled` - even though the future is not
        yet completed.
        
        The method retains `self` until it is completed or all continuations have
        been unregistered. If there are no other strong references and all continuations
        have been unregistred, the future will deinit.
        
        - parameter on: The execution context where the closure `f` will be executed.
        - parameter f: A closure taking the result of the future as its argument.
    */
    public final func onComplete(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        _ f : (Result<T>)->())
    {
        if let r = _result {
            ec.execute {
                f(r)
            }
        }
        else {
            _cr.register{ result in
                ec.execute {
                    self
                    f(result)
                } // import `self` into the closure in order to keep a strong
                // reference to self until after self will be completed.
            }
        }
    }
    
    
    
    /**
        Registers the continuation `f` which takes a parameter `value` of type `T` which will
        be executed on the given execution context when `self` has been fulfilled.
        The continuation will be called with a copy of `self`'s result value.
        Retains `self` until it is completed.

        - parameter cancellationToken: A cancellation token which will be monitored.
        - parameter on: The execution context where the closure f will be executed.
        - parameter f: A closure taking a parameter `value` of type `T`.
    */
    public final func onSuccess(
        on ec: ExecutionContext  = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> ())
    {
        onComplete(on: SynchronousCurrent(), cancellationToken:cancellationToken) { result in
            switch result {
            case .Success(let value):
                ec.execute { [value] in
                    f(value)
                }
            default:break
            }
        }
    }
    
    
    
    /**
        Registers the continuation `f` which takes a parameter `value` of type `T` which will be executed
        on a private execution context when `self` has been fulfilled.
        The continuation will be called with a copy of `self`'s result value.
        Retains `self` until it is completed.
        
        - parameter on: The execution context where the closure f will be executed.
        - parameter f: A closure taking a parameter `value` of type `T`.
    */
    public final func onSuccess(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> ())
    {
        onComplete(on: SynchronousCurrent()) { result in
            switch result {
            case .Success(let value):
                ec.execute { [value] in
                    f(value)
                }
            default:break
            }
        }
    }
    
    
    /**
        Registers the continuation `f` which takes a parameter `error` of type `ErrorType` which will be executed
        on the given execution context when `self` has been rejected.
        The continuation will be called with a copy of `self`'s error.
        Retains `self` until it is completed.

        - parameter on: The execution context where the closure f will be executed.
        - parameter cancellationToken: A cancellation token which will be monitored.
        - parameter f: A closure taking a paramter `error` of type `ErrorType` as parameter.
    */
    public final func onFailure(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: ErrorType -> ())
    {
        onComplete(on: SynchronousCurrent(), cancellationToken:cancellationToken) { result in
            switch result {
            case .Failure(let error):
                ec.execute {
                    f(error)
                }
            default:break
            }
        }
    }
    
    
    /**
        Registers the continuation `f` which takes a parameter `error` of type `ErrorType` which will be executed
        on the given execution context when `self` has been rejected.
        The continuation will be called with a copy of `self`'s error.
        Retains `self` until it is completed.
        
        - parameter on: The execution context where the closure f will be executed.
        - parameter f: A closure taking a paramter `error` of type `ErrorType` as parameter.
    */
    public final func onFailure(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        _ f: ErrorType -> ())
    {
        onComplete(on: SynchronousCurrent()) { result in
            switch result {
            case .Failure(let error):
                ec.execute {
                    f(error)
                }
            default:break
            }
        }
    }
    
    
    // MARK: map & flatMap
    
    /**
        Registers the mapping function `f` which takes a value of type `T` and returns
        a result of type `Result<R>`.

        If `self` has been fulfilled with a value the mapping function `f` will be executed 
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with the returned value of the mapping function.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the same error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter cancellationToken: A cancellation token which will be monitored.
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's return value.
    */
    public final func map<R>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> Result<R>)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    ec.execute { [value] in
                        strongReturnedFuture.resolve(f(value))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture;
    }

    
    /**
        Registers the mapping function `f` which takes a value of type `T` and returns
        a result of type `Result<R>`.
        
        If `self` has been fulfilled with a value the mapping function `f` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with the returned value of the mapping function.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the same error.
        Retains `self` until it is completed.
        
        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's return value.
    */
    public final func map<R>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> Result<R>)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    ec.execute { [value] in
                        strongReturnedFuture.resolve(f(value))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture;
    }
    
    
    /**
        Registers the mapping function `f` which takes a value of type `T` and returns
        a *deferred* value of type `R` by means of a `Future<R>`.

        If `self` has been fulfilled with a value the mapping function `f` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with a future `Future<R>` returned from the mapping 
        function `f`.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the samne error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter cancellationToken: A cancellation token which will be monitored.
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's returned future.
    */
    public final func flatMap<R>(
        on ec: ExecutionContext,
        cancellationToken: CancellationToken,
        _ f: T -> Future<R>)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    ec.schedule(strongReturnedFuture) { [value] in
                        strongReturnedFuture.resolve(f(value))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture
    }
    

    /**
        Registers the mapping function `f` which takes a value of type `T` and returns
        a *deferred* value of type `R` by means of a `Future<R>`.
        
        If `self` has been fulfilled with a value the mapping function `f` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with a future `Future<R>` returned from the mapping
        function `f`.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the samne error.
        Retains `self` until it is completed.
        
        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's returned future.
    */
    public final func flatMap<R>(
        on ec: ExecutionContext,
        _ f: T -> Future<R>)
        -> Future<R>
    {
        let returnedFuture = Future<R>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    ec.schedule(strongReturnedFuture) { [value] in
                        strongReturnedFuture.resolve(f(value))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture
    }
    
    
    
//    /**
//    Returns a new future which - iff it still exists - will be resolved with
//    the eventual result from self. Thus, self becomes the resolver of the returned
//    future.
//    It's assumed that self is the only resolver of the returned future.
//    
//    Retains `self` until it is completed.
//    
//    - returns: A new future.
//    */
//    public final func proxy() -> Future<T> {
//        // TODO: check if cancellation token should be used
//        let returnedFuture = Future<T>(resolver:self)
//        self.onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result -> () in
//            returnedFuture?.resolve(result)
//            return
//        }
//        return returnedFuture
//    }
    
}






// MARK: Extension DebugPrintable

extension Future : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var s:String = ""
        sync.read_sync_safe { /*[unowned(unsafe) self] in */
            var stateString: String
            if let res = self._result {
                switch res {
                case .Failure(let error): stateString = "rejected with error: \(error)"
                case .Success(let value): stateString = "fulfilled with value: \(value)"
                }
            }
            else {
                stateString = "pending with \(self._cr.count) continuations"
            }
            s = "future<\(T.self)> id: \(self.id) state: \(stateString)"
        }
        return s
    }
    
    
}

