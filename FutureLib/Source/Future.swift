//
//  Future.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



// MARK: Global synchronization object
// A single object is used to provide synchronization for any future created
// in a program. For a rationale not using a dedicated synchronization object
// for each future, see (TBD).
internal let Sync = Synchronize(name: "FutureLib.sync_queue")

internal extension Future {
    internal func sync() -> Synchronize {
        return Sync
    }
}





// MARK: - Class Future

/**
 The generic class `Future`.

 A _future_ represents the _eventual result_ of an asynchronous task. In FutureLib 
 a _result_ is commonly represented by the generic class `Result<T>`, which can 
 hold either a value of type `T` or an error conforming to protocol `ErrorType`.

 Initially, the future does not have a result at all, that means the future is in 
 the _pending_ state. Eventually, the future will be _completed_ with a result which 
 is actually either a _value_ or an _error_. Once a future is completed it cannot 
 change its state anymore and its result is immutable.  A future cannot be completed
 directly, this is the responsibility of other objects which _promise_ to compute
 the value - respectively a function of other futures which forward their result
 to the future.

 From the perspective of a client, a future is "read-only". That is, a client can 
 only _read_ the result from the future, but it cannot itself modify it, neither 
 can it complete the future.
*/
public class Future<T> : FutureType {

    public typealias ValueType = T
    public typealias ResultType = Result<ValueType>
    private typealias ClosureRegistryType = ClosureRegistry<Result<ValueType>>

    private var _result: Result<ValueType>?
    private var _cr = ClosureRegistryType.Empty


    /**
     Designatated initializer which creates a pending future.
    */
    internal init() {
        //Log.Info("Future with id \(id)")
    }

    /**
     Designated initializer which creates a future completed with the given success value.
     - parameter value: The value which is bound to the completed `self`.
     */
    internal init(value: T) {
        _result = Result<ValueType>(value)
        //Log.Info("Future with id \(id)")
    }

    /**
     Designated initializer which creates a future completed with the given error.
     - parameter error: The error which is bound to the completed `self`.
    */
    internal init(error: ErrorType) {
        _result = Result<ValueType>(error: error)
        //Log.Info("Future with id \(id)")
    }

    deinit {
        //Log.Info("Future with id \(id)")
        //  The deinitializer is not called when self has continuations.
        //assert(case _cr.Empty)
    }


    /**
     - returns: A unique Id representing `self`.
    */
    public final var id: UInt {
        return ObjectIdentifier(self).uintValue
    }
    

    /**
     If `self` is completed returns its result, otherwise it returns `nil`.
     
     - returns: an optional Result<T>
     */
    public final var result: Result<ValueType>? {
        var result: Result<ValueType>? = nil
        Sync.readSync() {
            result = self._result
        }
        return result
    }



    
    

    /**
     Executes the closure `f` on the given execution context when `self` is
     completed passing `self`'s result as an argument.
     
     If `self` is not yet completed and if the cancellation token is cancelled
     the function `f` will be "unregistered" and immediately called with an argument
     `CancellationError.Cancelled` error. Note that the passed argument is NOT
     the `self`'s result and that `self` is not yet completed!
     
     The method retains `self` until it is completed or all continuations have
     been unregistered. If there are no other strong references and all continuations
     have been unregistered, `self` is being deinitialized.
     
     - parameter ec: The execution context where the function `f` will be executed.
     - parameter ct: A cancellation token.
     - parameter f: A function taking the result of the future as its argument.
     
    */
    public final func onComplete<U>(
        ec ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: Result<ValueType> -> U)
    {
        if (ct.isCancellationRequested) {
            ec.execute{
                _ = f(Result<ValueType>(error: CancellationError.Cancelled))
            }
            return
        }
        Sync.writeAsync {
            if let r = self._result {
                ec.execute {
                    _ = f(r)
                }
                return
            }
            var cid: Int = -1
            let id = self._cr.register { result in
                ec.execute {
                    self
                    _ = f(result)
                }  // import `self` into the closure in order to keep a strong
                // reference to self until after self will be completed.
                ct.unregister(cid)
            }
            cid = ct.onCancel(on: GCDBarrierAsyncExecutionContext(Sync.sync_queue)) {
                switch self._cr {
                case .Empty: break
                case .Single, .Multiple:
                    assert(self._result == nil)
                    let callback = self._cr.unregister(id)
                    assert(callback != nil)
                    ec.execute {
                        callback!.continuation(Result<ValueType>(error: CancellationError.Cancelled))
                    }
                }
            }
        }
    }

    
    /**
     Returns a new future which is completed with the unwrapped return value of the
     type cast operator `as? S` applied to `self`'s success value. If the cast fails,
     the returned future will be completed with a `FutureError.InvalidCast` error.
     
     If the cancellation token has been cancelled before `self` has been
     completed, the returned future will be completed with a `CancellationError.Cancelled`
     error. Note that this will not complete `self`! 
     
     - parameter ct: A cancellation token which will be monitored.
     - returns: A new future.
     */
    public final func mapTo<S>(ct: CancellationTokenType = CancellationTokenNone()) -> Future<S>
    {
        let returnedFuture = Future<S>()
        self.onComplete(ec: SynchronousCurrent(), ct: ct) { [weak returnedFuture] result in
            returnedFuture?._complete(result.map {
                guard case let mappedValue as S = $0 else { throw FutureError.InvalidCast }
                return mappedValue
            })
        }
        return returnedFuture
    }

    
}



