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








// MARK: - Class Future

private let Sync = Synchronize(name: "Future.sync_queue")

internal extension Future {
    internal func sync() -> Synchronize {
        return Sync
    }
}



public protocol FutureBaseType : class {
    

    var isCompleted: Bool { get }
    
    func onCompleteFuture(on ec: ExecutionContext, _ f : (FutureBaseType)->())
    func onCompleteFuture(on ec: ExecutionContext, cancellationToken: CancellationToken, _ f: FutureBaseType -> ())
    func onCompleteFuture(on ec: ExecutionContext, cancellationToken: CancellationToken?, _ f: FutureBaseType -> ())
    
    
    /**
     Blocks the current thread until after Self is completed.
     returns: Self
    */
    func wait() -> Self

    /**
     Blocks the current thread until after Self is completed or a cancellation has
     been requested. Throws a CancellationError.Cancelled error if the cancellation
     token has ben cancelled before Self has been completed.
    
     cancellationToken: A cancellation token where the call-site can request a
                        a cancellation.
     returns: Self if Self has been completed before a cancellation has been requested.
    */
    func wait(cancellationToken: CancellationToken) throws -> Self
    
}


public protocol FutureType : FutureBaseType {
    
    typealias ValueType
    //typealias ResultType = Result<ValueType>
    
    
    /**
    If the future has been completed, returns its Result, ortherwise it
    returns `nil`.
    
    returns: An optional Result
    */
    var result: Result<ValueType>? { get }
    
    func onComplete<U>(on ec: ExecutionContext, cancellationToken: CancellationToken, _ f: Result<ValueType> -> U)
    func onComplete<U>(on ec: ExecutionContext, _ f: Result<ValueType> -> U)
}




/**
    A generic class `Future` which represents an eventual result.
*/


public class Future<T> : FutureType {
    
    public typealias ValueType = T
    //public typealias ResultType = Result<ValueType>
    
    private typealias ContinuationRegistryType = ContinuationRegistry<Result<ValueType>>
    
    private var _result: Result<ValueType>?
    private var _cr : ContinuationRegistryType = ContinuationRegistryType.Empty
    
    
    // MARK: init/deinit
    
    internal init() {
        //Log.Debug("Future created with id: \(self.id).")
    }
    
    internal init(value:T) {
        _result = Result<ValueType>(value)
        //Log.Debug("Fulfilled future created with id: \(self.id) with value \(value).")
    }
    
    internal init(error:ErrorType) {
        _result = Result<ValueType>(error: error)
        //Log.Debug("Rejected future created with id: \(self.id) with error \(error).")
    }
    
    
    deinit {
        //  a future cannot be deinited when there are continuations:
        //assert(case _cr.Empty)
    }

    
    /**
    Returns a unique Id for the future object.
    */
    final var id: UInt {
        return ObjectIdentifier(self).uintValue
    }
    
    // MARK: utility
    
