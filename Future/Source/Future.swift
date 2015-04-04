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




/// A Resolver is an object whose responsibility is to eventually either fulfill
/// or reject its associated future respectively its promise.
///
/// For a particular future, there is one and only one resolver at a time.
/// On the other hand, a client which _cancels_ a cancelable future does not need 
/// to be a resolver.
///
/// The Resolver protocol plays an important role in the Cancellation mechanism
/// implemented in the Future and Promise Lib.
public protocol Resolver {
    
    /// A resolver returns a Cancelable instance if it itself is also cancelable. 
    /// Otherwise it returns nil.
    var cancelable : Cancelable? {get}
    
    /// Returns the dependent resolver if any, otherwise returns nil.
    var resolver : Resolver? {get}
}


// MARK: - ExecutionContext

struct Asynchronously {}
struct Synchronously {}

/// An ExecutionContext is a thing that can execute closures.
public protocol ExecutionContext {
    /// Asynchronuosly executes the given closure f on its execution context.
    ///
    /// :param: f The closure takeing no parameters and returning ().
    func execute(f:()->()) -> ()
}



// MARK: - future function

/// Asynchronously executes the closure f on a private execution context and
/// returns a future for the eventual result.
///
/// :param:     f A closure which takes no parames and which returns a value of type Result<R> representing the result of the closure.
/// :returns:   A future of type Future<R>.
public func future<R>(f:()->Result<R>) -> Future<R> {
    let returnedFuture :Future<R> = Future<R>()
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), {
        switch f() {
        case .Success(let value): returnedFuture.resolve(value[0])
        case .Failure(let error): returnedFuture.resolve(error)
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
    let returnedFuture :Future<R> = Future<R>()
    executor.execute() {
        switch f() {
        case .Success(let value): returnedFuture.resolve(value[0])
        case .Failure(let error): returnedFuture.resolve(error)
        }
    }
    return returnedFuture
}




// MARK: - ExecutionContext Extension


extension dispatch_queue_t : ExecutionContext {
    public func execute(f:()->()) -> () {
        dispatch_async(self, f)
    }
}



// MARK: - Global

private var queue_ID_key = 0
private var queue_ID_value = 0

/// Returns true if the current execution context is the sync_queue
private func on_sync_queue() -> Bool {
    //return global_on_sync_queue()
    return dispatch_get_specific(&queue_ID_key) == &queue_ID_value
}
// MARK: The global synchronization queue
// (TODO: make this a private static of Promise)
// let sync_queue : dispatch_queue_t = global_get_sync_queue();

private let sync_queue : dispatch_queue_t = {
    let q = dispatch_queue_create("promise.sync_queue", DISPATCH_QUEUE_CONCURRENT)!
    dispatch_queue_set_specific(q, &queue_ID_key, &queue_ID_value, nil)
    return q
    }()




// MARK: - Synchronization Wrappers


//private func read_sync<T>(f: @autoclosure ()->T) -> T {
//    var v: T
//    dispatch_sync(s_sync_queue) { v = closure() }
//    return v
//}

/// The function read_sync_safe executes the closure on the synchronization execution
/// context and waits for completion.
/// The closure can safely read the objects associated to the context. However,
/// the closure must not modify the objects associated to the context.
/// If the current execution context is already the synchronization context the
/// function directly calls the closure. Otherwise it dispatches it on the synchronization 
/// context.
private func read_sync_safe(f: ()->()) -> () {
    if on_sync_queue() {
        f()
    }
    else {
        dispatch_sync(sync_queue, f)
    }
}

/// The function read_sync executes the closure on the synchronization execution
/// context and waits for completion.
/// The current execution context must not already be the synchronization context,
/// otherwise the function will dead lock.
/// The closure can safely read the objects associated to the context. However,
/// the closure must not modify the objects associated to the context.
/// The closue will be dispatched on the synchronization context and waits for completion.
private func read_sync(f: ()->()) -> () {
    dispatch_sync(sync_queue, f)
}

/// The function write_async asynchronously executes the closure on the synchronization 
/// execution context and returns immediately.
/// The closure can safely modify the objects associated to the context. No other 
/// concurrent read or write operation can interfere.
private func write_async(f: ()->()) -> () {
    dispatch_barrier_async(sync_queue, f)
}
/// The function write_sync executes the closure on the synchronization execution
/// context and waits for completion.
/// The closure can modify the objects associated to the context. No other
/// concurrent read or write operation can interfere.
/// The current execution context must not already be the synchronization context,
/// otherwise the function will dead lock.
private func write_sync(f: ()->()) -> () {
    dispatch_barrier_sync(sync_queue, f)
}


// MARK: - Future


public class Future<T> : Resolver, DebugPrintable {
    
    public typealias ValueType = T
    public typealias ResultType = Result<T>
    public typealias ErrorType = NSError
    
    private var _result: Result<T>?
    private var _handler_queue: dispatch_queue_t?
    private var _resolver : Resolver?
    
    
    
    // MARK: init
    
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
        read_sync_safe {
            if (self._result == nil && self._handler_queue != nil) {
                dispatch_resume(self._handler_queue!)
            }
            Log.Debug("Future destroyed: \(self.debugDescription).")
        }
    }

    public var id: UInt {
        return reflect(self).objectIdentifier!.uintValue
    }

    
    public var debugDescription: String {
        var s:String = ""
        read_sync_safe {
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
            let s = "future<\(T.self)> id: \(self.id) state: \(stateString)"
        }
        return s
    }

    
    // MARK: Resolver
    
    /// Implements the Resolver Protocol

    /// Returns nil since a future is by itself not cancelable.
    public var cancelable: Cancelable? { get { return nil } }
    
    /// Returns the resolver to which self depends on if any. It may return nil.
    public var resolver: Resolver? { get { return _resolver } }
    
    
    // MARK: Private
    
    /// Immediately fulfills self with the value.
    internal final func resolve(value : T) {
        write_sync { [unowned self] in
            if self._result == nil {
                self._result = Result(value)
                if self._handler_queue != nil {
                    dispatch_resume(self._handler_queue!)
                    self._handler_queue = nil
                }
            }
            self._resolver = nil;
        }
    }

    /// Immediately rejects self with the error.
    internal final func resolve(error : NSError) {
        write_sync { [unowned self] in
            if self._result == nil {
                self._result = Result(error)
                if self._handler_queue != nil {
                    dispatch_resume(self._handler_queue!)
                    self._handler_queue = nil
                }
            }
            self._resolver = nil;
        }
    }
    
    /// Immediately resolves self with the result.
    internal final func resolve(result : Result<T>) {
        write_sync { [unowned self] in
            if self._result == nil {
                self._result = result
                if self._handler_queue != nil {
                    dispatch_resume(self._handler_queue!)
                    self._handler_queue = nil
                }
            }
            self._resolver = nil;

        }
    }

    /// Resolves self with the eventual result of future other. That is, other
    /// becomes the resolver of self - iff self still exists. Self should not be
    /// resolved by another resolver.
    /// Retains other until self remains pending.
    /// Alias for bind (aka resolveWith)
    internal final func resolve(other: Future) {
        other.onComplete() { [weak self] result -> () in
            switch result {
            case .Success(let value): self?.resolve(value[0])
            case .Failure(let error): self?.resolve(error)
            }
        }
    }
    

    /// Enqueues the closure f on the handler queue.
    /// Creates the handler queue if it called the first time.
    private final func register(f: ()->()) {
        assert(on_sync_queue())
        if (_handler_queue == nil) {
            _handler_queue = dispatch_queue_create("handler_queue", nil)!
            dispatch_set_target_queue(_handler_queue, sync_queue)
            dispatch_suspend(_handler_queue!)
        }
        dispatch_async(_handler_queue!, f)
    }
    

    // MARK: - Public
    
    /// Registers the continuation `f` with a parameter `result` which will be executed on the
    /// given execution context when it has been completed (either fulfilled or rejected).
    /// The continuation will be called with a copy of `self`'s result.
    /// Retains `self` until it is completed.
    ///
    /// :param: executor The execution context where the closure `f` will be executed.
    /// :param: f A closure taking a `Result<T>` as parameter.
    public final func onComplete(executor: ExecutionContext, f: Result<T> -> ())-> () {
        write_async {
            if let r = self._result { // self already resolved
                executor.execute() {
                    f(r)
                }
            } else { // self still pending
                self.register() {
                    assert(on_sync_queue())
                    let r = self._result!
                    executor.execute() {
                        f(r)
                    }
                }
            }
        }
    }
    
    /// Registers the continuation `f` with a parameter `result` which will be executed on a
    /// private execution context when it has been completed (either fulfilled or rejected).
    /// The continuation will be called with a copy of `self`'s result.
    /// Retains `self` until it is completed.
    ///
    /// :param: f A closure taking a `Result<T>` as parameter.
    public final func onComplete(f: Result<T> -> ())-> () {
        onComplete(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f: f)
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
//    /// Executes closure f on the on the global dispatch queue when it is resolved.
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
    public final func onSuccess(executor: ExecutionContext, _ f: T -> ())-> () {
        onComplete(executor) { result -> () in
            switch result {
            case .Success(let value):
                f(value[0])
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
    public final func onSuccess(f: T -> ())-> () {
        onSuccess(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    
    
    /// Registers the continuation `f` which takes a parameter `error` of type `NSError` which will be executed
    /// on the given execution context when `self` has been rejected.
    /// The continuation will be called with a copy of `self`'s error.
    /// Retains `self` until it is completed.
    ///
    /// :param: executor The execution context where the closure f will be executed.
    /// :param: f A closure taking a paramter `error` of type `NSError` as parameter.
    public final func onFailure(executor: ExecutionContext, _ f: NSError -> ())-> () {
        onComplete(executor) { result -> () in
            switch result {
            case .Failure(let error): f(error)
            default:break
            }
        }
    }
    
    /// Registers the continuation `f` which takes a parameter `error` of type `NSError` which will be executed
    /// on a private execution context when `self` has been rejected.
    /// The continuation will be called with a copy of `self`'s error.
    /// Retains `self` until it is completed.
    ///
    /// :param: executor The execution context where the closure f will be executed.
    /// :param: f A closure taking a paramter `error` of type `NSError` as parameter.
    public final func onFailure(f: NSError -> ())-> () {
        onFailure(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }

//    /// Executes closure f on the given execution context when it is cancelled.
//    /// Does not retain self.
//    public final func onCancel(executor: ExecutionContext, f: NSError -> ())-> () {
//        weakOnComplete(executor) { result -> () in
//            switch result {
//            case .Failure(let error):
//                if (error.code == -1) {
//                    f(error)
//                }
//            default:break
//            }
//        }
//    }
    
//    /// Executes closure f on the global dispatch queue when it is cancelled.
//    /// Does not retain self.
//    public final func onCancel(f: NSError -> ())-> () {
//        onCancel(dispatch_get_global_queue(0, 0), f)
//    }
    
    
    
    /// Returns a new future which - iff it still exists - will be resolved with
    /// the eventual result from self. Thus, self becomes the resolver of the returned 
    /// future.  
    /// It's assumed that self is the only resolver of the returned future.
    ///
    /// Retains `self` until it is completed.
    ///
    /// :returns: A new future.
    public final func proxy() -> Future<T> {
        let returnedFuture = Future<T>()
        self.onComplete() { [weak returnedFuture] result -> () in
            switch result {
            case .Success(let value): returnedFuture?.resolve(value[0])
            case .Failure(let error): returnedFuture?.resolve(error)
            }
        }
        return returnedFuture
    }
    
    
//    /// Returns the cancelable resolver or nil if there is no such resolver.
//    /// Note, that this method is not indempotent!
//    ///
//    /// The resolver returned is also the currently executing and cancelable task 
//    /// which is required to finish in order to eventually resolve self.
//    /// The method returns the nearest resolver associated to a future in the 
//    /// dependency chain if that resolver is cancelable and if rejecting the 
//    /// resolver's promise would directly or indirectly reject self. That is, 
//    /// self is either the root promise, or a child or grand child of the root 
//    /// promise associated to the resolver. If that cancelable resolver would be 
//    /// cancelled, and if that resolver itself is still executing, it should cancel 
//    /// its task and reject its promise with a corresponding error reason which
//    /// in turn would reject self with that error. Since, it the meantime a
//    /// cancelable resolver may finish with success, there is no guarantee that
//    /// calling cancel on that cancelable resolver will actually reject self.
//    /// If the cancelable resolver has finished, another call to cancelable() 
//    /// may return another cancelable resolver or nil.
//    ///
//    /// If an object will be returned, calling cancel() on it will reject the 
//    /// future with a corresponding error.
//    public func firstCancelableResolver() -> Cancelable? {
//        var resolver : Resolver?  = _resolver
//        while (resolver? != nil) {
//            if let cancelable = resolver!.cancelable? {
//                return cancelable
//            }
//            resolver = resolver!.resolver
//        }
//        return nil
//    }
    
    
    
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
    public func map<R>(on executor: ExecutionContext, _ f: T -> Result<R>) -> Future<R> {
        let returnedFuture = Future<R>()
        onComplete(executor) { [weak returnedFuture] result in
            switch result {
            case .Success(let value):
                let r = f(value[0])
                switch r {
                case .Success(let v): returnedFuture?.resolve(v[0])
                case .Failure(let e): returnedFuture?.resolve(e)
                }
            case .Failure(let error):
                returnedFuture?.resolve(error)
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
    public func flatMap<R>(on executor: ExecutionContext, _ f: T -> Future<R>) -> Future<R> {
        let returnedFuture = Future<R>()
        onComplete(executor) { [weak returnedFuture] result in
            switch result {
            case .Success(let value):
                returnedFuture?.resolve(f(value[0]))
            case .Failure(let error):
                returnedFuture?.resolve(error)
            }
        }
        return returnedFuture
    }
    

//    /// Cancels the future which will effectively reject it with a dedicated
//    /// error reason.
//    ///
//    /// A client should cancel a pending future when it is no more interested in 
//    /// the result. The future will be rejected with an NSError instance whose 
//    /// domain equals "Future" and whose code equals -1.
//    public final func cancel() {
//        self.resolve(NSError(domain: "Future",
//                             code: -1,
//                             userInfo: [NSLocalizedFailureReasonErrorKey: "future cancelled"]))
//    }
    
    
    
    // MARK: then
    
    /// Registers the continuation `f` which takes a parameter `value` of type `T` which will
    /// be executed on the given execution context when `self` has been fulfilled.
    /// The continuation will be called with a copy of `self`'s result value.
    /// Retains `self` until it is completed.
    ///
    /// Alias: `func onSuccess(executor: ExecutionContext, _ f: T -> ())`
    ///
    /// :param: on The execution context where the closure f will be executed.
    /// :param: f A closure taking a parameter `value` of type `T`.
    public final func then(on ec: ExecutionContext, _ f: T -> ()) -> () {
        onSuccess(ec, f)
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
    public final func then<R>(on executor: ExecutionContext, _ f: T -> R) -> Future<R> {
        let returnedFuture = Future<R>()
        onComplete(executor) { [weak returnedFuture] result in
            switch (result) {
            case .Success(let value):
                let r = f(value[0])
                returnedFuture?.resolve(r)
            case .Failure(let error):
                returnedFuture?.resolve(error)
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
    public final func then(on executor: ExecutionContext, _ f: T -> NSError) -> Future<T> {
        let returnedFuture = Future<T>()
        onComplete(executor) { [weak returnedFuture] result in
            switch (result) {
            case .Success(let value):
                let r = f(value[0])
                returnedFuture?.resolve(r)
            case .Failure(let error):
                returnedFuture?.resolve(error)
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
    public final func then<R>(on executor: ExecutionContext, _ f: T -> Result<R>) -> Future<R> {
        return map(on: executor, f)
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
    public final func then<R>(on executor: ExecutionContext, _ f: T -> Future<R>) -> Future<R> {
        return flatMap(on: executor, f);
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
    public final func then(f: T -> ()) -> () {
        then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
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
    public final func then<R>(f: T -> R) -> Future<R> {
        return then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
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
    public final func then(f: T -> NSError) -> Future<T> {
        return then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
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
    public final func then<R>(f: T -> Result<R>) -> Future<R> {
        return then(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
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
    public final func then<R>(f: T -> Future<R>) -> Future<R> {
        return then(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
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
    public final func catch(on executor: ExecutionContext, _ f: NSError -> ()) -> () {
        onFailure(executor) {
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
//        onComplete(executor) { [weak returnedFuture] result -> () in
//            switch result {
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
    public final func catch(on executor: ExecutionContext, _ f: NSError -> T) -> Future<T> {
        let returnedFuture = Future<T>()
        onComplete(executor) { [weak returnedFuture] result -> () in
            switch result {
            case .Success(let value):
                returnedFuture?.resolve(value[0])
            case .Failure(let error):
                returnedFuture?.resolve(f(error))
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
    public final func catch(on executor: ExecutionContext, _ f: NSError -> Result<T>) -> Future<T> {
        let returnedFuture = Future<T>()
        onComplete(executor) { [weak returnedFuture] result -> () in
            switch result {
            case .Success(let value):
                returnedFuture?.resolve(value[0])
            case .Failure(let error):
                returnedFuture?.resolve(f(error))
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
    public final func catch(on executor: ExecutionContext, _ f: NSError -> NSError) -> Future<T> {
        let returnedFuture = Future<T>()
        onComplete(executor) { [weak returnedFuture] result -> () in
            switch result {
            case .Success(let value):
                returnedFuture?.resolve(value[0])
            case .Failure(let error):
                returnedFuture?.resolve(f(error))
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
    public final func catch(on executor: ExecutionContext, _ f: NSError -> Future<T>) -> Future<T> {
        let returnedFuture = Future<T>()
        onComplete(executor) { [weak returnedFuture] result -> () in
            switch result {
            case .Success(let value):
                returnedFuture?.resolve(value[0])
            case .Failure(let error):
                returnedFuture?.resolve(f(error))
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
    public final func catch(f: NSError -> ()) -> () {
        catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), f)
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
    public final func catch(f: NSError -> T) -> Future {
        return catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), f)
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
    public final func catch(f: NSError -> Result<T>) -> Future {
        return catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), f)
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
    public final func catch(f: NSError -> NSError) -> Future<T> {
        return catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), f)
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
    public final func catch(f: NSError -> Future<T>) -> Future<T> {
        return catch(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), f)
    }
    
    
    // MARK: - finally
    
    public final func finally(on executor: ExecutionContext, _ f: () -> ()) {
        onComplete(executor) { result -> () in
            f()
        }
    }
    public final func finally<R>(on executor: ExecutionContext, _ f: () -> R) -> Future<R> {
        let returnedFuture = Future<R>()
        onComplete(executor) { result -> () in
            let r = f()
            returnedFuture.resolve(r)
        }
        return returnedFuture
    }
    public final func finally<R>(on executor: ExecutionContext, _ f: () -> Result<R>) -> Future<R> {
        let returnedFuture = Future<R>()
        onComplete(executor) { result -> () in
            let r = f()
            returnedFuture.resolve(r)
        }
        return returnedFuture
    }
    public final func finally(on executor: ExecutionContext, _ f: () -> NSError) -> Future<T> {
        let returnedFuture = Future<T>()
        onComplete(executor) { result -> () in
            let r = f()
            returnedFuture.resolve(r)
        }
        return returnedFuture
    }
    public final func finally<R>(on executor: ExecutionContext, _ f: () -> Future<R>) -> Future<R>  {
        let returnedFuture = Future<R>()
        onComplete(executor) { [weak returnedFuture] result -> () in
            switch result {
            case .Success, .Failure:
                returnedFuture?.resolve(f())
            }
        }
        return returnedFuture
    }
    
    public final func finally(f: () -> ()) -> () {
        finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    public final func finally<R>(f: () -> R) -> Future<R> {
        return finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    public final func finally<R>(f: () -> Result<R>) -> Future<R> {
        return finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    public final func finally(f: () -> NSError) -> Future {
        return finally(on:dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    public final func finally<R>(f: () -> Future<R>) -> Future<R> {
        return finally(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    
}






