// MARK: CompletableFutureType

extension Future: CompletableFutureType {
    

    internal final func complete(result: ResultType) {
        Sync.writeAsync {
            self._complete(result)
        }
    }
    
    internal final func complete(value: ValueType) {
        complete(ResultType(value))
    }
    
    internal final func complete(error: ErrorType) {
        complete(ResultType(error: error))
    }
    
    internal final func tryComplete(result: ResultType) -> Bool {
        var ret = false
        Sync.readSync {
            ret = self._result != nil
        }
        if !ret {
            Sync.writeSync {
                ret = self._tryComplete(result)
            }
        }
        return ret
    }
    
    
    private final func _tryComplete(result: ResultType) -> Bool {
        assert(Sync.isSynchronized())
        if _result == nil {
            _complete(result)
            return true
        }
        return false
    }
    
    internal final func _complete(result: ResultType) {
        assert(Sync.isSynchronized())
        assert(self._result == nil)
        self._result = result
        _cr.resume(result)
        _cr = ClosureRegistryType.Empty
    }

    internal final func _complete(value: ValueType) {
        _complete(ResultType(value))
    }
    
    internal final func _complete(error: ErrorType) {
        _complete(ResultType(error: error))
    }
    
}




// MARK: Waitable

extension Future  {
    
    
    
