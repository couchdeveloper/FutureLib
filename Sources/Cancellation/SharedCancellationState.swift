//
//  SharedCancellationState.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


private enum CancellationState {
    typealias ClosureRegistryType = ClosureRegistry<Bool>

    case Pending(ClosureRegistryType)
    case Completed(Bool)


    private init() {
        self = Pending(ClosureRegistryType())
    }


    private init(completed: Bool) {
        self = Completed(completed)
    }


    private var isCompleted: Bool {
        switch self {
        case .Completed: return true
        default: return false
        }
    }


    private var isCancelled: Bool {
        switch self {
        case .Completed(let v): return v
        default: return false
        }
    }


    private mutating func cancel() {
        switch self {
        case .Pending(let state):
            self = CancellationState(completed: true)
            state.resume(true)
        case .Completed: break
        }
    }


    private mutating func complete() {
        switch self {
        case .Pending(let state):
            self = CancellationState(completed: false)
            state.resume(false)
        case .Completed: break
        }
    }


    private mutating func register(f: (Bool)->()) -> Int {
        var result: Int = -1
        switch self {
        case .Pending(var cr):
            result = cr.register(f)
            self = .Pending(cr)

        case .Completed(let cancelled): f(cancelled)
        }
        return result
    }


    /**
     Unregister the closure previously registered with `register`.

     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    private func unregister(id: Int) {
        switch self {
        case .Pending(var cr):
            cr.unregister(id)
        default: break
        }
    }


}

private let syncQueue = dispatch_queue_create("cancellation.sync_queue", DISPATCH_QUEUE_SERIAL)

internal final class SharedCancellationState {

    private var value = CancellationState()


    final var isCompleted: Bool {
        var result = false
        dispatch_sync(syncQueue) {
            result = self.value.isCompleted
        }
        return result
    }


    final var isCancelled: Bool {
        var result = false
        dispatch_sync(syncQueue) {
            result = self.value.isCancelled
        }
        return result
    }


    final func cancel() {
        dispatch_async(syncQueue) {
            self.value.cancel()
        }
    }


    final func complete() {
        dispatch_async(syncQueue) {
            self.value.complete()
        }
    }


    /**
     Register a closure which will be called when `self` has been completed.

     - parameter on: An exdcution context where function `f` will be executed.
     - parameter f: The closure which will be executed.
     - returns: An id which represents the registered closure which can be used
     to unregister it again.
     */
    final func register(on executor: ExecutionContext, f: (Bool)->()) -> Int {
        var result = -1
        dispatch_sync(syncQueue) {
            result = self.value.register { cancelled in
                executor.execute {
                    f(cancelled)
                }
            }
        }
        return result
    }


    /**
     Unregister the closure previously registered with `register`.

     - parameter id: The `id` representing the closure which has been obtained with `onCancel`.
     */
    final func unregister(id: Int) {
        dispatch_async(syncQueue) {
            self.value.unregister(id)
        }
    }


    final func onCancel(on executor: ExecutionContext,
        cancelable: Cancelable,
        f: (Cancelable)->()) -> Int {
        var result: Int = -1
        dispatch_sync(syncQueue) {
            result = self.value.register { cancelled in
                if cancelled {
                    executor.execute {
                        f(cancelable)
                    }
                }
                self // keep a reference in order to prevent from prematurely
                     // deinitialization
            }
        }
        return result
    }


    final func onCancel(on executor: ExecutionContext, f: ()->()) -> Int {
        var result: Int = -1
        dispatch_sync(syncQueue) {
            result = self.value.register { cancelled in
                if cancelled {
                    executor.execute {
                        f()
                    }
                }
                self // keep a reference in order to prevent from prematurely
                     // deinitialization
            }
        }
        return result
    }



}
