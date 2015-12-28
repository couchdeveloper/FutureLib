//
//  SequenceTypeWithFutureTypeExtension.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch






extension SequenceType  {
    
    /**
     Transforms a Sequence of T's into a `Future<[U]>` using the provided task
     function `T -> Future<U>` which is applied to each element in `self`.
     
     This is useful for performing a parallel map. For example, apply a function 
     to all items of a sequence concurrently:
     
     ```swift
     let values = [a, b, c]
     func task(input: T) -> Future<[U]>
     values.traverse(task) { output in
         // output is an array of U's
     }
     ```
     The method completes when all values have been computed. If any of the tasks
     fails, the returned future will be completed with this error after the
     previous tasks have been completed.
     
     The tasks are scheduled for execution to the given execution context. The
     execution context is used to set concurrency constraints. For example, the
     execution context may define the maximum number of concurrent tasks.
     
     
     - parameter ec: The execution context where the task `task` will be scheduled 
                     for execution
     - parameter ct: A cancellation token.
     - parameter task: A closure which is applied to each element in `self`.
     
     */
    public func traverse<U>(
        ec ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        task: Generator.Element -> Future<U>)
        -> Future<[U]>
    {        
        typealias FutureArrayFuture = Future<[Future<U>]>
        let initial: FutureArrayFuture = FutureArrayFuture(value: [Future<U>]())
        let ffutures = self.reduce(initial) {(combined, element) -> FutureArrayFuture in
            combined.flatMap(ct: ct) { combinedValue in
                ec.schedule { task(element) }.map { future  in
                    combinedValue + [future]
                }
            }
        }
        return ffutures.flatMap(ct: ct) { futures in
            futures.sequence(ct: ct)
        }
            
    }
    

    
}


// Note: specialize SequenceType whose Generator.Element is FutureType and where FutureType.ResultType is Result<Generator.Element.ValueType>
// This "imports" specializations defined in protocol extension FutureType where ResultType == Result<ValueType>
extension SequenceType
    where Generator.Element: FutureType,
    Generator.Element.ResultType == Result<Generator.Element.ValueType>
{
    
    /**
     For a sequence of futures `Future<T>` returns a new future `Future<U>` 
     completed with the result of the function `combine` repeatedly applied to 
     the success value for each future in `self` and the accumulated value 
     initialized with `initial`.
    
     That is, it transforms a `SequenceOf<Future<T>>` into a `Future<U>` whose
     result is the combined value of the success values of each future.
     
     The `combine` method will be called asynchronously in order with the futures
     in `self` once it has been completed with success. Note that the future's
     underlying task will execute concurrently with each other and may complete
     in any order.
     
     The returned future will be completed with success when all futures in `self`
     have been completed and combined successfully. If any of the future fails,
     the returned future will be completed with this error after the previous
     futures have been completed.
    */
    public func fold<U>(ec ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        initial: U,
        combine: (U, Generator.Element.ValueType) throws -> U)
        -> Future<U>
    {
        return self.reduce(Future.succeeded(initial)) { (combined, element) -> Future<U> in
            return combined.flatMap(ec: SynchronousCurrent(), ct: ct) { (combinedValue) -> Future<U> in
                return element.map(ec: ec, ct: ct) { (elementValue) -> U in
                    return try combine(combinedValue, elementValue)
                }
            }
        }
    }
    
    
    /**
     For a sequence of futures `Future<T>` returns a new future `Future<[T]>`
     which is completed with an array of `T`, where each element in the array 
     is the success value of the corresponding future in `self` in the same order.
     */
    public func sequence(ct ct: CancellationTokenType = CancellationTokenNone())
        -> Future<[Generator.Element.ValueType]>
    {
        return fold(ec: SynchronousCurrent(), ct: ct, initial: ()) { _,_ -> Void in }
        .map {
            return self.map {
                if let r = $0.result {
                    switch r {
                    case .Success(let v): return v
                    case .Failure: fatalError()
                    }
                }
                else {
                    fatalError()
                }
            }
        }
    }
    

    internal func sequence2(ct ct: CancellationTokenType = CancellationTokenNone())
        -> Future<[Generator.Element.ValueType]>
    {
        typealias U = Generator.Element.ValueType
        return self.fold(ec: SynchronousCurrent(), ct: ct, initial: [U]()) { (a, element) -> [U] in
            return a + [element]  // TODO: check performance: multiple copies.
        }
    }
    
    

    
    /**
     Given a sequence of `Future<T>`s, the method `result` returns a new future 
     which is completed with an array of `Result<T>`, where each element in the 
     array corresponds to the result of the future in `self` in the same order.
     */
    public func results(ct ct: CancellationTokenType = CancellationTokenNone())
        -> Future<[Generator.Element.ResultType]>
    {
        return self.reduce(Future<Void>.succeeded()) { (combinedFuture, elementFuture) -> Future<Void> in
            return combinedFuture.continueWith(ec: SynchronousCurrent(), ct: ct) { _ in
                return elementFuture.continueWith(ec: SynchronousCurrent(), ct: ct) { _ -> Void in
                }
            }
        }
        .map { self.map { $0.result! }  }
    }
    
    
}





    /**
     Returns a new future which will be completed with an array of result
     when all futures in `sequence` have been completed:
     ```S<Future<T>> -> Future<[Result<T>]>```
     
     - parameter cancellationToken: A cancellation token which will be monitored.
     - returns: A Future whose `ValueType` is an array of results which equals
     each futures's result in `sequence` in the same order.
     */
