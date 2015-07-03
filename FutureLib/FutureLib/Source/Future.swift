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



///** 
//    FutureError encapsulates a few kinds of errors which will be
//    thrown by a Future if an exceptional error occurs.
//*/
//public enum FutureError : ErrorType {
//    case NotCompleted
//    case AlreadyCompleted
//    case Rejected(error: ErrorType)
//}



/**
    A private concrete implementation of the protocol `ExecutionContext` which 
    _synchronously_ executes a given closures on the _current_ execution context.
    This class is used internally by FutureLib.
*/
private struct SynchronousCurrent : ExecutionContext, SynchronousTrait {
    
    /**
        Synchronuosly executes the given closure `f` on its execution context.

        - parameter f: The closure takeing no parameters and returning ().
    */
    private func execute(f:()->()) {
        f()
    }
}



// MARK: - Internal Protocol Resolver

/**
    A Resolver is an object whose responsibility is to eventually resolve
    its associated Resolvable with a result value.

    This protocol is only used internally by the FutureLib.
*/
internal protocol Resolver {

    func unregister<T:Resolvable>(resolvable: T) -> ()

}


// MARK: - Internal Protocol Resolvable

/**
    A `Resolvable` is an object which is initially created in a "pending" state 
    and can transition to a "completed" state through "resolving" the resolvable 
    with a result value (`Result<T>`). The resolvbale can be completed only once, 
    and can not transition to another state afterward.
    For a particular Resolvable, there is one and only one resolver at a time.

    This protocol is only used internally by the FutureLib.
*/
internal protocol Resolvable {
    
    typealias ValueType
    
    func resolve(result : Result<ValueType>)
    
    var resolver: Resolver? { get }

}



extension Future : Resolvable {
    
    /// Completes self with the given result.
    final internal func resolve(result : Result<Future.ValueType>) {
        sync.write_async {
            self._resolve(result)
        }
    }
 
    /// Returns the resolver to which self depends on if any. It may return nil.
    internal var resolver: Resolver? { get { return _resolver } }
    
}


extension Future : Resolver {
    
    /// Undo registering the given resolvable.
    final internal func unregister<T:Resolvable>(resolvable: T) -> () {
        sync.read_sync_safe() {
            self.unregister(DummyRegisterable())
        }
    }
}




// MARK: - Class Future

private let sync = Synchronize(name: "Future.sync_queue")

/**
    A generic class `Future` which represents an eventual result.
*/
public class Future<T> {
    
    public typealias ValueType = T
    
    private var _result: Result<T>?
    private var _handler_queue: dispatch_queue_t?
    private var _register_count = 0
    private var _resolver : Resolver?
    
    
    // MARK: init/deinit
    
    internal init(resolver: Resolver? = nil) {
        _resolver = resolver
        //Log.Debug("Future created with id: \(self.id).")
    }
    
    internal init(_ value:T, resolver: Resolver? = nil) {
        _resolver = resolver
        _result = Result<T>(value)
        //Log.Debug("Fulfilled future created with id: \(self.id) with value \(value).")
    }
    
    internal init(_ error:ErrorType, resolver: Resolver? = nil) {
        _resolver = resolver
        _result = Result<T>(error)
        //Log.Debug("Rejected future created with id: \(self.id) with error \(error).")
    }
    
    
    deinit {
        if let handlerQueue = self._handler_queue {
            if (self._result == nil) {
                Log.Warning("Future not yet completed while resuming continuations: unregistering continuatuations...")
            }
            dispatch_resume(handlerQueue)
        }
    }

    
    // MARK: utility
    
    /**
        Returns a unique Id for the future object.
    */
    internal final var id: UInt {
        return reflect(self).objectIdentifier!.uintValue
    }

