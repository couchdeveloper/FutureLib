//
//  Future.swift
//  Future
//
//  Created by Andreas Grosam on 06.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//

import Foundation

/// Initialize and configure the Logger
let Log = Logger("Future")




/// An ExecutionContext that synchronously executes on the current execution context.
private struct SynchronousCurrent : ExecutionContext {
    /// synchronuosly executes the given closure f on its execution context.
    ///
    /// :param: f The closure takeing no parameters and returning ().
    private func execute(f:()->()) {
        f()
    }
}



// MARK: - Protocol Resolver
//
/// A Resolver is an object whose responsibility is to eventually resolve
/// its associated Resolvable with a result value.
internal protocol Resolver {

    func unregister<T:Resolvable>(resolvable: T) -> ()

}


// MARK: - Protocol Resolvable
//
/// A Resolvable is an object which is initially created in a "pending" state and
/// can transition to a "completed" state through resolving the resolvablecvwith 
/// a result value (Result<T>). The resolvabale can be complted only once, and
/// can not transition to another state afterward.
/// For a particular Resolvable, there is one and only one resolver at a time.
internal protocol Resolvable {
    
    typealias ValueType
    
    func resolve(result : Result<ValueType>)
    
    var resolver: Resolver? { get }

}






// MARK: - future function
//
/// Asynchronously executes the closure f on a private execution context and
/// returns a future for the eventual result.
///
/// :param:     f A closure which takes no parames and which returns a value of type Result<R> representing the result of the closure.
/// :returns:   A future of type Future<R>.
public func future<R>(f:()->Result<R>) -> Future<R> {
    let returnedFuture :Future<R> = Future<R>(resolver: nil)
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
        switch f() {
        case .Success(let value): returnedFuture.resolve(Result(value[0]))
        case .Failure(let error): returnedFuture.resolve(Result(error))
        }
    })
    return returnedFuture
}

/// Asynchronously executes the closure f on a private execution context and
/// returns a future for the eventual result.
///
/// :param:     executor An execution context which asynchronously executes the given closure.
/// :param:     f A closure which takes no parames and which returns a value of type Result<R> representing the result of the closure.
/// :returns:   A future of type Future<R>.
public func future<R>(on executor: ExecutionContext, f:()->Result<R>) -> Future<R> {
    let returnedFuture :Future<R> = Future<R>(resolver:nil)
    executor.execute() {
        switch f() {
        case .Success(let value): returnedFuture.resolve(Result(value[0]))
        case .Failure(let error): returnedFuture.resolve(Result(error))
        }
    }
    return returnedFuture
}






extension Future : Resolvable {
    
    /// Completes self with the given result.
    final func resolve(result : Result<Future.ValueType>) {
        sync.write_sync { [unowned self] in
            self._resolve(result)
        }
    }
 
    /// Returns the resolver to which self depends on if any. It may return nil.
    internal var resolver: Resolver? { get { return _resolver } }
    
}




extension Future : Resolver {
    
    /// Undo registering the given resolvable.
    final func unregister<T:Resolvable>(resolvable: T) -> () {
        sync.read_sync_safe() {
            self._unregister()
        }
    }
}




// MARK: - Class Future

private let sync = Synchronize()


public class Future<T> : DebugPrintable {
    
    public typealias ValueType = T
    
    private var _result: Result<T>?
    private var _handler_queue: dispatch_queue_t?
    private var _register_count = 0
    private var _resolver : Resolver?
    
    
    // MARK: init/deinit
    
    internal init(resolver: Resolver? = nil) {
        _resolver = resolver
        Log.Debug("Future created with id: \(self.id).")
    }
    internal init(_ value:T, resolver: Resolver? = nil) {
        _resolver = resolver
        _result = Result<T>(value)
        Log.Debug("Fulfilled future created with id: \(self.id) with value \(value).")
    }
    internal init (_ error:NSError, resolver: Resolver? = nil) {
        _resolver = resolver
        _result = Result<T>(error)
        Log.Debug("Rejected future created with id: \(self.id) with error \(error).")
    }
    
    
    deinit {
        sync.read_sync_safe {
            if (self._result == nil && self._handler_queue != nil) {
                dispatch_resume(self._handler_queue!)
            }
            Log.Debug("Future destroyed: \(self.debugDescription).")
        }
    }

    
    // MARK: utility
    
