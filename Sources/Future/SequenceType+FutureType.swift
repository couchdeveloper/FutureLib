//
//  SequenceTypeWithFutureTypeExtension.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch

extension Sequence {

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
        ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        task: (Iterator.Element) throws -> Future<U>)
        -> Future<[U]> {
        typealias FutureArrayFuture = Future<[Future<U>]>
        let initial: FutureArrayFuture = FutureArrayFuture(value: [Future<U>]())
        let ffutures = self.reduce(initial) {(combined, element) -> FutureArrayFuture in
            combined.flatMap(ct: ct) { combinedValue in
                ec.schedule { try task(element) }.map { future  in
                    combinedValue + [future]
                }
            }
        }
        return ffutures.flatMap(ct: ct) { futures in
            futures.sequence(ct: ct)
        }

    }

}


// Note: specialize SequenceType whose Generator.Element is FutureType and where
// FutureType.ResultType is Try<Generator.Element.ValueType>
// This "imports" specializations defined in protocol extension FutureType where
// ResultType == Try<ValueType>
extension Sequence
    where Iterator.Element: FutureType,
    Iterator.Element.ResultType == Try<Iterator.Element.ValueType> {

    typealias T = Iterator.Element.ValueType
    
    /** 
     Returns a `Future` that will be completed with the optional result of the 
     first `Future` whose result matches the predicate. Failed `Future`s will be 
     ignored. If a cancellation has been requested, the future will be completed
     with a `CancellationError.Cancelled`.
     If no match has been found, returns a future which is completed
     with `.None`.
    
     - parameter pred: The predicate which indicates if it's a match.
     - returns: A `Future` holding the optional result of the search.
    */
    public func find(
        _ ec: ExecutionContext = ConcurrentAsync(), 
        ct: CancellationTokenType = CancellationTokenNone(),
        pred: (T) -> Bool) -> Future<T?> 
    {
        func searchNext(_ gen: inout Self.Iterator) -> Future<T?> {
            if let elem = gen.next() {
                return elem.transformWith(ec: ec, ct: ct) { result in 
                    switch result {
                    case .success(let value) where pred(value): return Future<T?>.succeeded(.some(value)) 
                    default:
                        if ct.isCancellationRequested {
                            return Future(error: CancellationError.cancelled)
                        } else {
                            return searchNext(&gen)
                        }
                    }
                }
            } else {
                return Future.succeeded(.none)
            }
        }
        var gen = self.makeIterator()
        return searchNext(&gen)
    }
    
    
    /** 
     Returns a new `Future` which will be completed with the result of the 
     first completed future in `self`.

     - parameter ct: A cancellation token.
     - returns: A `Future` holding the optional result of the search.
     */
    public func firstCompleted(
        _ ct: CancellationTokenType = CancellationTokenNone())
        -> Future<T> 
    {
        let promise = Promise<T>()
        let tryCompletePromise: (Try<T>) -> Void = { promise.tryResolve($0) }
        self.forEach { 
            $0.onComplete(ec: ConcurrentAsync(), ct: ct, f: tryCompletePromise) 
        }
        return promise.future!
    }
    
    
    
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

     - parameter ec: An execution context.
     - parameter initial: The initial value for the combine function.
     - parameter combine: The combine function.
     - returns: A future.
    */
    public func fold<U>(ec: ExecutionContext = ConcurrentAsync(),
        ct: CancellationTokenType = CancellationTokenNone(),
        initial: U,
        combine: (U, Iterator.Element.ValueType) throws -> U)
        -> Future<U> {
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
    
     - parameter ct: A cancellation token.
     - returns: A future.
     */
    public func sequence(ct: CancellationTokenType = CancellationTokenNone())
        -> Future<[Iterator.Element.ValueType]> {
        return fold(ec: SynchronousCurrent(), ct: ct, initial: ()) { _, _ -> Void in }
        .map {
            return self.map {
                if let r = $0.result {
                    switch r {
                    case .success(let v): return v
                    case .failure: fatalError()
                    }
                } else {
                    fatalError()
                }
            }
        }
    }


    internal func sequence2(ct: CancellationTokenType = CancellationTokenNone())
        -> Future<[Iterator.Element.ValueType]> {
        typealias U = Iterator.Element.ValueType
        return self.fold(ec: SynchronousCurrent(), ct: ct, initial: [U]()) { (a, element) -> [U] in
            return a + [element]  // TODO: check performance: multiple copies.
        }
    }




    /**
     Given a sequence of `Future<T>`s, the method `result` returns a new future
     which is completed with an array of `Try<T>`, where each element in the
     array corresponds to the result of the future in `self` in the same order.

     - parameter ct: A cancellation token.
     - returns: A future.
     */
    public func results(ct: CancellationTokenType = CancellationTokenNone())
        -> Future<[Iterator.Element.ResultType]> {
        return self.reduce(Future<Void>.succeeded()) { (combinedFuture, elementFuture) -> Future<Void> in
            return combinedFuture.continueWith(ec: SynchronousCurrent(), ct: ct) { _ in
                return elementFuture.continueWith(ec: SynchronousCurrent(), ct: ct) { _ -> Void in
                }
            }
        }
        .map { self.map { $0.result! }  }
    }


}