//    public func results(
//        cancellationToken ct: CancellationTokenType)
//        -> Future<[ResultType]>
//    {
//        let returnedFuture = Future<[ResultType]>()
//        return returnedFuture
//    }
//    {
//        let promise = Promise<[Result<T>]>()
//        s.onComplete(cancellationToken: ct) { results -> Void in
//            promise.resolve(Result(results))
//        }
//        return promise.future!
//    }

    
    
    
    /**
     Returns a new future which will be completed with an array of the success
     values when all futures in `sequence` have been completed:
     ```S<Future<T>> -> Future<[T]>```
     
     - parameter cancellationToken: A cancellation token which will be monitored.
     - returns: A Future whose `ValueType` is an array of results which equals
     each futures's result in `sequence` in the same order.
     */
//    public func sequence(
//        cancellationToken ct: CancellationTokenType)
//        -> Future<[ValueType]>
//    {

        
//        let ec = GCDAsyncExecutionContext(dispatch_queue_create("FutureLib.sequence.serial_queue", DISPATCH_QUEUE_SERIAL))
//        let promise = Promise<[T]>()
//        var values: [T]? = nil
//        var count = 0
//        dispatch_async(ec.queue) {
//            count = s._forEach(on: ec, cancellationToken: ct) { (idx, result) -> Void in
//                switch result {
//                case .Success(let value):
//                    if idx == 0 { values = [T](); values!.reserveCapacity(count) }
//                    values!.append(value)
//                case .Failure(let error):
//                    promise.reject(error)
//                    values = nil
//                }
//                
//                if count == idx+1 && values != nil{
//                    promise.fulfill(values!)
//                }
//            }
//        }
//        return promise.future!
//    }
    
    
    /**
     Returns a new future which will be completed with an array of results when
     all futures in `self` have been completed.
     - returns a Future whose `ValueType` is an array of results which equals
     each futures's result in `self` in the same order.
     */
//    public static func sequence<T, S: SequenceType where S.Generator.Element: FutureType, T == S.Generator.Element.ValueType>(
//        sequence s: S)
//        -> Future<[T]>
//    {
//        return sequence(sequence: s, cancellationToken: CancellationTokenNone())
//    }
 

    /**
     Returns a new future which will be completed with an array of results when
     all futures in `sequence` have been completed.
     - returns a Future whose `ValueType` is an array of results which equals
     each futures's result in `sequence` in the same order.
     */
//    public static func results<T, S: SequenceType where S.Generator.Element: FutureType, T == S.Generator.Element.ValueType>(
//        sequence s: S)
//        -> Future<[Result<T>]>
//    {
//        return results(sequence: s, cancellationToken: CancellationTokenNone())
//    }
 
    
    
    // MARK: onComplete

    /**
     Calls the continuation `f` when _all_ futures in `self` are completed.
     
     - parameter on: An asynchronous execution context where `f` will be executed.
     - parameter cancellationToken: A cancellation token which will be monitored.
     - parameter f: A completion closure whose parameter is an array of results
                    each corresponding to the future in `self` in the same order. 
                    The return value is not used.
     */