    /**
     Blocks the current thread until `self` is completed or if a cancellation
     has been requested.
     
     - parameter cancellationToken: A cancellation token which will be monitored by `self`.
     - returns:  `self`
     */
    public final func wait(cancellationToken: CancellationTokenType) -> Self {
        
        // wait until completed or a cancellation has been requested
        let sem: dispatch_semaphore_t = dispatch_semaphore_create(0)
        onComplete(ec: SynchronousCurrent(), ct: cancellationToken) { _ in
            dispatch_semaphore_signal(sem)
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        return self
    }
    
    
    /**
     Blocks the current thread until `self` is completed.
     - returns: `self`
     */
    public final func wait() -> Self {
        // wait until completed or a cancellation has been requested
        let sem: dispatch_semaphore_t = dispatch_semaphore_create(0)
        onComplete(ec: SynchronousCurrent(), ct: CancellationTokenNone()) { _ in
            dispatch_semaphore_signal(sem)
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        return self
    }
    

}



// MARK: Extension ContinueWith


public extension Future {
    
    /**
     Registers the mapping function `f` which will be applied to `self` as a
     `FutureBaseType` when the future will be completed or when the continuation
     will be cancelled.
     
     If the cancellation token is already cancelled or if it will be cancelled
     before `self` has been completed, the returned future will be completed with
     a `CancellationError.Cancelled` error. Note that cancelling a continuation
     will not complete `self`! Instead the mapping function `f` will be "unregistered"
     and called with the pending `self` as its argument. Otherwise, executes the
     closure `f` on the given execution context when `self` is completed passing
     the completed `self` as the argument.
     
     The method retains `self` until it is completed or all continuations have
     been unregistered. If there are no other strong references and all continuations
     have been unregistered, `self` is being deinitialized.
     
     - parameter on: The execution context where the function `f` will be executed.
     - parameter cancellationToken: A cancellation token.
     - parameter f: A closure which will be called with the completed `self` as its argument.
     */
    private final func _continueWith<U>(
        on ec: ExecutionContext,
        cancellationToken ct: CancellationTokenType,
        f: FutureBaseType -> U)
    {
        if (ct.isCancellationRequested) {
            ec.execute{
                _ = f(self)
            }
            return
        }
        Sync.writeAsync {
            if let _ = self._result {
                ec.execute {
                    _ = f(self)
                }
                return
            }
            var cid: Int = -1
            let id = self._cr.register { _ in
                ec.execute {
                    _ = f(self)
                }  // import `self` into the function in order to keep a strong
                // reference to self until after self will be completed.
                ct.unregister(cid)
            }
            cid = ct.onCancel(on: GCDBarrierAsyncExecutionContext(Sync.sync_queue)) {
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
    
    
    public final func continueWith<U>(
        ec ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: FutureBaseType throws -> U)
        -> Future<U>
    {
        // Caution: the mapping function must be called even when the returned
        // future has been deinitialized prematurely!
        let returnedFuture = Future<U>()
        _continueWith(on: ec, cancellationToken: ct) { [weak returnedFuture] (future) in
            let result = Result<U>({try f(future)})
            returnedFuture?.complete(result)
        }
        return returnedFuture
    }
    

    public final func continueWith<U>(
        ec ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: (FutureBaseType) -> Future<U>)
        -> Future<U>
    {
        // Caution: the mapping function must be called even when the returned
        // future has been deinitialized prematurely!
        let returnedFuture = Future<U>()
        _continueWith(on: ec, cancellationToken: ct) { [weak returnedFuture] future in
            let mappedFuture = f(future)
            returnedFuture?.completeWith(mappedFuture)
        }
        return returnedFuture
    }

    
}

// MARK: Extension CustomStringConvertible


extension Future : CustomStringConvertible {
    
    /**
     - returns: A description of `self`.
     */
    public var description: String {
        var s: String = ""
        Sync.readSyncSafe { /*[unowned(unsafe) self] in */
            var stateString: String
            if let res = self._result {
                switch res {
                case .Failure(let error): stateString = "Failed with: \(String(error))"
                case .Success(let value): stateString = "Succeeded with: \(String(value))"
                }
            }
            else {
                stateString = "Pending with \(self._cr.count) continuations."
            }
            s = "future<\(T.self)> \(stateString)"
        }
        return s
    }
    
    
}



// MARK: Extension DebugPrintable



extension Future : CustomDebugStringConvertible {

    /**
     - returns: A description of `self`.
    */
    public var debugDescription: String {
        var s: String = ""
        Sync.readSyncSafe { /*[unowned(unsafe) self] in */
            var stateString: String
            if let res = self._result {
                switch res {
                case .Failure(let error): stateString = "Failed with: \(String(reflecting: error))"
                case .Success(let value): stateString = "Succeeded with: \(String(reflecting: value))"
                }
            }
            else {
                stateString = "Pending with \(self._cr.count) continuations."
            }
            s = "future<\(T.self)> id: \(self.id) \(stateString)"
        }
        return s
    }


}




internal final class RootFuture<T> : Future<T> {
    
    typealias nullary_func = () -> ()
    
    final internal var onRevocation: nullary_func?
    
    
    internal override init() {
        super.init()
    }
    
    internal override init(value: T) {
        super.init(value: value)
    }
    
    internal override init(error: ErrorType) {
        super.init(error: error)
    }
    
    deinit {
        // Caution: deinit might be called on the synchroninization context Future.Sync!
        if let f = onRevocation {
            if _result == nil {
                dispatch_async(dispatch_get_global_queue(0, 0), f)
            }
        }
    }
    
}