    public var id: UInt {
        return reflect(self).objectIdentifier!.uintValue
    }

    
    // MARK: Private
    
    
    /// Completes `self` with the given result.
    private final func _resolve(result : Result<T>) {
        assert(sync.on_sync_queue())
        if self._result == nil {
            self._result = result
            if self._handler_queue != nil {
                dispatch_resume(self._handler_queue!)
                self._handler_queue = nil
            }
        } 
        self._resolver = nil;
    }
    
    /// Registers a completion function for the given future `other` which
    /// completes `self` with the same result. That is, future `other` becomes
    /// the resolver of `self` - iff `self` still exists. `self` should not be
    /// resolved by another resolver.
    /// Retains `other` until `self` remains pending.
    /// Alias for bind (aka resolveWith)
    private final func resolve(other: Future) {
        sync.write_async() {
            self._resolve(other)
        }
    }
    
    /// Registers a completion function for the given future `other` which
    /// completes `self` with the same result. That is, future `other` becomes
    /// the resolver of `self` - iff `self` still exists. `self` should not be
    /// resolved by another resolver.
    /// Retains `other` until `self` remains pending.
    /// Alias for bind (aka resolveWith)
    private final func _resolve(other: Future) {
        assert(sync.on_sync_queue())
        self._resolver = other;
        other.onComplete(on:SynchronousCurrent()) { [weak self] otherResult -> () in
            self?._resolve(otherResult); return
        }
    }
    
    /// Completes self with a cancelation error
    private final func _cancel(error: NSError?) {
        assert(sync.on_sync_queue())
        if self._result == nil {
            let err = error != nil ? CancellationError(underlyingError: error!) : CancellationError()
            self._result = Result(err)
            if self._handler_queue != nil {
                dispatch_resume(self._handler_queue!)
                self._handler_queue = nil
            }
        }
        if let resolver = self._resolver {
            resolver.unregister(self)
            self._resolver = nil;
        }
    }
    

    /// If there is a cancellation token given and if there is a cancellation request for this token
    /// and if there are no other continuations registered `self` will be completed with a
    /// `CancellationError` and closure `f` will be directly called.
    /// Otherwise, the closure `f` will be registered which increments `_register_count` and if there 
    /// is a (pending) cancellation token, the cancellation token will register a closure which effectively 
    /// calls `self._unregister()` for the weakly captured `self`.
    /// _register must execute on the sync queue with write access.
    /// `self` must not be completed.
    private final func _register(cancellationToken: CancellationToken?, f: ()->()) {
        assert(sync.on_sync_queue())
        assert(self._result == nil)
        let isCancelled = cancellationToken != nil ? cancellationToken!.isCancellationRequested : false
        let doCancel = isCancelled && _register_count == 0
        if doCancel {
            _cancel(nil)
            f()
        }
        else {
            if (_handler_queue == nil) {
                _handler_queue = dispatch_queue_create("handler_queue", nil)!
                dispatch_set_target_queue(_handler_queue, sync.sync_queue)
                dispatch_suspend(_handler_queue!)
            }
            ++_register_count
            if let ct = cancellationToken {
                ct.onCancel(on: SynchronousCurrent()) { [weak self] in
                    if let this = self {
                        this._unregister()
                    }
                }
            }
            dispatch_async(_handler_queue!, f)
        }
    }
    
    
    /// Decrements `_register_count` and if it becomes zero `self` will be completed with a
    /// `CancellationError`.
    /// _unregister must execute on the sync queue with write access.
    /// `self` must not be completed.
    private final func _unregister() {
        assert(sync.on_sync_queue())
        assert(self._result == nil)
        if (--_register_count == 0) {
            _cancel(nil)
        }
    }
    
    
    // MARK: - Public
    