//    private func onComplete<U>(on ec: ExecutionContext, cancellationToken ct: CancellationTokenType, f: [ResultType] -> U)
//    {
//        let sync_queue = dispatch_queue_create("private sync queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0))
//        let private_ec = GCDAsyncExecutionContext(sync_queue)
//        private_ec.execute {
//            var count = 0
//            for future in self {
//                ++count
//                future.onComplete(on: private_ec, cancellationToken: ct) { r in
//                    if --count == 0 {
//                        let results = self.map {$0.result!}
//                        ec.execute {
//                            f(results)
//                        }
//                    }
//                }
//            }
//        }
//    }
 
    
//    /**
//     Calls the continuation `f` when _all_ futures in `self` are completed.
//     
//     - parameter cancellationToken: A cancellation token which will be monitored.
//     - parameter f: A completion closure whose parameter is an array of results
//     each corresponding to the future in `self` in the same order.
//     The return value is not used.
//     */
//    private func onComplete<U>(cancellationToken ct: CancellationTokenType, f: [ResultType] -> U)
//    {
//        return onComplete(on: GCDAsyncExecutionContext(), cancellationToken: ct, f: f)
//    }
//    
//    
//    /**
//     Calls the continuation `f` when _all_ futures in `self` are completed.
//     
//     - parameter on: An asynchronous execution context where `f` will be executed.
//     - parameter f: A completion closure whose parameter is a sequence of results
//     each corresponding to the future in `self` in the same order.
//     The return value is not used.
//     */
//    private func onComplete<U>(on ec: ExecutionContext, f: [ResultType] -> U)
//    {
//        return onComplete(on: ec, cancellationToken: CancellationTokenNone(), f: f)
//    }
//    
//    
//    /**
//     Calls the continuation `f` when _all_ futures in `self` are completed.
//     
//     - parameter f: A completion closure whose parameter is a sequence of results
//     each corresponding to the future in `self` in the same order.
//     The return value is not used.
//     */
//    private func onComplete<U>(f: [ResultType] -> U) {
//        return onComplete(on: GCDAsyncExecutionContext(), cancellationToken: CancellationTokenNone(), f: f)
//    }
 
    



    
//    /**
//     Asynchronously calls the closure `f` for each completed future's result in order.
//     
//     - Note:  
//     If a cancellation has been requested, the the completion closure `f` will be
//     immediately called with a `CancellationError.Cancelled` for all remainig
//     pending futures.
//     
//     - parameter on: An asynchronous execution context where `f` will be executed.
//     - parameter cancellationToken: A cancellation token which will be monitored.
//     - parameter f: A completion closure whose parameter is a tuple whose first
//     value equals the index of the element and whose second value is the result
//     of the corresponding future. The return value is not used.
//    */
//    private func forEach<U>(
//        on ec: ExecutionContext,
//        cancellationToken ct: CancellationTokenType,
//        f: (Int, ResultType) -> U)
//    {
//        _forEach(on: ec, cancellationToken: ct, f: f)
//    }
//    
//    
//    /**
//     Asynchronously calls the closure `f` for each completed future's result in order.
//     
//     - Note:
//     If a cancellation has been requested, the the completion closure `f` will be
//     immediately called with a `CancellationError.Cancelled` for all remainig
//     pending futures.
//     
//     - parameter cancellationToken: A cancellation token which will be monitored.
//     - parameter f: A completion closure whose parameter is a tuple whose first
//     value equals the index of the element and whose second value is the result
//     of the corresponding future. The return value is not used.
//     */
//    private func forEach<U>(
//        cancellationToken ct: CancellationTokenType,
//        f: (Int, ResultType) -> U)
//    {
//        _forEach(on: GCDAsyncExecutionContext(), cancellationToken: ct, f: f)
//    }
//    
//    
//    /**
//     Asynchronously calls the closure `f` for each completed future's result in order.
//     
//     - parameter on: An asynchronous execution context where `f` will be executed.
//     - parameter f: A completion closure whose parameter is a tuple whose first
//     value equals the index of the element and whose second value is the result
//     of the corresponding future. The return value is not used.
//     */
//    private func forEach<U>(
//        on ec: ExecutionContext,
//        f: (Int, ResultType) -> U)
//    {
//        _forEach(on: ec, cancellationToken: CancellationTokenNone(), f: f)
//    }
//    
//    
//    /**
//     Asynchronously calls the closure `f` for each completed future's result in order.
//     
//     - parameter f: A completion closure whose parameter is a tuple whose first
//     value equals the index of the element and whose second value is the result
//     of the corresponding future. The return value is not used.
//     */
//    private func forEach<U>(f: (Int, ResultType) -> U) {
//        _forEach(on: GCDAsyncExecutionContext(), cancellationToken: CancellationTokenNone(), f: f)
//    }
//    
//    
//
//    
//    /**
//     Asynchronously calls the closure `f` for each completed future's result in order.
//     
//     - Note: 
//     If a cancellation has been requested, the the completion closure `f` will be
//     immediately called with a `CancellationError.Cancelled` for all remainig 
//     pending futures.
//     
//     - parameter on: An asynchronous execution context where `f` will be executed.
//     - parameter cancellationToken: A cancellation token which will be monitored.
//     - parameter f: A completion closure whose parameter is a tuple whose first
//     - returns: The number of elements in the sequence
//     value equals the index of the element and whose second value is the result
//     of the corresponding future. The return value is not used.
//     */
//    private func _forEach<U>(
//        on ec: ExecutionContext,
//        cancellationToken ct: CancellationTokenType,
//        f: (Int, ResultType) -> U)
//        -> Int
//    {
//        //let queue = dispatch_queue_create("FutureLib.foreach.serial_queue", DISPATCH_QUEUE_SERIAL)
//        let g0 = dispatch_group_create()
//        dispatch_group_enter(g0)
//        var g_prev = g0
//        var count = 0
//        for (i, future) in self.enumerate() {
//            ++count
//            let g = dispatch_group_create()
//            dispatch_group_enter(g)
//            let gp = g_prev
//            future.onComplete(on: SynchronousCurrent(), cancellationToken: ct) { [i] result in
//                dispatch_group_notify(gp, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) { [g,i]
//                    ec.execute {
//                        f(i, result)
//                    }
//                    dispatch_group_leave(g)
//                }
//            }
//            g_prev = g
//        }
//        dispatch_group_leave(g0)
//        return count
//    }
//    
//    
//    /**
//     Returns a new future whose `ValueType` is an array of values of type `U` which
//     are the result of the mapping function `f` for each future in `self`.
//
//     - Note:
//     The mapping function will be called for _each_ future which has
//     been successfully completed, regardless whether a mapping function throws
//     and completes the new future with an error prematurely.
//
//     - parameter cancellationToken: A cancellation token which will be monitored.
//     - returns: A Future whose `ValueType` is a sequence of results which equals
//     each futures's result in `self` in the same order.
//     */
//    private func map<U>(
//        on ec: ExecutionContext = GCDAsyncExecutionContext(),
//        cancellationToken ct: CancellationTokenType = CancellationTokenNone(),
//        f: ValueType throws -> U)
//        -> Future<[U]>
//    {
//        var values: [U]? = [U]()
//        let returnedFuture = Future<[U]>()
//        var count = 0
//        count = _forEach(on: SynchronousCurrent(), cancellationToken: ct) { (index, result) in
//            do {
//                let v = try f(try result.value())
//                if values != nil {
//                    if index == 0 { values!.reserveCapacity(count) }
//                    values!.append(v)
//                    if index == count - 1 {
//                        returnedFuture.complete(Result(values!))
//                    }
//                }
//            }
//            catch let error {
//                if values != nil {
//                    returnedFuture.complete(Result<[U]>(error: error))
//                    values = nil
//                }
//            }
//        }
//        return returnedFuture
//    }
//    
//    
//    
//    
//    
//    
//    
//    private func onFirstSuccess<U>(
//        on ec: ExecutionContext = GCDAsyncExecutionContext(),
//        cancellationToken: CancellationTokenType = CancellationTokenNone(),
//        f: (Int, ResultType) -> U)
//    {
//        let cr = CancellationRequest()
//        let ct = cr.token
//        let cid = cancellationToken.onCancel {
//            cr.cancel()
//        }
//        let sync_queue = dispatch_queue_create("private sync queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0))
//        let private_ec = GCDAsyncExecutionContext(sync_queue)
//        var count = 0
//        private_ec.execute {
//            for (i, future) in self.enumerate() {
//                ++count
//                future.onComplete(on: private_ec, cancellationToken: ct) { r in
//                    switch (r) {
//                    case .Success:
//                        // It is ensured that the given closure will be called only once by asking the cr.
//                        if !cr.isCancellationRequested {
//                            ec.execute {
//                                f(i, r)
//                            }
//                            cr.cancel()
//                            
//                        }
//                        break
//                    case .Failure: break
//                    }
//                    if --count == 0 {
//                        cancellationToken.unregister(cid)
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    private func onFirstFailure<U>(
//        on ec: ExecutionContext = GCDAsyncExecutionContext(),
//        cancellationToken: CancellationTokenType = CancellationTokenNone(),
//        f: [ResultType] -> U)
//    {
//        fatalError("not yet implemented")
//    }
//    
//    
//    
//    private func whenFirstSuccess<U>(
//        on ec: ExecutionContext = GCDAsyncExecutionContext(),
//        cancellationToken: CancellationTokenType = CancellationTokenNone(),
//        f: [ResultType] -> U)
//        -> Future<U>
//    {
//        let returnedFuture = Future<U>()
//        fatalError("not yet implemented")
//        return returnedFuture
//    }
//    
//    
//    private func onFirstFailure<U>(
//        on ec: ExecutionContext = GCDAsyncExecutionContext(),
//        cancellationToken: CancellationTokenType = CancellationTokenNone(),
//        f: [ResultType] -> U)
//        -> Future<U>
//    {
//        let returnedFuture = Future<U>()
//        fatalError("not yet implemented")
//        return returnedFuture
//    }
//    
//    
//}
//
//
//
//
//extension SequenceType where Generator.Element == FutureBaseType {
//    
//    /**
//     Calls the continuation `f` when _all_ futures in `self` are completed.
//     
//     - parameter on: An asynchronous execution context where `f` will be executed.
//     - parameter cancellationToken: A cancellation token which will be monitored.
//     - parameter f: A completion closure with signature `Self -> U` which will be called when all furures are completed with `self` as the argument.
//
//    The return value is not used.
//     */
//    private func _continueWith<U>(
//        on ec: ExecutionContext,
//        cancellationToken ct: CancellationTokenType,
//        f: (Self, CancellationTokenType) -> U)
//    {
//        let sync_queue = dispatch_queue_create("private sync queue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0))
//        let private_ec = GCDAsyncExecutionContext(sync_queue)
//        private_ec.execute {
//            var count = 0
//            for future in self {
//                ++count
//                future.continueWith(on: private_ec, cancellationToken: ct) { _ in
//                    if --count == 0 {
//                        ec.execute {
//                            f(self, ct)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    /**
//     Returns a new future with the result of the mapping function `f` applied to
//     the tuple (`self`, ct) which is called when _all_ futures in `self` have been
//     completed. `self` is passed as a `Self` and `ct` is the cancellation
//     token given in the parameters. If the mapping function throws an error the 
//     returned future will be completed with the same error.
//     
//     If the cancellation token is already cancelled or if it will be cancelled
//     before all futures in `self` have been completed, the returned future will
//     be completed with a `CancellationError.Cancelled` error. Note that cancelling
//     a continuation will not complete any future in `self`! Instead the mapping
//     function `f` will be "unregistered" and called with a tuple `self` and the
//     cancelled `ct` as its argument. Otherwise, executes the closure `f` when all
//     futures in `self` are completed passing a tuple of the completed `self` and
//     the cancellation token as the argument.
//     
//     When the continuation will be called, it is exectuded on the given execution
//     context.
//     
//     The method retains `self` until it is completed or all continuations have
//     been unregistered. If there are no other strong references and all continuations
//     have been unregistered, `self` is being deinitialized.
//     
//     - parameter on: The execution context where the function `f` will be executed.
//     - parameter cancellationToken: A cancellation token.
//     - parameter f: A closure with signature `(Self, CancellationTokenType) throws -> U` which
//                    will be called with a tupe `(self, ct)` as its argument.
//     */
//    public func continueWith<U>(
//        on ec: ExecutionContext,
//        cancellationToken ct: CancellationTokenType,
//        f: (Self, CancellationTokenType) throws -> U)
//    -> Future<U>
//    {
//        let promise = Promise<U>()
//        self._continueWith(on: ec, cancellationToken: ct) { (sequence, ct) in
//            do {
//                let value = try f(self, ct)
//                promise.fulfill(value)
//            }
//            catch let error {
//                promise.reject(error)
//            }
//        }
//        return promise.future!
//    }
//    
//    
//    
//    /**
//     Returns a new future with the deferred result of the mapping function `f` 
//     applied to the tuple (`self`, ct) which is called when _all_ futures in 
//     `self` have been completed. `self` is passed as a `Self` and `ct` is the 
//     cancellation token given in the parameters.
//     
//     If the cancellation token is already cancelled or if it will be cancelled
//     before all futures in `self` have been completed, the returned future will
//     be completed with a `CancellationError.Cancelled` error. Note that cancelling
//     a continuation will not complete any future in `self`! Instead the mapping
//     function `f` will be "unregistered" and called with a tuple `self` and the
//     cancelled `ct` as its argument. Otherwise, executes the closure `f` when all 
//     futures in `self` are completed passing a tuple of the completed `self` and 
//     the cancellation token as the argument.
//     
//     When the continuation will be called, it is exectuded on the given execution
//     context.
//     
//     The method retains `self` until it is completed or all continuations have
//     been unregistered. If there are no other strong references and all continuations
//     have been unregistered, `self` is being deinitialized.
//     
//     - parameter on: The execution context where the function `f` will be executed.
//     - parameter cancellationToken: A cancellation token.
//     - parameter f: A closure with signature `(Self, CancellationTokenType) -> Future<U>` which
//     will be called with a tupe `(self, ct)` as its argument.
//     */
//    public func continueWith<U>(
//        on ec: ExecutionContext,
//        cancellationToken ct: CancellationTokenType,
//        f: (Self, CancellationTokenType) -> Future<U>)
//        -> Future<U>
//    {
//        // Caution: the mapping function must be called even when the returned
//        // future has been deinitialized prematurely!
//        let returnedFuture = Future<U>()
//        _continueWith(on: SynchronousCurrent(), cancellationToken: ct) { [weak returnedFuture] (future, ct) in
//            let mappedFuture = f(future, ct)
//            returnedFuture?.complete(mappedFuture)
//        }
//        return returnedFuture
//    }
//    
//    
//    
//    
//    /**
//     Returns a new future with the result of the mapping function `f` applied to
//     `self` which is called when _all_ futures in `self` have been completed. 
//     If the mapping function throws an error the returned future will be completed 
//     with the same error.
//     
//     When the continuation will be called, it is exectuded on the given execution
//     context.
//     
//     The method retains `self` until it is completed or all continuations have
//     been unregistered. If there are no other strong references and all continuations
//     have been unregistered, `self` is being deinitialized.
//     
//     - parameter on: The execution context where the function `f` will be executed.
//     - parameter cancellationToken: A cancellation token.
//     - parameter f: A closure with signature `Self throws -> U` which
//     will be called with `self` as its argument.
//     */
//    public func continueWith<U>(on ec: ExecutionContext, f: Self throws -> U) -> Future<U> {
//        return self.continueWith(on: ec, cancellationToken: CancellationTokenNone(), f: { (sequence, _) -> U in
//            return try f(sequence)
//        })
//    }
//    
//    /**
//     Returns a new future with the result of the mapping function `f` applied to
//     `self` which is called when _all_ futures in `self` have been completed.
//     If the mapping function throws an error the returned future will be completed
//     with the same error.
//     
//     When the continuation will be called, it is exectuded on a private execution
//     context.
//     
//     The method retains `self` until it is completed or all continuations have
//     been unregistered. If there are no other strong references and all continuations
//     have been unregistered, `self` is being deinitialized.
//     
//     - parameter f: A closure with signature `Self throws -> U` which
//     will be called with `self` as its argument.
//     */
//    public func continueWith<U>(f: Self throws -> U) -> Future<U> {
//        return self.continueWith(on: GCDAsyncExecutionContext(), cancellationToken: CancellationTokenNone()) { sequence, _ in
//            return try f(sequence)
//        }
//    }
//    
//    
//    
//    /**
//     Returns a new future with the result of the mapping function `f` applied to
//     the tuple (`self`, ct) which is called when _all_ futures in `self` have been
//     completed. `self` is passed as a `Self` and `ct` is the cancellation
//     token given in the parameters. If the mapping function throws an error the
//     returned future will be completed with the same error.
//     
//     If the cancellation token is already cancelled or if it will be cancelled
//     before all futures in `self` have been completed, the returned future will
//     be completed with a `CancellationError.Cancelled` error. Note that cancelling
//     a continuation will not complete any future in `self`! Instead the mapping
//     function `f` will be "unregistered" and called with a tuple `self` and the
//     cancelled `ct` as its argument. Otherwise, executes the closure `f` when all
//     futures in `self` are completed passing a tuple of the completed `self` and
//     the cancellation token as the argument.
//     
//     When the continuation will be called, it is exectuded on a private execution
//     context.
//     
//     The method retains `self` until it is completed or all continuations have
//     been unregistered. If there are no other strong references and all continuations
//     have been unregistered, `self` is being deinitialized.
//     
//     - parameter cancellationToken: A cancellation token.
//     - parameter f: A closure with signature `(Self, CancellationTokenType) throws -> U` which
//     will be called with a tupe `(self, ct)` as its argument.
//     */
//    public func continueWith<U>(cancellationToken ct: CancellationTokenType, f: (Self, CancellationTokenType) throws -> U) -> Future<U> {
//        return self.continueWith(on: GCDAsyncExecutionContext(), cancellationToken: ct, f: f)
//    }
//    
//    
//    
//    
//    
//    /**
//     Returns a new future with the deferred result of the mapping function `f`
//     applied to `self` which is called when _all_ futures in `self` have been 
//     completed.
//     
//     When the continuation will be called, it is exectuded on the given execution
//     context.
//     
//     The method retains `self` until it is completed or all continuations have
//     been unregistered. If there are no other strong references and all continuations
//     have been unregistered, `self` is being deinitialized.
//     
//     - parameter on: The execution context where the function `f` will be executed.
//     - parameter f: A closure with signature `Self -> Future<U>` which
//     will be called with `self` as its argument.
//     */
//    public func continueWith<U>(on ec: ExecutionContext, f: Self -> Future<U>) -> Future<U> {
//        return self.continueWith(on: ec, cancellationToken: CancellationTokenNone()) { sequence, _ in
//            return f(sequence)
//        }
//    }
//    
//
//    /**
//     Returns a new future with the deferred result of the mapping function `f`
//     applied to `self` which is called when _all_ futures in `self` have been
//     completed.
//     
//     When the continuation will be called, it is exectuded on a private execution
//     context.
//     
//     The method retains `self` until it is completed or all continuations have
//     been unregistered. If there are no other strong references and all continuations
//     have been unregistered, `self` is being deinitialized.
//     
//     - parameter f: A closure with signature `Self -> Future<U>` which
//     will be called with `self` as its argument.
//     */
//    public func continueWith<U>(f: Self -> Future<U>) -> Future<U> {
//        return self.continueWith(on: GCDAsyncExecutionContext(), cancellationToken: CancellationTokenNone()) { sequence, _ in
//            return f(sequence)
//        }
//    }
//    
//    
//    
//    /**
//     Returns a new future with the deferred result of the mapping function `f`
//     applied to the tuple (`self`, ct) which is called when _all_ futures in
//     `self` have been completed. `self` is passed as a `Self` and `ct` is the
//     cancellation token given in the parameters.
//     
//     If the cancellation token is already cancelled or if it will be cancelled
//     before all futures in `self` have been completed, the returned future will
//     be completed with a `CancellationError.Cancelled` error. Note that cancelling
//     a continuation will not complete any future in `self`! Instead the mapping
//     function `f` will be "unregistered" and called with a tuple `self` and the
//     cancelled `ct` as its argument. Otherwise, executes the closure `f` when all
//     futures in `self` are completed passing a tuple of the completed `self` and
//     the cancellation token as the argument.
//     
//     When the continuation will be called, it is exectuded on a private execution
//     context.
//     
//     The method retains `self` until it is completed or all continuations have
//     been unregistered. If there are no other strong references and all continuations
//     have been unregistered, `self` is being deinitialized.
//     
//     - parameter cancellationToken: A cancellation token.
//     - parameter f: A closure with signature `(Self, CancellationTokenType) -> Future<U>` which
//     will be called with a tupe `(self, ct)` as its argument.
//     */
//    public func continueWith<U>(cancellationToken ct: CancellationTokenType, f: (Self, CancellationTokenType) -> Future<U>) -> Future<U> {
//        return self.continueWith(on: GCDAsyncExecutionContext(), cancellationToken: ct, f: f)
//    }
//    
//
//
//
//
//}
