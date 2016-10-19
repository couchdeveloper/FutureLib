//
//  Future.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


private let _sync = (0..<8).map { Synchronize(name: "future-sync-queue-\($0)") } 
private var _sync_id: Int32 = 0
    


// MARK: - Class Future

/**
 The generic class `Future`.

 A _future_ represents the _eventual result_ of an asynchronous task. In FutureLib
 a _result_ is commonly represented by the generic class `Try<T>`, which can
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
public class Future<T>: FutureType {

    public typealias ValueType = T
    public typealias ResultType = Try<ValueType>
    fileprivate typealias ClosureRegistryType = ClosureRegistry<ResultType>

    fileprivate var _result: Try<ValueType>?
    fileprivate var _cr: ClosureRegistryType = ClosureRegistryType() 
    internal let sync = _sync[Int(OSAtomicIncrement32(&_sync_id) % 7)] // Synchronize(name: "future-sync-queue-\(OSAtomicIncrement32(&_sync_id))")//


    /**
     Designatated initializer which creates a pending future.
    */
    internal init() {
        //Log.Debug("\(Thread.current): ")
    }
    
    deinit {
        //Log.Debug("\(Thread.current): ")
    }
    
    /**
     Designated initializer which creates a future completed with the given success value.
     - parameter value: The value which is bound to the completed `self`.
     */
    internal init(value: T) {
        _result = Try<ValueType>(value)
    }

    /**
     Designated initializer which creates a future completed with the given result.
     - parameter result: The result which is bound to the completed `self`.
     */
    internal init(result: ResultType) {
        _result = result
    }
    

    /**
     Designated initializer which creates a future completed with the given error.
     - parameter error: The error which is bound to the completed `self`.
    */
    internal init(error: Error) {
        _result = Try<ValueType>(error: error)
    }

    // deinit { }


    /**
     - returns: A unique Id representing `self`.
    */
    public final var id: UInt {
        return UInt(bitPattern: ObjectIdentifier(self))
    }


    /**
     If `self` is completed returns its result, otherwise it returns `nil`.

     - returns: an optional Try<T>
     */
    public final var result: Try<ValueType>? {
        var result: Try<ValueType>? = nil
        sync.readSync() {
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
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (Try<ValueType>) -> U) {
        sync.writeAsync {
            if ct.isCancellationRequested {
                ec.execute {
                    _ = f(Try<ValueType>(error: CancellationError()))
                }
                return
            }
            if let r = self._result {
                ec.execute {
                    _ = f(r)
                }
                return
            }
            var cid: EventHandlerIdType?
            let id = self._cr.register { result in
                assert(self.sync.isSynchronized())
                ec.execute {
                    _ = f(result)
                }  
                // import `self` into the closure in order to keep a strong
                // reference to self until after self will be completed:
                _ = self
                cid?.invalidate()
            }
            // TODO: Use GCDBarrierAsyncExecutionContext!
            cid = ct.onCancel(queue: self.sync.syncQueue) { 
                if let callback = self._cr.unregister(id) {
                    callback.continuation(Try<ValueType>(error: CancellationError()))
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
    public final func mapTo<S>(_ ct: CancellationTokenType = CancellationTokenNone())
        -> Future<S> {
        let returnedFuture = Future<S>()
        self.onComplete(ec: SynchronousCurrent(), ct: ct) { [weak returnedFuture] result in
            returnedFuture?.complete(result.map {
                guard case let mappedValue as S = $0 else { throw FutureError.invalidCast }
                return mappedValue
            })
        }
        return returnedFuture
    }


}



// MARK: CompletableFutureType

extension Future: CompletableFutureType {


    internal final func complete(_ result: ResultType) {
        sync.writeAsync {
            self._complete(result)
        }
    }

    internal final func complete(_ value: ValueType) {
        complete(ResultType(value))
    }

    internal final func complete(_ error: Error) {
        complete(ResultType(error: error))
    }

    @discardableResult
    internal final func tryComplete(_ result: ResultType) -> Bool {
        var ret = false
        sync.writeSync {
            ret = self._tryComplete(result)
        }
        return ret
    }


    @discardableResult
    internal final func _tryComplete(_ result: ResultType) -> Bool {
        assert(sync.isSynchronized())
        if _result == nil {
            _complete(result)
            return true
        }
        return false
    }

    internal final func _complete(_ result: ResultType) {
        assert(sync.isSynchronized())
        assert(self._result == nil)
        self._result = result
        _cr.resume(result)
        _cr = ClosureRegistryType.empty
    }

    internal final func _complete(_ value: ValueType) {
        _complete(ResultType(value))
    }

    internal final func _complete(_ error: Error) {
        _complete(ResultType(error: error))
    }

}




// MARK: Waitable

extension Future {

    /**
     Blocks the current thread until `self` is completed or if a cancellation
     has been requested.

     - parameter cancellationToken: A cancellation token which will be monitored by `self`.
     - returns:  `self`
     */
    @discardableResult    
    public final func wait(_ cancellationToken: CancellationTokenType) -> Self {

        // wait until completed or a cancellation has been requested
        let sem: DispatchSemaphore = DispatchSemaphore(value: 0)
        onComplete(ec: ConcurrentAsync(), ct: cancellationToken) { _ in
            sem.signal()
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture)
        return self
    }


    /**
     Blocks the current thread until `self` is completed.
     - returns: `self`
     */
    @discardableResult
    public final func wait() -> Self {
        // wait until completed or a cancellation has been requested
        let sem: DispatchSemaphore = DispatchSemaphore(value: 0)
        onComplete(ec: ConcurrentAsync(), ct: CancellationTokenNone()) { _ in
            sem.signal()
        }
        _ = sem.wait(timeout: DispatchTime.distantFuture)
        return self
    }

}



// MARK: Extension Future continueWith
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
        f: @escaping (FutureBaseType) -> U) {
        sync.writeAsync {
            if ct.isCancellationRequested {
                ec.execute {
                    _ = f(self)
                }
                return
            }
            if let _ = self._result {
                ec.execute {
                    _ = f(self)
                }
                return
            }
            var cid: EventHandlerIdType?
            let id = self._cr.register { _ in
                assert(self.sync.isSynchronized())
                ec.execute {
                    _ = f(self)
                }  
                _ = self
                // import `self` into the function in order to keep a strong
                // reference to self until after self will be completed.
                cid?.invalidate()
            }
            cid = ct.onCancel(queue: self.sync.syncQueue) { // TODO: Use GCDBarrierAsyncExecutionContext
                if let callback = self._cr.unregister(id) {
                    callback.continuation(Try<ValueType>(error: CancellationError()))
                }
            }
        }
    }


    public final func continueWith<U>(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (FutureBaseType) throws -> U)
        -> Future<U> {
        // Caution: the mapping function must be called even when the returned
        // future has been deinitialized prematurely!
        let returnedFuture = Future<U>()
        _continueWith(on: ec, cancellationToken: ct) { [weak returnedFuture] (future) in
            let result = Try<U>({try f(future)})
            returnedFuture?.complete(result)
        }
        return returnedFuture
    }


    public final func continueWith<U>(
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        f: @escaping (FutureBaseType) -> Future<U>)
        -> Future<U> {
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
extension Future: CustomStringConvertible {

    /**
     - returns: A description of `self`.
     */
    public var description: String {
        var s: String = ""
        sync.readSyncSafe { /*[unowned(unsafe) self] in */
            var stateString: String
            if let res = self._result {
                switch res {
                case .failure(let error): stateString = "Failed with: \(String(describing: error))"
                case .success(let value): stateString = "Succeeded with: \(String(describing: value))"
                }
            } else {
                stateString = "Pending with \(self._cr.count) continuations."
            }
            s = "future<\(T.self)> \(stateString)"
        }
        return s
    }


}



// MARK: Extension CustomDebugStringConvertible
extension Future: CustomDebugStringConvertible {

    /**
     - returns: A description of `self`.
    */
    public var debugDescription: String {
        var s: String = ""
        sync.readSyncSafe { /*[unowned(unsafe) self] in */
            var stateString: String
            if let res = self._result {
                switch res {
                case .failure(let error):
                    stateString = "Failed with: \(String(reflecting: error))"
                case .success(let value):
                    stateString = "Succeeded with: \(String(reflecting: value))"
                }
            } else {
                stateString = "Pending with \(self._cr.count) continuations."
            }
            s = "future<\(T.self)> id: \(self.id) \(stateString)"
        }
        return s
    }


}


internal final class RootFuture<T>: Future<T> {

    typealias nullary_func = () -> ()

    final internal var onRevocation: nullary_func?


    internal override init() {
        super.init()
    }

    internal override init(value: T) {
        super.init(value: value)
    }

    internal override init(error: Error) {
        super.init(error: error)
    }

    deinit {
        // Caution: deinit might be called on the synchroninization context Future.Sync!
        if let f = onRevocation {
            if _result == nil {
                DispatchQueue.global().async(execute: f)
            }
        }
    }
    
}

extension RootFuture: CustomPlaygroundQuickLookable  {
    
    internal var customPlaygroundQuickLook: PlaygroundQuickLook {
        return .text(String(describing: self))
    }
}