    /**
        Returns true if the future has been completed.
    */
    public final var isCompleted: Bool {
        var result = false
        sync.read_sync() {
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
        If the future has been completed with success, returns the `Success` 
        value of its result. If the future has been rejected, it throws a 
        `FutureError.Rejected` error with the `Failure` value of its result. 
        
        Otherwise:  Blocks the current thread until after self is completed.
    
        returns:    Returns the value of its result.
    */
    public final func value() throws -> T {
        // wait until completed:
        let sem : dispatch_semaphore_t = dispatch_semaphore_create(0)
        sync.write_sync {
            if let _ = self._result  { // self already resolved
                dispatch_semaphore_signal(sem)
            } else { // self still pending
                self.register(nil) {
                    dispatch_semaphore_signal(sem)
                }
            }
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        switch self.result! {
            case .Success(let v): return v
            case .Failure(let e): throw e
        }
    }
    
    
    

    
    // MARK: Private
    
    
    // Completes `self` with the given result.
    private final func _resolve(result : Result<T>) {
        assert(sync.is_synchronized())
        if self._result == nil {
            self._result = result
            resume()
        }
        else {
            // TODO: throw FutureError.AlreadyCompleted or fatalError ??
        }
        self._resolver = nil;
    }
    
    // Registers a completion function for the given future `other` which
    // completes `self` with the same result. That is, future `other` becomes
    // the resolver of `self` - iff `self` still exists. `self` should not be
    // resolved by another resolver.
    // Retains `other` until `self` remains pending.
    // Alias for bind (aka resolveWith)
    private final func resolve(other: Future) {
        sync.write_async() {
            self._resolve(other)
        }
    }
    
    // Registers a completion function for the given future `other` which
    // completes `self` with the same result. That is, future `other` becomes
    // the resolver of `self` - iff `self` still exists. `self` should not be
    // resolved by another resolver.
    // Retains `other` until `self` remains pending.
    // Alias for bind (aka resolveWith)
    private final func _resolve(other: Future) {
        assert(sync.is_synchronized())
        self._resolver = other;
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
    
    
    // MARK: - Public
    
    /**
        Registers the closure `f` - the continuation - which will be executed on 
        the given execution context when it has been completed. 
    
        If the cancellation token is already cancelled the method returns without
        registering and without calling the closure `f`. Otherwise, if the future
        is already completed, the closure `f` will be called using the given execution
        context. Otherwise, the closure `f` will be registered and it will be 
        called on the given execution context when the future becomes completed.
    
        If the future is not yet completed and the cancellation token will be cancelled 
        it _unregisters_ the continuation. Unregistering a continuation will prevent 
        it to be called when the future will be completed.
        There's no guarantee, though, that captured references will be immediately 
        released when the continuation will be unregistered. Captured references
        may be kept until after the future will be completed.

        The method retains `self` until it is completed or all continuations have
        been unregistered. If there are no other strong references and all continuations
        have been unregistred, the future will deinit.

        - parameter executor: The execution context where the closure `f` will be executed.
        - parameter cancellationToken: An optional cancellation token.
        - parameter f: A closure taking the result of the future as its argument.
    */
    public final func onComplete(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, f: Result<T> -> ())-> () {
        if let ct = cancellationToken {
            if ct.isCancellationRequested {
                return
            }
        }
        let wrapperFunc : ()->() = {
            if let r = self._result  {
                executor.execute { [r] in
                    f(r)
                }
            }
        }
        sync.write_sync {
            if self._result == nil  { // self still pending
                self.register(cancellationToken, f: wrapperFunc)
            } else { // self already resolved
                wrapperFunc()
            }
        }
    }
    
    /**
    Registers the closure `f` - the continuation - which will be executed on
    a private execution context when it has been completed.
    
    If the cancellation token is already cancelled the method returns without
    registering and without calling the closure `f`. Otherwise, if the future
    is already completed, the closure `f` will be called on a private execution
    context. Otherwise, the closure `f` will be registered and it will be
    called on a private execution context when the future becomes completed.
    
    If the future is not yet completed and the cancellation token will be cancelled
    it _unregisters_ the continuation. Unregistering a continuation will prevent
    it to be called when the future will be completed.
    There's no guarantee, though, that captured references will be immediately
    released when the continuation will be unregistered. Captured references
    may be kept until after the future will be completed.
    
    The method retains `self` until it is completed or all continuations have
    been unregistered. If there are no other strong references and all continuations
    have been unregistred, the future will deinit.
    
    - parameter cancellationToken: An optional cancellation token.
    - parameter f: A closure taking the result of the future as its argument.
    */
    public final func onComplete(cancellationToken: CancellationTokenProtocol? = nil, f: Result<T> -> ())-> () {
        onComplete(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f: f)
    }
    
    
    
    /**
        Registers the continuation `f` which takes a parameter `value` of type `T` which will
        be executed on the given execution context when `self` has been fulfilled.
        The continuation will be called with a copy of `self`'s result value.
        Retains `self` until it is completed.

        - parameter executor: The execution context where the closure f will be executed.
        - parameter f: A closure taking a parameter `value` of type `T`.
    */
    public final func onSuccess(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> ())-> () {
        onComplete(on: SynchronousCurrent(), cancellationToken:cancellationToken) { result in
            switch result {
            case .Success(let value):
                executor.execute() { [value] in
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

        - parameter executor: The execution context where the closure f will be executed.
        - parameter f: A closure taking a parameter `value` of type `T`.
    */
    public final func onSuccess(cancellationToken: CancellationTokenProtocol? = nil,  _ f: T -> ())-> () {
        onSuccess(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken:cancellationToken, f)
    }
    
    
    /**
        Registers the continuation `f` which takes a parameter `error` of type `ErrorType` which will be executed
        on the given execution context when `self` has been rejected.
        The continuation will be called with a copy of `self`'s error.
        Retains `self` until it is completed.

        - parameter executor: The execution context where the closure f will be executed.
        - parameter f: A closure taking a paramter `error` of type `ErrorType` as parameter.
    */
    public final func onFailure(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> ())-> () {
        onComplete(on: SynchronousCurrent(), cancellationToken:cancellationToken) { result in
            switch result {
            case .Failure(let error):
                executor.execute() {
                    f(error)
                }
            default:break
            }
        }
    }
    
    /**
        Registers the continuation `f` which takes a parameter `error` of type `ErrorType` which will be executed
        on a private execution context when `self` has been rejected.
        The continuation will be called with a copy of `self`'s error.
        Retains `self` until it is completed.

        - parameter f: A closure taking a paramter `error` of type `ErrorType` as parameter.
    */
    public final func onFailure(cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> ())-> () {
        onFailure(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken:cancellationToken, f)
    }
    
    
//    // Cancellation
//    
//    /**
//        Registers the continuation `f` with a parameter `error` which will be executed on the
//        given execution context when `self` has been cancelled.
//
//        Self will transition to the `Cancelled` state only
//        1. if it has an associated cancellation token which has been cancelled
//        2. if it is still pending and
//        3. if it has no continuations or all continuations have been cancelled.
//        The continuation will be called with a copy of `self`'s error.
//        Retains `self` until it is completed.
//
//        - parameter executor: The execution context where the closure f will be executed.
//        - parameter f: A closure taking an error as parameter.
//    */
//    internal final func onCancel(on executor: ExecutionContext, _ f: ErrorType -> ())-> () {
//        onComplete(on: SynchronousCurrent()) { result in
//            switch result {
//            case .Failure(let error) where error is CancellationError:
//                if (error is CancellationError) {
//                    executor.execute() {
//                        f(error)
//                    }
//                }
//            default:break
//            }
//        }
//    }

//    /**
//        Registers the continuation `f` with a parameter `error` which will be executed on a
//        private execution context when `self` has been cancelled. 
//
//        Self will transition to the `Cancelled` state only
//        1. if it has an associated cancellation token which has been cancelled
//        1. if it is still pending and
//        1. if it has no continuations or all continuations have been cancelled.
//        The continuation will be called with a copy of `self`'s error.
//        Retains `self` until it is completed.
//
//        - parameter f: A closure taking an error as parameter.
//    */
//    internal final func onCancel(f: ErrorType -> ())-> () {
//        onCancel(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
//    }

    
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
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's return value.
    */
    public final func map<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> Result<R>) -> Future<R> {
        let returnedFuture = Future<R>(resolver:self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    executor.execute() { [value] in
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
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's returned future.
    */
    public final func flatMap<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> Future<R>) -> Future<R> {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    executor.execute() { [value] in
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
    


    // MARK: then
    
    /**
        Registers a continuation with a success handler `onSuccess` which takes a value
        of type `T` and an error handler `onError` which takes an error of type `ErrorType`
        Both handlers return a result of type `Result<R>`.

        If `self` has been fulfilled with a value the success handler `onSuccess` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with the result of the success handler function.
        Otherwise, when `self` has been rejected with an error, the error handler `onError` will
        be executed on the given execution context with this error. The returned future (if it
        still exists) will be resolved with the result of the error handler function.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func then<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil,
            onSuccess: T -> Result<R>,
            onError: ErrorType -> Result<R>)
    -> Future<R>
    {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                let r: Result<R>
                switch result {
                case .Success(let value):
                    r = onSuccess(value)
                case .Failure(let error):
                    r = onError(error)
                }
                strongReturnedFuture.resolve(r)
            }
        }
        return returnedFuture
    }
    
    
    /**
        Registers the continuation `f` which takes a parameter `value` of type `T` which will
        be executed on the given execution context when `self` has been fulfilled.
        The continuation will be called with a copy of `self`'s result value.
        Retains `self` until it is completed.

        Alias: `func onSuccess(executor: ExecutionContext, _ f: T -> ())`

        - parameter on: The execution context where the closure f will be executed.
        - parameter f: A closure taking a parameter `value` of type `T`.
    */
    public final func then(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> ()) -> () {
        onSuccess(on: executor, cancellationToken:cancellationToken, f)
    }
    


    /**
        Registers the continuation `f` which takes a value of type `T` and returns
        a value of type `R`.

        If `self` has been fulfilled with a value the continuation `f` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be fulfilled with the returned value of the continuation function.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the same error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func then<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> R) -> Future<R> {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    executor.execute() { [value] in
                        strongReturnedFuture.resolve(Result(f(value)))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture
    }

    /**
        Registers the continuation `f` which takes a value of type `T` and returns
        an error of type `ErrorType`.

        If `self` has been fulfilled with a value the continuation `f` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be rejected with the returned error of the continuation function.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the same error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func then(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> ErrorType) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    executor.execute() { [value] in
                        strongReturnedFuture.resolve(Result(f(value)))
                    }
                case .Failure(let error):
                    strongReturnedFuture._resolve(Result(error))
                }
            }
        }
        return returnedFuture
    }

    /**
        Registers the continuation `f` which takes a value of type `T` and returns
        a result of type `Result<R>`.

        If `self` has been fulfilled with a value the continuation function `f` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with the returned result of the continuation function.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the same error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned result.
    */
    public final func then<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> Result<R>) -> Future<R> {
        return map(on: executor, cancellationToken: cancellationToken, f)
    }

    /**
        Registers the continuation function `f` which takes a value of type `T` and returns
        a *deferred* value of type `R` by means of a `Future<R>`.

        If `self` has been fulfilled with a value the continuation function `f` will be executed
        on the given execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with a future `Future<R>` returned from the continuation
        function `f`.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the samne error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned future.
    */
    public final func then<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> Future<R>) -> Future<R> {
        return flatMap(on: executor, cancellationToken: cancellationToken, f);
    }
    
    /**
        Registers the continuation `f` which takes a parameter `value` of type `T` which will
        be executed on a private execution context when `self` has been fulfilled.
        The continuation will be called with a copy of `self`'s result value.
        Retains `self` until it is completed.

        Alias: `func onSuccess(f: T -> ())`

        - parameter on: The execution context where the closure f will be executed.
        - parameter f: A closure taking a parameter `value` of type `T`.
    */
    public final func then(cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> ()) -> () {
        then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }

    /**
        Registers the continuation `f` which takes a value of type `T` and returns
        a value of type `R`.

        If `self` has been fulfilled with a value the continuation `f` will be executed
        on a private execution context with a copy of the value. The returned future (if it
        still exists) will be fulfilled with the returned value of the continuation function.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the same error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func then<R>(cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> R) -> Future<R> {
        return then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }

    /**
        Registers the continuation `f` which takes a value of type `T` and returns
        an error of type `ErrorType`.

        If `self` has been fulfilled with a value the continuation `f` will be executed
        on a private execution context with a copy of the value. The returned future (if it
        still exists) will be rejected with the returned error of the continuation function.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the same error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func then(cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> ErrorType) -> Future<T> {
        return then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }

    /**
        Registers the continuation `f` which takes a value of type `T` and returns
        a result of type `Result<R>`.

        If `self` has been fulfilled with a value the continuation function `f` will be executed
        on a private execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with the returned result of the continuation function.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the same error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned result.
    */
    public final func then<R>(cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> Result<R>) -> Future<R> {
        return then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }

    /**
        Registers the continuation function `f` which takes a value of type `T` and returns
        a *deferred* value of type `R` by means of a `Future<R>`.

        If `self` has been fulfilled with a value the continuation function `f` will be executed
        on a private execution context with a copy of the value. The returned future (if it
        still exists) will be resolved with a future `Future<R>` returned from the continuation
        function `f`.
        Otherwise, when `self` has been completed with an error, the returned future (if it
        still exists) will be rejected with the samne error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned future.
    */
    public final func then<R>(cancellationToken: CancellationTokenProtocol? = nil, _ f: T -> Future<R>) -> Future<R> {
        return then(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    


    // MARK: catch
    
    
    /**
        Registers the continuation `f` which takes an error of type `ErrorType`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on the given execution context with this error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
    */
    public final func `catch`(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> ()) -> () {
        onFailure(on: executor, cancellationToken: cancellationToken) {
            f($0)
        }
    }

//   /**
//      Registers the continuation `f` which takes an error of type `ErrorType` and returns
//      a value of type `U` (either a value of type T, a Result<T>, a Future<T> or an ErrorType).
//
//      If `self` has been rejected with an error the continuation `f` will be executed
//      on the given execution context with this error. The returned future (if it still
//      exists) will be fulfilled with the returned value of the continuation function.
//      Otherwise, when `self` has been completed with success, the returned future (if it
//      still exists) will be fullfilled with the same value.
//      Retains `self` until it is completed.
//    
//      :param: on An asynchronous execution context.
//      :param: f A closure defining the continuation.
//      :returns: A future.
//    */
//    public final func catch<U>(on executor: ExecutionContext, _ f: ErrorType -> U) -> Future<T> {
//        let returnedFuture = Future<T>()
//        onComplete(executor) { [weak returnedFuture] future -> () in
//            switch future._result! {
//            case .Success(let value):
//                returnedFuture?.resolve(value[0])
//            case .Failure(let error):
//                returnedFuture?.resolve(f(error))
//            }
//        }
//        return returnedFuture
//    }
    
    
    /**
        Registers the continuation `f` which takes an error of type `ErrorType` and returns
        a value of type `T`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on the given execution context with this error. The returned future (if it still
        exists) will be fulfilled with the returned value of the continuation function.
        Otherwise, when `self` has been completed with success, the returned future (if it
        still exists) will be fullfilled with the same value.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func `catch`(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> T) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result -> () in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute() {
                        strongReturnedFuture.resolve(Result(f(error)))
                    }
                }
            }
        }
        return returnedFuture
    }
    
    /**
        Registers the continuation `f` which takes an error of type `ErrorType` and returns
        a result of type `Result<T>`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on the given execution context with this error. The returned future (if it still
        exists) will be fulfilled with the returned result of the continuation function.
        Otherwise, when `self` has been completed with success, the returned future (if it
        still exists) will be fullfilled with the same value.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func `catch`(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> Result<T>) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute() {
                        strongReturnedFuture.resolve(f(error))
                    }
                }
            }
        }
        return returnedFuture
    }
    
    /**
        Registers the continuation `f` which takes an error of type `ErrorType` and returns
        an error type `ErrorType`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on the given execution context with this error. The returned future (if it still
        exists) will be rejected with the returned error of the continuation function.
        Otherwise, when `self` has been completed with success, the returned future (if it
        still exists) will be fullfilled with the same value.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func `catch`(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> ErrorType) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute() {
                        strongReturnedFuture.resolve(Result(f(error)))
                    }
                }
            }
        }
        return returnedFuture
    }
    
    /**
        Registers the continuation `f` which takes an error of type `ErrorType` and returns
        a defered value by means of a future of type `future<T>`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on the given execution context with this error. The returned future (if it still
        exists) will be resolved with the returned future of the continuation function.
        Otherwise, when `self` has been completed with success, the returned future (if it
        still exists) will be fullfilled with the same value.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func `catch`(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> Future<T>) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] result in
            if let strongReturnedFuture = returnedFuture {
                switch result {
                case .Success(let value):
                    strongReturnedFuture._resolve(Result(value))
                case .Failure(let error):
                    executor.execute() {
                        strongReturnedFuture.resolve(f(error))
                    }
                }
            }
        }
        return returnedFuture
    }
    
    /**
        Registers the continuation `f` which takes an error of type `ErrorType`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on a private execution context with this error.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
    */
    public final func `catch`(cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> ()) -> () {
        `catch`(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken:cancellationToken, f)
    }

    
    /**
        Registers the continuation `f` which takes an error of type `ErrorType` and returns
        a value of type `T`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on a private execution context with this error. The returned future (if it still
        exists) will be fulfilled with the returned value of the continuation function.
        Otherwise, when `self` has been completed with success, the returned future (if it
        still exists) will be fullfilled with the same value.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func `catch`(cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> T) -> Future {
        return `catch`(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken: cancellationToken, f)
    }

    
    /**
        Registers the continuation `f` which takes an error of type `ErrorType` and returns
        a value of type `T`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on a private execution context with a this error. The returned future (if it
        still exists) will be fulfilled with the returned value of the continuation function.
        Otherwise, when `self` has been completed with success, the returned future (if it
        still exists) will be fullfilled with the same value.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func `catch`(cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> Result<T>) -> Future {
        return `catch`(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken:cancellationToken, f)
    }
    
    
    /**
        Registers the continuation `f` which takes an error of type `ErrorType` and returns
        a value of type `T`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on a private execution context with a this error. The returned future (if it
        still exists) will be fulfilled with the returned value of the continuation function.
        Otherwise, when `self` has been completed with success, the returned future (if it
        still exists) will be fullfilled with the same value.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func `catch`(cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> ErrorType) -> Future<T> {
        return `catch`(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken: cancellationToken, f)
    }

    /**
        Registers the continuation `f` which takes an error of type `ErrorType` and returns
        a value of type `T`.

        If `self` has been rejected with an error the continuation `f` will be executed
        on a private execution context with a this error. The returned future (if it
        still exists) will be fulfilled with the returned value of the continuation function.
        Otherwise, when `self` has been completed with success, the returned future (if it
        still exists) will be fullfilled with the same value.
        Retains `self` until it is completed.

        - parameter on: An asynchronous execution context.
        - parameter f: A closure defining the continuation.
        - returns: A future.
    */
    public final func `catch`(cancellationToken: CancellationTokenProtocol? = nil, _ f: ErrorType -> Future<T>) -> Future<T> {
        return `catch`(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken:cancellationToken, f)
    }
    
    
    // MARK: - finally
    
    public final func finally(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> ()) {
        onComplete(on: executor, cancellationToken:cancellationToken) { _ -> () in
            f()
        }
    }
    public final func finally<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> R) -> Future<R> {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            let r = f()
            returnedFuture?.resolve(Result(r))
        }
        return returnedFuture
    }
    public final func finally<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> Result<R>) -> Future<R> {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            let r = f()
            returnedFuture?.resolve(r)
        }
        return returnedFuture
    }
    public final func finally(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> ErrorType) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _  in
            let r = f()
            returnedFuture?.resolve(Result(r))
        }
        return returnedFuture
    }
    public final func finally<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> Future<R>) -> Future<R>  {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _ -> () in
            let future = f()
            returnedFuture?.resolve(future)
        }
        return returnedFuture
    }
    
    public final func finally(cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> ()) -> () {
        finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    public final func finally<R>(cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> R) -> Future<R> {
        return finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    public final func finally<R>(cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> Result<R>) -> Future<R> {
        return finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    public final func finally(cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> ErrorType) -> Future {
        return finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    public final func finally<R>(cancellationToken: CancellationTokenProtocol? = nil, _ f: () -> Future<R>) -> Future<R> {
        return finally(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    
}


// MARK: CallbackHandlerType

internal protocol Registerable { }

private struct DummyRegisterable : Registerable {}


private protocol CallbackHandlerType {
    
    mutating func resume()
    
    mutating func register(f: ()->()) -> Registerable
    
    mutating func unregister(registerable: Registerable)
}



private struct Callback : Registerable {
    let _f : ()->()
    init(_ f:()->()) {
        _f = f
    }
    func execute() {
        _f()
    }
}




/**
    Implements the continuation handler mechanism.

    This extension accesses the member variable _handler_queue.
*/
extension Future : CallbackHandlerType {

    // Execute the registered continuations - if any.
    private final func resume() {
        assert(sync.is_synchronized())
        if let handlerQueue = self._handler_queue {
            if (self._result == nil) {
                Log.Warning("Future not yet completed while resuming continuations: unregistering continuatuations...")
            }
            dispatch_resume(handlerQueue)
            self._handler_queue = nil
        }
    }
    
    
    // Registers the closure `f` which will be executed when the future becomes
    // completed. If the cancellation token's property `isCancellationRequested`
    // returns `true` the execution of the closure will be skipped. Release of any
    // resources associated with the closure will be delayed until execution
    // of the closure is next attempted (or any execution already in progress
    // completes).
    //
    // Retains the cancellation token until after the future has been completed.
    private final func register(cancellationToken: CancellationTokenProtocol? = nil, f: ()->()) {
        if let ct = cancellationToken {
            let registerToken = register({
                if !ct.isCancellationRequested {
                    f()
                }
            })
            // Note: private function `self.unregister()` requires to be called
            // on self's sync_queue with exclusive write access.
            // Thus, we cannot use SynchronousCurrent() as the execution context
            // for the CancellationToken's continuation which executes unregister,
            // since we do not know which execution context onCancel executes
            // its continuations.
            // We cannot use SyncExecutionContext(queue: sync.sync_queue) as the
            // execution context because this may cause a dead-lock.
            // We cannot use AsyncExecutionContext(queue: sync.sync_queue) as the
            // execution context because `unregister`requires exclusive write access.
            // We need to use `BarrierAsyncExecutionContext` with the sync_queue.
            ct.onCancel(on: BarrierAsyncExecutionContext(queue: sync.sync_queue)) { [weak self] in
                if let this = self {
                    this.unregister(registerToken)
                }
            }
        }
        else {
            register(f)
        }
    }
    
    
    private final func register(f: ()->()) -> Registerable {
        assert(sync.is_synchronized())
        assert(self._result == nil)
        if (_handler_queue == nil) {
            Log.Trace("creating handler queue")
            // The handler queue's target queue will become the sync-queue. This
            // ensures that code executing on the handler queue is synchronized
            // with code executing on the sync-queue.
            _handler_queue = dispatch_queue_create("Future.handler_queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0))!
            dispatch_set_target_queue(_handler_queue, sync.sync_queue)
            dispatch_suspend(_handler_queue!)
        }
        ++_register_count
        dispatch_async(_handler_queue!, f)
        return DummyRegisterable()
    }
    
    
    // Decrements `_register_count` and if it becomes zero self clears its
    // handler queue, which releases any imported references including `self`,
    // and thus *may* release the last strong reference to itself.
    // `unregister` must execute on the sync queue with exclusive write access.
    // `self` must not be completed.
    private final func unregister(registerable: Registerable) {
        assert(sync.is_synchronized())
        if (--_register_count == 0) {
            // When all continuaitons are cancelled, we can clear the handler queue:
            if let handlerQueue = self._handler_queue {
                Log.Trace("clearing handler queue")
                dispatch_resume(handlerQueue)
                self._handler_queue = nil
            }
        }
    }

}






// MARK: Extension CancellationToken API

extension Future {


//    /// Registers the continuation `f` which takes a parameter `result` which will be executed on the
//    /// given execution context when it has been completed (either fulfilled or rejected).
//    /// The continuation will be called with a copy of `self`'s result.
//    /// Retains `self` until it is completed.
//    ///
//    /// - parameter executor: The execution context where the closure `f` will be executed.
//    /// - parameter f: A closure taking a `Result<T>` as parameter.
//    public final func onComplete(executor: ExecutionContext, cancellationToken: CancellationTokenProtocol?, f: Future<T> -> ())-> () {
//        sync.write_async {
//            if self._result != nil  { // self already resolved
//                // TODO: What if cancellationToken.isCancellationRequested returns true?
//                // We cannot set self to "cancelled" - it's already completed.
//                // Possibly create a Result<T> with a CancellationError and pass this result to the excutor?, e.g.:
//                // executor.execute(cancellationToken) { f(Result<T>(CancellationError())) }
//                // Or, follow the rule that a future which is completed cannot be cancelled, and simply ignore
//                // the cancellation token:
//                
//                // If the future is already completed, the state of the cancellation token is ignored:
//                executor.execute() {
//                    f(self)
//                }
//            }
//            else { // self still pending
//                self._register(cancellationToken) {
//                    assert(sync.is_synchronized())
//                    executor.execute() {
//                        f(self)
//                    }
//                }
//                if let ct = cancellationToken {
//                    ct.onCancel(on: SynchronousCurrent()) { [weak self] in
//                        if let this = self, resolver = this._resolver {
//                            resolver.unregister(this)
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    
    
    /// Registers the mapping function `f` which takes a value of type `T` and returns
    /// a result of type `Result<R>`.
    ///
    /// If `self` has been fulfilled with a value the mapping function `f` will be executed
    /// on the given execution context with a copy of the value. The returned future (if it
    /// still exists) will be resolved with the returned value of the mapping function.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the same error.
    /// Retains `self` until it is completed.
    ///
    /// - parameter on: An asynchronous execution context.
    /// - parameter f: A closure defining the continuation.
    /// - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's return value.
    public func map<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol, _ f: T -> Result<R>) -> Future<R> {
        cancellationToken.onCancel() { [weak self] in
            if let this = self, resolver = this._resolver {
                resolver.unregister(this)
            }
        }
        return self.map(on: executor, f)
    }
    
    
    
    
    
    
    
    /// Registers the mapping function `f` which takes a value of type `T` and returns
    /// a *deferred* value of type `R` by means of a `Future<R>`.
    ///
    /// If `self` has been fulfilled with a value the mapping function `f` will be executed
    /// on the given execution context with a copy of the value. The returned future (if it
    /// still exists) will be resolved with a future `Future<R>` returned from the mapping
    /// function `f`.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the samne error.
    /// Retains `self` until it is completed.
    ///
    /// - parameter on: An asynchronous execution context.
    /// - parameter f: A closure defining the continuation.
    /// - returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's returned future.
    public func flatMap<R>(on executor: ExecutionContext, cancellationToken: CancellationTokenProtocol, _ f: T -> Future<R>) -> Future<R> {
        cancellationToken.onCancel() { [weak self] in
            if let this = self, resolver = this._resolver {
                resolver.unregister(this)
            }
        }
        return self.flatMap(on: executor, f)
    }


}





// MARK: Extension DebugPrintable

extension Future : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var s:String = ""
        sync.read_sync_safe { /*[unowned(unsafe) self] in */
            var stateString: String
            if let res = self._result {
                switch res {
                case .Failure: stateString = "rejected"
                case .Success: stateString = "fulfilled"
                }
            }
            else {
                stateString = "pending with \(self._register_count) continuations"
            }
            s = "future<\(T.self)> id: \(self.id) state: \(stateString)"
        }
        return s
    }
    
    
}