    /// Registers the continuation `f` which takes a parameter `result` which will be executed on the
    /// given execution context when it has been completed (either fulfilled or rejected).
    /// The continuation will be called with a copy of `self`'s result.
    /// Retains `self` until it is completed.
    ///
    /// :param: executor The execution context where the closure `f` will be executed.
    /// :param: f A closure taking a `Result<T>` as parameter.
    /// :param: cancellationToken An optional cancellation token.
    public final func onComplete(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, f: Future<T> -> ())-> () {
        sync.write_async {
            if self._result != nil  { // self already resolved
                executor.execute() {
                    f(self)
                }
            } else { // self still pending
                self._register(cancellationToken) {
                    assert(sync.on_sync_queue())
                    executor.execute() {
                        f(self)
                    }
                }
            }
        }
    }
    
    /// Registers the continuation `f` which takes a parameter `result` which will be executed on a
    /// private execution context when it has been completed (either fulfilled or rejected).
    /// The continuation will be called with a copy of `self`'s result.
    /// Retains `self` until it is completed.
    ///
    /// :param: f A closure taking a `Result<T>` as parameter.
    /// :param: cancellationToken An optional cancellation token.
    public final func onComplete(cancellationToken: CancellationToken? = nil, f: Future<T> -> ())-> () {
        onComplete(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f: f)
    }
    
    
    
    
    
    
//    /// Executes closure f on the given execution context when it is resolved.
//    /// Does not retain self. Accessing the internal state is thread-safe.
//    /// The methods weakOnComplete has no perceivable side-effect when the future 
//    /// will be deinitialized before it has been resolved.
//    ///
//    /// :param: executor The execution context where the closure f will be executed.
//    /// :param: f A closure taking a Result<T> as parameter representing the result of the task.
//    public final func weakOnComplete(executor: ExecutionContext, f: Result<T> -> ())-> () {
//        read_sync {
//            if let r = self._result { // self already resolved
//                executor.execute() {
//                    f(r)
//                }
//            } else { // self still pending
//                assert(self._handler_queue != nil)
//                self.register(self._handler_queue!) { [weak self] in
//                    assert(on_sync_queue())
//                    if let r = self?._result {
//                        executor.execute() {
//                            f(r)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    /// Executes closure f on the global dispatch queue when it is resolved.
//    /// Does not retain self. Accessing the internal state is thread-safe.
//    ///
//    /// :param: f A closure taking a Result<T> as parameter representing the result of the task.
//    public final func weakOnComplete(f: Result<T> -> ())-> () {
//        weakOnComplete(dispatch_get_global_queue(0, 0), f: f)
//    }
//  
    
    
    
    
    /// Registers the continuation `f` which takes a parameter `value` of type `T` which will 
    /// be executed on the given execution context when `self` has been fulfilled.
    /// The continuation will be called with a copy of `self`'s result value.
    /// Retains `self` until it is completed.
    ///
    /// :param: executor The execution context where the closure f will be executed.
    /// :param: f A closure taking a parameter `value` of type `T`.
    public final func onSuccess(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: T -> ())-> () {
        onComplete(on: SynchronousCurrent(), cancellationToken:cancellationToken) { _ in
            switch self._result! {
            case .Success(let value):
                executor.execute() {
                    f(value[0])
                }
            default:break
            }
        }
    }
    /// Registers the continuation `f` which takes a parameter `value` of type `T` which will be executed
    /// on a private execution context when `self` has been fulfilled.
    /// The continuation will be called with a copy of `self`'s result value.
    /// Retains `self` until it is completed.
    ///
    /// :param: executor The execution context where the closure f will be executed.
    /// :param: f A closure taking a parameter `value` of type `T`.
    public final func onSuccess(cancellationToken: CancellationToken?,  _ f: T -> ())-> () {
        onSuccess(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken:cancellationToken, f)
    }
    
    
    /// Registers the continuation `f` which takes a parameter `error` of type `NSError` which will be executed
    /// on the given execution context when `self` has been rejected.
    /// The continuation will be called with a copy of `self`'s error.
    /// Retains `self` until it is completed.
    ///
    /// :param: executor The execution context where the closure f will be executed.
    /// :param: f A closure taking a paramter `error` of type `NSError` as parameter.
    public final func onFailure(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: NSError -> ())-> () {
        onComplete(on: SynchronousCurrent(), cancellationToken:cancellationToken) { _ in
            switch self._result! {
            case .Failure(let error):
                executor.execute() {
                    f(error)
                }
            default:break
            }
        }
    }
    
