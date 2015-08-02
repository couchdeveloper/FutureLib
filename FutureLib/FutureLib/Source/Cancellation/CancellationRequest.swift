//
//  CancellationRequest.swift
//  Future
//
//  Created by Andreas Grosam on 27.03.15.
//  Copyright (c) 2015 Andreas Grosam. All rights reserved.
//

import Dispatch
import Darwin



/// Initialize and configure a Logger - mainly for debugging and testing
#if DEBUG
    private let Log = Logger(category: "CancellationRequest", verbosity: Logger.Severity.Debug)
    #else
    private let Log = Logger(category: "CancellationRequest", verbosity: Logger.Severity.Error)
#endif



private let sync_queue = dispatch_queue_create("cancellation.sync_que", DISPATCH_QUEUE_SERIAL)



internal class SharedState {
    private var _state : Int32 = 0
    
    internal final var isCompleted : Bool {
        return OSAtomicCompareAndSwap32(1,1, &_state)
    }
    
    internal final func complete() -> Bool {
        return OSAtomicCompareAndSwap32(0, 1, &_state)
    }
}





/**
    A CancellationRequest is a means to let clients signal a task which they initiated,
    that they are no more interested in the result. The task will be notified about the
    cancellation request signaled by its client and may now cancel its operation.
*/
public class CancellationRequest  {
    
    
    private var _queue : dispatch_queue_t? = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL)
    private let _sharedState = SharedState()
    
    /**
        Designated initializer. Initializes a CancellationRequest object.
    */
    public init() {
        dispatch_suspend(_queue!)
    }

    deinit {
        if let q = self._queue {
            dispatch_resume(q)
        }
    }
    
    internal final var sharedState : SharedState {
        return _sharedState
    }
    

    /**
        Returns a unique Id where this object can be identified.
    */
    public var id: UInt {
        return ObjectIdentifier(self).uintValue
    }
    
    
    /**
        Returns true if a cancellation has been requested.
    */
    public final var isCancellationRequested : Bool {
        return _sharedState.isCompleted
    }
    
    
    /**
        Request a cancellation. Clients will call this method in order to signal 
        a cancellation request to any object which has registered handlers for this 
        CancellationRequest. 
    
        Cancellation is asynchronous, that is, the effect of requesting a cancellation 
        may not yet be visible on the same thread immediately after `cancel` returns.
    
        `self` will be retained up until all registered handlers have been finished executing.
    */
    public final func cancel() {
        dispatch_async(sync_queue) {
            if self._sharedState.complete() {
                assert(self._queue != nil)
                dispatch_resume(self._queue!)
                self._queue = nil
            }
        }
    }


    /**
        Returns the associated "cancellation token" - an instance of a 
        CancellationTokenType.
    */
    public final var token : CancellationToken {
        return CancellationToken(cancellationRequest: self)
    }
    
    
    
    /**
        Registers the closure `f` which is invoked on the given execution context 
        when `self` has been cancelled and when the `cancelable` still exists. 
        `Closure `f` will be called with the given cancellable as its argument. 
        `self` and the `cancelable` will not be retained.
    */
    internal func onCancel(on executor: ExecutionContext, cancelable: Cancelable, f: (Cancelable)->()) {
        dispatch_async(sync_queue) {
            if !self._sharedState.isCompleted {
                assert(self._queue != nil)
                let state = self._sharedState
                dispatch_async(self._queue!) { [weak cancelable] in
                    if let c = cancelable {
                        if state.isCompleted {
                            executor.execute {
                                f(c)
                            }
                        }
                    }
                }
            }
            else {
                assert(self._queue == nil)
                executor.execute {
                    f(cancelable)
                }
            }
        }
    }

    
    
    /**
        Registers the closure `f` which is invoked on the given execution context
        when `self` has been cancelled.
    */
    internal final func onCancel(on executor: ExecutionContext, f: ()->()) {
        dispatch_async(sync_queue) {
            if !self._sharedState.isCompleted {
                assert(self._queue != nil)
                let state = self._sharedState
                dispatch_async(self._queue!) {
                    if state.isCompleted {
                        executor.execute(f)
                    }
                }
            }
            else {
                assert(self._queue == nil)
                executor.execute(f)
            }
        }
    }
    
    
}



extension CancellationRequest : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let stateString: String = self.isCancellationRequested == true
            ? "cancellation requested"
            : "no cancellation requested"
        return "CancelllationRequest id: \(self.id) state: \(stateString)"
    }
 
}