    /**
        Returns true if the future has been completed.
    */
    public final var isCompleted: Bool {
        var result = false
        Sync.read_sync_safe() {
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
    public final var result: Result<ValueType>? {
        var result: Result<ValueType>? = nil
        Sync.read_sync() {
            result = self._result
        }
        return result
    }
    
    public final func get() -> Any? {
        var result: Result<ValueType>? = nil
        Sync.read_sync() {
            result = self._result
        }
        return result
    }
    
    /**
        Blocks the curren thread until self is completed.
        returns: self
    */
    public final func wait() -> Self {
        // wait until completed:
        let sem : dispatch_semaphore_t = dispatch_semaphore_create(0)
        onComplete(on: SynchronousCurrent()) { _ in
            dispatch_semaphore_signal(sem)
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        return self
    }
    

    /**
        Blocks the curren thread until self is completed or if a cancellation
        has been requested.
    
        returns:  True if self is completed, otherwise false.
    */
    public final func wait(cancellationToken: CancellationToken) -> Self {
        // wait until completed or a cancellation has been requested
        let sem : dispatch_semaphore_t = dispatch_semaphore_create(0)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { _ in
            dispatch_semaphore_signal(sem)
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        return self
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
        while true {
            if let r = self.result {
                switch r {
                case .Success(let v): return v
                case .Failure(let e): throw e
                }
            }
            wait()
        }
    }
    
    /**
        Blocks the current thread until after self is completed or a cancellation
        has been requested.
    
        If the future has been completed with success, it returns the `Success`
        value of its result. If the future has been rejected, it throws the
        Failure value of its result. When the cancellation token has been cancelled, 
        it throws an CancellationError.Cancelled error. Note: the cancellation token
        will be checked first.
        
        - parameter cancellationToken: A cancellation token which can be used
        to resume the blocked thread through throwing a CancellationError.Cancelled
        error.
    
        returns:    Returns the value of its result.
    */
    public final func value(cancellationToken: CancellationToken) throws -> T {
        while !cancellationToken.isCancellationRequested {
            if let r = self.result {
                switch r {
                case .Success(let v): return v
                case .Failure(let e): throw e
                }
            }
            wait(cancellationToken)
        }
        throw CancellationError.Cancelled
    }
    
    

    
    // MARK: resolve
    
    /**
        Registers a completion function for the given future `other` which completes
        `self` when `other` completes with the same result. That is, future `other`
         becomes the "resolver" for `self` - iff `self` still exists.
        `self` should not be resolved by another resolver.
        Retains `other` until `self` remains pending.
        Alias for `bind` (aka resolveWith)
    */
    internal final func resolve(other: Future) {
        Sync.write_async() {
            self._resolve(other)
        }
    }
    
    
    /// Completes self with the given result.
    internal final func resolve(result : Result<ValueType>) {
        Sync.write_async {
            self._resolve(result)
        }
    }
    
    
    // Registers a completion function for the given future `other` which
    // completes `self` when other completes with the same result. That is, future 
    // `other` becomes the resolver of `self` - iff `self` still exists. `self` 
    // should not be resolved by another resolver.
    // Retains `other` until `self` remains pending.
    // Alias for bind (aka resolveWith)
    internal final func _resolve(other: Future) {
        assert(Sync.is_synchronized())
        // Note: unless Future is a protocol, we know that onComplete executes its
        // continuations on the Future class's sync_queue. So, we can use SynchronousCurrent()
        // as its execution context which executes on the sync_queue as required
        // for executing _register as an optimization.
        // Otherwise we would have to use SyncExecutionContext(queue: Sync.sync_queue)
        other.onComplete(on:SynchronousCurrent()) { [weak self] otherResult -> () in
            self?._resolve(otherResult);
            return
        }
    }
    
    // Completes `self` with the given result.
    internal final func _resolve(result : Result<ValueType>) {
        assert(Sync.is_synchronized())
        assert(self._result == nil)
        self._result = result
        _cr.run(result)
        _cr = ContinuationRegistryType.Empty
    }
    
    
    // MARK: - Public
    
    /**
        When this future is completed the function `f` will be executed on the
        given execution context with the future's result as its argument.
    
        If this future is not yet completed and if the cancellation token is cancelled
        the function `f` will be "unregistered" and then called with an argument
        `CancellationError.Cancelled` error. Note that the passed argument is NOT 
        the future's result and that the future is not yet completed!
    
        The method retains `self` until it is completed or all continuations have
        been unregistered. If there are no other strong references and all continuations
        have been unregistred, the future will deinit.

        - parameter on: The execution context where the function `f` will be executed.
        - parameter cancellationToken: A cancellation token.
        - parameter f: A function taking the result of the future as its argument.
    */
    public final func onComplete<U>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: Result<ValueType> -> U)
    {
        Sync.write_async {
            if (cancellationToken.isCancellationRequested) {
                ec.execute{
                    f(Result<ValueType>(error: CancellationError.Cancelled))
                }
                return
            }
            if let r = self._result {
                ec.execute {
                    f(r)
                }
            }
            else {
                let id = self._cr.register { result in
                    ec.execute {
                        self
                        f(result)
                    }  // import `self` into the function in order to keep a strong
                    // reference to self until after self will be completed.
                }
                cancellationToken.onCancel(on: GCDAsyncExecutionContext(Sync.sync_queue)) {
                    switch self._cr {
                    case .Empty: break
                    case .Single, .Multiple:
                        let callback = self._cr.unregister(id)
                        assert(callback != nil)
                        ec.execute {
                            callback!.continuation(Result<ValueType>(error: CancellationError.Cancelled))
                        }
                    }
                }
            }
        }
    }

    
    
    /**
        When this future is completed the function `f` will be executed on the
        given execution context with the future's result as its argument.
        
        The method retains `self` until it is completed.
        
        - parameter on: The execution context where the function `f` will be executed.
        - parameter f: A function taking the result of the future as its argument.
    */
    public final func onComplete<U>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        _ f : Result<ValueType> -> U)
    {
        Sync.write_async {
            if let r = self._result {
                ec.execute {
                    f(r)
                }
            }
            else {
                self._cr.register { result in
                    ec.execute {
                        self
                        f(result)
                    } // import `self` into the function in order to keep a strong
                    // reference to self until after self will be completed.
                }
            }
        }
    }
    
    
    public final func onComplete<U>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken?,
        _ f: Result<ValueType> -> U)
    {
        if let ct = cancellationToken {
            onComplete(on: ec, cancellationToken: ct, f)
        }
        else {
            onComplete(on: ec, f)
        }
    }
    

    
    /**
        When this future is completed the function `f` will be executed on the
        given execution context with the future as its argument.
        
        The method retains `self` until it is completed.
        
        - parameter on: The execution context where the function `f` will be executed.
        - parameter f: A function taking the future as its argument.
    */
    public final func onCompleteFuture (
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        _ f : (FutureBaseType) -> ())
    {
        Sync.write_async {
            if let _ = self._result {
                ec.execute {
                    f(self)
                }
            }
            else {
                self._cr.register { _ in
                    ec.execute {
                        f(self)
                    } // import `self` into the function in order to keep a strong
                    // reference to self until after self will be completed.
                }
            }
        }
    }
    
    
    /**
    When this future is completed the function `f` will be executed on the
    given execution context with the future's result as its argument.
    
    If this future is not yet completed and if the cancellation token is cancelled
    the function `f` will be "unregistered" and then called with an argument
    `CancellationError.Cancelled` error. Note that the passed argument is NOT
    the future's result and that the future is not yet completed!
    
    The method retains `self` until it is completed or all continuations have
    been unregistered. If there are no other strong references and all continuations
    have been unregistred, the future will deinit.
    
    - parameter on: The execution context where the function `f` will be executed.
    - parameter cancellationToken: A cancellation token.
    - parameter f: A function taking the result of the future as its argument.
    */
    public final func onCompleteFuture (
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: FutureBaseType -> ())
    {
        Sync.write_async {
            if (cancellationToken.isCancellationRequested) {
                ec.execute{
                    f(self)
                }
                return
            }
            if let _ = self._result {
                ec.execute {
                    f(self)
                }
            }
            else {
                let id = self._cr.register { _ in
                    ec.execute {
                        f(self)
                    }  // import `self` into the function in order to keep a strong
                    // reference to self until after self will be completed.
                }
                cancellationToken.onCancel(on: GCDAsyncExecutionContext(Sync.sync_queue)) {
                    switch self._cr {
                    case .Empty: break
                    case .Single, .Multiple:
                        let callback = self._cr.unregister(id)
                        assert(callback != nil)
                        ec.execute {
                            // Note: the error argument will be ignored in the registered function.
                            callback!.continuation(Result<ValueType>(error: CancellationError.Cancelled))
                        }
                    }
                }
            }
        }
    }
    
    
    public final func onCompleteFuture (
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken?,
        _ f: FutureBaseType -> ())
    {
        if let ct = cancellationToken {
            onCompleteFuture(on: ec, cancellationToken: ct, f)
        }
        else {
            onCompleteFuture(on: ec, f)
        }
    }

    
    
    /**
        Registers the continuation `f` which takes a parameter `value` of type `T` which will
        be executed on the given execution context when `self` has been fulfilled.
        The continuation will be called with a copy of `self`'s result value.
        Retains `self` until it is completed.

        - parameter cancellationToken: A cancellation token which will be monitored.
        - parameter on: The execution context where the function f will be executed.
        - parameter f: A function taking a parameter `value` of type `T`.
    */
    public final func onSuccess(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> ())
    {
        onComplete(on: ec, cancellationToken:cancellationToken) { result in
            if case .Success(let value) = result {
                f(value)
            }
        }
    }
    
    
    
    /**
        Registers the continuation `f` which takes a parameter `value` of type `T` which will be executed
        on a private execution context when `self` has been fulfilled.
        The continuation will be called with a copy of `self`'s result value.
        Retains `self` until it is completed.
        
        - parameter on: The execution context where the function f will be executed.
        - parameter f: A function taking a parameter `value` of type `T`.
    */
    public final func onSuccess(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> ())
    {
        onComplete(on: ec) { result in
            if case .Success(let value) = result {
                f(value)
            }
        }
    }
    
    
    /**
        Registers the continuation `f` which takes a parameter `error` of type `ErrorType` which will be executed
        on the given execution context when `self` has been rejected.
        The continuation will be called with a copy of `self`'s error.
        Retains `self` until it is completed.

        - parameter on: The execution context where the function f will be executed.
        - parameter cancellationToken: A cancellation token which will be monitored.
        - parameter f: A function taking a paramter `error` of type `ErrorType` as parameter.
    */
    public final func onFailure(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: ErrorType -> ())
    {
        onComplete(on: ec, cancellationToken:cancellationToken) { result in
            if case .Failure(let error) = result {
                f(error)
            }
        }
    }
    
    
    /**
        Registers the continuation `f` which takes a parameter `error` of type `ErrorType` which will be executed
        on the given execution context when `self` has been rejected.
        The continuation will be called with a copy of `self`'s error.
        Retains `self` until it is completed.
        
        - parameter on: The execution context where the function f will be executed.
        - parameter f: A function taking a paramter `error` of type `ErrorType` as parameter.
    */
    public final func onFailure(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        _ f: ErrorType -> ())
    {
        onComplete(on: ec) { result in
            if case .Failure(let error) = result {
                f(error)
            }
        }
    }
    
    
    // MARK: map & flatMap
    
    /**
        Returns a new future with the result of the function `f` which is applied
        to the succesful result of this future. If this future has been completed
        with an error, the returned future will be completed with the same error.

        If the cancellation token has been cancelled before the future has been 
        completed, the returned future will completed with a `CancellationError.Cancelled`
        error. Note that this will not complete this future! The function `f` will
        be "unregistered" - that is, it will not be called when the future becomes
        succesfully completed.
        
        When completed successfully, function `f` will be executed on the given
        execution context.
        
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter cancellationToken: A cancellation token which will be monitored.
        - parameter f:  The mapping function `f` which takes a value of type `T`
                        and returns a result of type `Result<U>`.
        - returns:      A new future which will be either completed with `self`'s
                        error or completed with the mapping function's result.
    */
    public final func map<U>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> Result<U>)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    ec.execute { [value] in
                        strongReturnedFuture.resolve(f(value))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error: error))
                }
            }
        }
        return returnedFuture;
    }

    
    /**
        Returns a new future with the result of the function `f` which is applied
        to the succesful result of this future. If this future has been completed
        with an error, the returned future will be completed with the same error.

    
        When completed successfully, function `f` will be executed on the given
        execution context.
    
    
        Retains `self` until it is completed.
        
        - parameter on: An asynchronous execution context.
        - parameter f:  The mapping function `f` which takes a value of type `T`
                        and returns a result of type `Result<U>`.
        - returns:      A new future which will be either completed with `self`'s
                        error or completed with the mapping function's result.
    */
    public final func map<U>(
        on ec: ExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> Result<U>)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    ec.execute { [value] in
                        strongReturnedFuture.resolve(f(value))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error: error))
                }
            }
        }
        return returnedFuture;
    }
    
    
    /**
        Registers the mapping function `f` which takes a value of type `T` and returns
        a *deferred* value of type `U` by means of a `Future<U>`.

        If `self` has been fulfilled with a value the mapping function `f` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with a future `Future<U>` returned from the mapping 
        function `f`.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the samne error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter cancellationToken: A cancellation token which will be monitored.
        - parameter f: A function defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's returned future.
    */
    public final func flatMap<U>(
        on ec: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancellationToken: CancellationToken,
        _ f: T -> Future<U>)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    ec.schedule(strongReturnedFuture) { [value] in
                        strongReturnedFuture.resolve(f(value))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error: error))
                }
            }
        }
        return returnedFuture
    }
    

    /**
        Registers the mapping function `f` which takes a value of type `T` and returns
        a *deferred* value of type `U` by means of a `Future<U>`.
        
        If `self` has been fulfilled with a value the mapping function `f` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with a future `Future<U>` returned from the mapping
        function `f`.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the samne error.
        Retains `self` until it is completed.
        
        - parameter on: An asynchronous execution context.
        - parameter f: A function defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's returned future.
    */
    public final func flatMap<U>(
        on ec: AsyncExecutionContext = GCDAsyncExecutionContext(),
        _ f: T -> Future<U>)
        -> Future<U>
    {
        let returnedFuture = Future<U>()
        onComplete(on: SynchronousCurrent()) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    ec.schedule(strongReturnedFuture) { [value] in
                        strongReturnedFuture.resolve(f(value))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error: error))
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



// MARK: Future Base extension






// MARK: Extension DebugPrintable

extension Future : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var s:String = ""
        Sync.read_sync_safe { /*[unowned(unsafe) self] in */
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