    /// Registers the continuation `f` which takes a parameter `error` of type `NSError` which will be executed
    /// on a private execution context when `self` has been rejected.
    /// The continuation will be called with a copy of `self`'s error.
    /// Retains `self` until it is completed.
    ///
    /// :param: f A closure taking a paramter `error` of type `NSError` as parameter.
    public final func onFailure(cancellationToken: CancellationToken? = nil, _ f: NSError -> ())-> () {
        onFailure(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken:cancellationToken, f)
    }
    
    
    // Cancellation
    
    /// Registers the continuation `f` with a parameter `error` which will be executed on the
    /// given execution context when `self` has been cancelled.
    ///
    /// Self will transition to the `Cancelled` state only
    ///  1. if it has an associated cancellation token which has been cancelled
    ///  1. if it is still pending and
    ///  1. if it has no continuations or all continuations have been cancelled.
    /// The continuation will be called with a copy of `self`'s error.
    /// Retains `self` until it is completed.
    ///
    /// :param: executor The execution context where the closure f will be executed.
    /// :param: f A closure taking an error as parameter.
    internal final func onCancel(on executor: ExecutionContext, _ f: NSError -> ())-> () {
        onComplete(on: SynchronousCurrent()) { _ in
            switch self._result! {
            case .Failure(let error) where error is CancellationError:
                if (error is CancellationError) {
                    executor.execute() {
                        f(error)
                    }
                }
            default:break
            }
        }
    }

    /// Registers the continuation `f` with a parameter `error` which will be executed on a
    /// private execution context when `self` has been cancelled. 
    ///
    /// Self will transition to the `Cancelled` state only
    ///  1. if it has an associated cancellation token which has been cancelled
    ///  1. if it is still pending and
    ///  1. if it has no continuations or all continuations have been cancelled.
    /// The continuation will be called with a copy of `self`'s error.
    /// Retains `self` until it is completed.
    ///
    /// :param: f A closure taking an error as parameter.
    internal final func onCancel(f: NSError -> ())-> () {
        onCancel(on: dispatch_get_global_queue(0, 0), f)
    }

    
    
    
    /// Returns a new future which - iff it still exists - will be resolved with
    /// the eventual result from self. Thus, self becomes the resolver of the returned
    /// future.  
    /// It's assumed that self is the only resolver of the returned future.
    ///
    /// Retains `self` until it is completed.
    ///
    /// :returns: A new future.
    public final func proxy() -> Future<T> {
        // TODO: check if cancellation token should be used
        let returnedFuture = Future<T>(resolver:self)
        self.onComplete(on: SynchronousCurrent()) { [weak returnedFuture] future -> () in
            returnedFuture?.resolve(future._result!)
            return
        }
        return returnedFuture
    }
    
    
    
    // MARK: map & flatMap
    
    
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
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's return value.
    public func map<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: T -> Result<R>) -> Future<R> {
        let returnedFuture = Future<R>(resolver:self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            switch self._result! {
            case .Success(let value):
                executor.execute() {
                    returnedFuture?.resolve(f(value[0]))
                }
            case .Failure(let error):
                returnedFuture?._resolve(Result(error))
            }
        }
        return returnedFuture;
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
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's returned future.
    public func flatMap<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: T -> Future<R>) -> Future<R> {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            switch self._result! {
            case .Success(let value):
                executor.execute() {
                    returnedFuture?.resolve(f(value[0]))
                }
            case .Failure(let error):
                returnedFuture?._resolve(Result(error))
            }
        }
        return returnedFuture
    }
    

    // MARK: then
    
    
    /// Registers a continuation with a success handler `onSuccess` which takes a value
    /// of type `T` and an error handler `onError` which takes an error of type `NSError`
    /// Both handlers return a result of type `Result<R>`.
    ///
    /// If `self` has been fulfilled with a value the success handler `onSuccess` will be executed
    /// on the given execution context with a copy of the value. The returned future (if it
    /// still exists) will be resolved with the result of the success handler function.
    /// Otherwise, when `self` has been rejected with an error, the error handler `onError` will
    /// be executed on the given execution context with this error. The returned future (if it
    /// still exists) will be resolved with the result of the error handler function.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func then<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil,
            _ onSuccess: T -> Result<R>,
            _ onError: NSError -> Result<R>)
    -> Future<R>
    {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] future in
            let r: Result<R>
            switch future._result! {
            case .Success(let value):
                r = onSuccess(value[0])
            case .Failure(let error):
                r = onError(error)
            }
            returnedFuture?.resolve(r)
        }
        return returnedFuture
    }
    
    
    
    /// Registers the continuation `f` which takes a parameter `value` of type `T` which will
    /// be executed on the given execution context when `self` has been fulfilled.
    /// The continuation will be called with a copy of `self`'s result value.
    /// Retains `self` until it is completed.
    ///
    /// Alias: `func onSuccess(executor: ExecutionContext, _ f: T -> ())`
    ///
    /// :param: on The execution context where the closure f will be executed.
    /// :param: f A closure taking a parameter `value` of type `T`.
    public final func then(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: T -> ()) -> () {
        onSuccess(on: executor, cancellationToken:cancellationToken, f)
    }
    


    
    /// Registers the continuation `f` which takes a value of type `T` and returns
    /// a value of type `R`.
    ///
    /// If `self` has been fulfilled with a value the continuation `f` will be executed
    /// on the given execution context with a copy of the value. The returned future (if it
    /// still exists) will be fulfilled with the returned value of the continuation function.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the same error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func then<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: T -> R) -> Future<R> {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            switch self._result! {
            case .Success(let value):
                executor.execute() {
                    returnedFuture?.resolve(Result(f(value[0])))
                }
            case .Failure(let error):
                returnedFuture?._resolve(Result(error))
            }
        }
        return returnedFuture
    }

    /// Registers the continuation `f` which takes a value of type `T` and returns
    /// an error of type `NSError`.
    ///
    /// If `self` has been fulfilled with a value the continuation `f` will be executed
    /// on the given execution context with a copy of the value. The returned future (if it
    /// still exists) will be rejected with the returned error of the continuation function.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the same error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func then(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: T -> NSError) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            switch self._result! {
            case .Success(let value):
                executor.execute() {
                    returnedFuture?.resolve(Result(f(value[0])))
                }
            case .Failure(let error):
                returnedFuture?._resolve(Result(error))
            }
        }
        return returnedFuture
    }

    /// Registers the continuation `f` which takes a value of type `T` and returns
    /// a result of type `Result<R>`.
    ///
    /// If `self` has been fulfilled with a value the continuation function `f` will be executed
    /// on the given execution context with a copy of the value. The returned future (if it
    /// still exists) will be resolved with the returned result of the continuation function.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the same error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned result.
    public final func then<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: T -> Result<R>) -> Future<R> {
        return map(on: executor, cancellationToken: cancellationToken, f)
    }

    /// Registers the continuation function `f` which takes a value of type `T` and returns
    /// a *deferred* value of type `R` by means of a `Future<R>`.
    ///
    /// If `self` has been fulfilled with a value the continuation function `f` will be executed
    /// on the given execution context with a copy of the value. The returned future (if it
    /// still exists) will be resolved with a future `Future<R>` returned from the continuation
    /// function `f`.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the samne error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned future.
    public final func then<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: T -> Future<R>) -> Future<R> {
        return flatMap(on: executor, cancellationToken: cancellationToken, f);
    }
    
    /// Registers the continuation `f` which takes a parameter `value` of type `T` which will
    /// be executed on a private execution context when `self` has been fulfilled.
    /// The continuation will be called with a copy of `self`'s result value.
    /// Retains `self` until it is completed.
    ///
    /// Alias: `func onSuccess(f: T -> ())`
    ///
    /// :param: on The execution context where the closure f will be executed.
    /// :param: f A closure taking a parameter `value` of type `T`.
    public final func then(cancellationToken: CancellationToken? = nil, _ f: T -> ()) -> () {
        then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }

    /// Registers the continuation `f` which takes a value of type `T` and returns
    /// a value of type `R`.
    ///
    /// If `self` has been fulfilled with a value the continuation `f` will be executed
    /// on a private execution context with a copy of the value. The returned future (if it
    /// still exists) will be fulfilled with the returned value of the continuation function.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the same error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func then<R>(cancellationToken: CancellationToken? = nil, _ f: T -> R) -> Future<R> {
        return then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }

    /// Registers the continuation `f` which takes a value of type `T` and returns
    /// an error of type `NSError`.
    ///
    /// If `self` has been fulfilled with a value the continuation `f` will be executed
    /// on a private execution context with a copy of the value. The returned future (if it
    /// still exists) will be rejected with the returned error of the continuation function.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the same error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func then(cancellationToken: CancellationToken? = nil, _ f: T -> NSError) -> Future<T> {
        return then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }

    /// Registers the continuation `f` which takes a value of type `T` and returns
    /// a result of type `Result<R>`.
    ///
    /// If `self` has been fulfilled with a value the continuation function `f` will be executed
    /// on a private execution context with a copy of the value. The returned future (if it
    /// still exists) will be resolved with the returned result of the continuation function.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the same error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned result.
    public final func then<R>(cancellationToken: CancellationToken? = nil, _ f: T -> Result<R>) -> Future<R> {
        return then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }

    /// Registers the continuation function `f` which takes a value of type `T` and returns
    /// a *deferred* value of type `R` by means of a `Future<R>`.
    ///
    /// If `self` has been fulfilled with a value the continuation function `f` will be executed
    /// on a private execution context with a copy of the value. The returned future (if it
    /// still exists) will be resolved with a future `Future<R>` returned from the continuation
    /// function `f`.
    /// Otherwise, when `self` has been completed with an error, the returned future (if it
    /// still exists) will be rejected with the samne error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future which will be either rejected with `self`'s error or resolved with the continuation function's returned future.
    public final func then<R>(cancellationToken: CancellationToken? = nil, _ f: T -> Future<R>) -> Future<R> {
        return then(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    


    // MARK: catch
    
    
    
    /// Registers the continuation `f` which takes an error of type `NSError`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on the given execution context with this error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    public final func catch(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: NSError -> ()) -> () {
        onFailure(on: executor, cancellationToken: cancellationToken) {
            f($0)
        }
    }

//    /// Registers the continuation `f` which takes an error of type `NSError` and returns
//    /// a value of type `U` (either a value of type T, a Result<T>, a Future<T> or an NSError).
//    ///
//    /// If `self` has been rejected with an error the continuation `f` will be executed
//    /// on the given execution context with this error. The returned future (if it still
//    /// exists) will be fulfilled with the returned value of the continuation function.
//    /// Otherwise, when `self` has been completed with success, the returned future (if it
//    /// still exists) will be fullfilled with the same value.
//    /// Retains `self` until it is completed.
//    ///
//    /// :param: on An asynchronous execution context.
//    /// :param: f A closure defining the continuation.
//    /// :returns: A future.
//    public final func catch<U>(on executor: ExecutionContext, _ f: NSError -> U) -> Future<T> {
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
    
    
    
    /// Registers the continuation `f` which takes an error of type `NSError` and returns
    /// a value of type `T`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on the given execution context with this error. The returned future (if it still
    /// exists) will be fulfilled with the returned value of the continuation function.
    /// Otherwise, when `self` has been completed with success, the returned future (if it
    /// still exists) will be fullfilled with the same value.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func catch(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: NSError -> T) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] _ -> () in
            switch self._result! {
            case .Success(let value):
                returnedFuture?._resolve(Result(value[0]))
            case .Failure(let error):
                executor.execute() {
                    returnedFuture?.resolve(Result(f(error)))
                }
            }
        }
        return returnedFuture
    }
    
    /// Registers the continuation `f` which takes an error of type `NSError` and returns
    /// a result of type `Result<T>`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on the given execution context with this error. The returned future (if it still
    /// exists) will be fulfilled with the returned result of the continuation function.
    /// Otherwise, when `self` has been completed with success, the returned future (if it
    /// still exists) will be fullfilled with the same value.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func catch(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: NSError -> Result<T>) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            switch self._result! {
            case .Success(let value):
                returnedFuture?._resolve(Result(value[0]))
            case .Failure(let error):
                executor.execute() {
                    returnedFuture?.resolve(f(error))
                }
            }
        }
        return returnedFuture
    }
    
    /// Registers the continuation `f` which takes an error of type `NSError` and returns
    /// an error type `NSError`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on the given execution context with this error. The returned future (if it still
    /// exists) will be rejected with the returned error of the continuation function.
    /// Otherwise, when `self` has been completed with success, the returned future (if it
    /// still exists) will be fullfilled with the same value.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func catch(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: NSError -> NSError) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            switch self._result! {
            case .Success(let value):
                returnedFuture?._resolve(Result(value[0]))
            case .Failure(let error):
                executor.execute() {
                    returnedFuture?.resolve(Result(f(error)))
                }
            }
        }
        return returnedFuture
    }
    
    /// Registers the continuation `f` which takes an error of type `NSError` and returns
    /// a defered value by means of a future of type `future<T>`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on the given execution context with this error. The returned future (if it still
    /// exists) will be resolved with the returned future of the continuation function.
    /// Otherwise, when `self` has been completed with success, the returned future (if it
    /// still exists) will be fullfilled with the same value.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func catch(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: NSError -> Future<T>) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: SynchronousCurrent(), cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            switch self._result! {
            case .Success(let value):
                returnedFuture?._resolve(Result(value[0]))
            case .Failure(let error):
                executor.execute() {
                    returnedFuture?.resolve(f(error))
                }
            }
        }
        return returnedFuture
    }
    
    /// Registers the continuation `f` which takes an error of type `NSError`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on a private execution context with this error.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    public final func catch(cancellationToken: CancellationToken? = nil, _ f: NSError -> ()) -> () {
        catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken:cancellationToken, f)
    }

    
    /// Registers the continuation `f` which takes an error of type `NSError` and returns
    /// a value of type `T`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on a private execution context with this error. The returned future (if it still
    /// exists) will be fulfilled with the returned value of the continuation function.
    /// Otherwise, when `self` has been completed with success, the returned future (if it
    /// still exists) will be fullfilled with the same value.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func catch(cancellationToken: CancellationToken? = nil, _ f: NSError -> T) -> Future {
        return catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken: cancellationToken, f)
    }

    
    /// Registers the continuation `f` which takes an error of type `NSError` and returns
    /// a value of type `T`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on a private execution context with a this error. The returned future (if it
    /// still exists) will be fulfilled with the returned value of the continuation function.
    /// Otherwise, when `self` has been completed with success, the returned future (if it
    /// still exists) will be fullfilled with the same value.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func catch(cancellationToken: CancellationToken? = nil, _ f: NSError -> Result<T>) -> Future {
        return catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken:cancellationToken, f)
    }
    
    
    /// Registers the continuation `f` which takes an error of type `NSError` and returns
    /// a value of type `T`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on a private execution context with a this error. The returned future (if it
    /// still exists) will be fulfilled with the returned value of the continuation function.
    /// Otherwise, when `self` has been completed with success, the returned future (if it
    /// still exists) will be fullfilled with the same value.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func catch(cancellationToken: CancellationToken? = nil, _ f: NSError -> NSError) -> Future<T> {
        return catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken: cancellationToken, f)
    }

    
    /// Registers the continuation `f` which takes an error of type `NSError` and returns
    /// a value of type `T`.
    ///
    /// If `self` has been rejected with an error the continuation `f` will be executed
    /// on a private execution context with a this error. The returned future (if it
    /// still exists) will be fulfilled with the returned value of the continuation function.
    /// Otherwise, when `self` has been completed with success, the returned future (if it
    /// still exists) will be fullfilled with the same value.
    /// Retains `self` until it is completed.
    ///
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future.
    public final func catch(cancellationToken: CancellationToken? = nil, _ f: NSError -> Future<T>) -> Future<T> {
        return catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), cancellationToken:cancellationToken, f)
    }
    
    
    // MARK: - finally
    
    public final func finally(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: () -> ()) {
        onComplete(on: executor, cancellationToken:cancellationToken) { result -> () in
            f()
        }
    }
    public final func finally<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: () -> R) -> Future<R> {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            let r = f()
            returnedFuture?.resolve(Result(r))
        }
        return returnedFuture
    }
    public final func finally<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: () -> Result<R>) -> Future<R> {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _ in
            let r = f()
            returnedFuture?.resolve(r)
        }
        return returnedFuture
    }
    public final func finally(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: () -> NSError) -> Future<T> {
        let returnedFuture = Future<T>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _  in
            let r = f()
            returnedFuture?.resolve(Result(r))
        }
        return returnedFuture
    }
    public final func finally<R>(on executor: ExecutionContext, cancellationToken: CancellationToken? = nil, _ f: () -> Future<R>) -> Future<R>  {
        let returnedFuture = Future<R>(resolver: self)
        onComplete(on: executor, cancellationToken: cancellationToken) { [weak returnedFuture] _ -> () in
            let future = f()
            returnedFuture?.resolve(future)
        }
        return returnedFuture
    }
    
    public final func finally(cancellationToken: CancellationToken? = nil, _ f: () -> ()) -> () {
        finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    public final func finally<R>(cancellationToken: CancellationToken? = nil, _ f: () -> R) -> Future<R> {
        return finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    public final func finally<R>(cancellationToken: CancellationToken? = nil, _ f: () -> Result<R>) -> Future<R> {
        return finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    public final func finally(cancellationToken: CancellationToken? = nil, _ f: () -> NSError) -> Future {
        return finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    public final func finally<R>(cancellationToken: CancellationToken? = nil, _ f: () -> Future<R>) -> Future<R> {
        return finally(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), cancellationToken: cancellationToken, f)
    }
    
}






// MARK: Extension CancellationToken API

extension Future {


    /// Registers the continuation `f` which takes a parameter `result` which will be executed on the
    /// given execution context when it has been completed (either fulfilled or rejected).
    /// The continuation will be called with a copy of `self`'s result.
    /// Retains `self` until it is completed.
    ///
    /// :param: executor The execution context where the closure `f` will be executed.
    /// :param: f A closure taking a `Result<T>` as parameter.
    public final func onComplete(executor: ExecutionContext, cancellationToken: CancellationToken?, f: Future<T> -> ())-> () {
        sync.write_async {
            if self._result != nil  { // self already resolved
                // TODO: What if cancellationToken.isCancellationRequested returns true?
                // We cannot set self to "cancelled" - it's already completed.
                // Possibly create a Result<T> with a CancellationError and pass this result to the excutor?, e.g.:
                // executor.execute(cancellationToken) { f(Result<T>(CancellationError())) }
                // Or, follow the rule that a future which is completed cannot be cancelled, and simply ignore
                // the cancellation token:
                
                // If the future is already completed, the state of the cancellation token is ignored:
                executor.execute() {
                    f(self)
                }
            }
            else { // self still pending
                self._register(cancellationToken) {
                    assert(sync.on_sync_queue())
                    executor.execute() {
                        f(self)
                    }
                }
                if let ct = cancellationToken {
                    ct.onCancel(on: SynchronousCurrent()) { [weak self] in
                        if let this = self, resolver = this._resolver {
                            resolver.unregister(this)
                        }
                    }
                }
            }
        }
    }
    
    
    
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
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's return value.
    public func map<R>(on executor: ExecutionContext, cancellationToken: CancellationToken, _ f: T -> Result<R>) -> Future<R> {
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
    /// :param: on An asynchronous execution context.
    /// :param: f A closure defining the continuation.
    /// :returns: A future which will be either rejected with `self`'s error or resolved with the mapping function's returned future.
    public func flatMap<R>(on executor: ExecutionContext, cancellationToken: CancellationToken, _ f: T -> Future<R>) -> Future<R> {
        cancellationToken.onCancel() { [weak self] in
            if let this = self, resolver = this._resolver {
                resolver.unregister(this)
            }
        }
        return self.flatMap(on: executor, f)
    }


}





// MARK: Extension DebugPrintable

extension Future : DebugPrintable {
    
    public var debugDescription: String {
        var s:String = ""
        sync.read_sync_safe {
            var stateString: String
            if let res = self._result {
                switch res {
                case .Failure: stateString = "rejected"
                case .Success: stateString = "fulfilled"
                }
            }
            else {
                stateString = "pending"
            }
            s = "future<\(T.self)> id: \(self.id) state: \(stateString)"
        }
        return s
    }
    
    
}

