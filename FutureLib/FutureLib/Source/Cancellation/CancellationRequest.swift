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



private let sync = Synchronize(name: "CancellationRequest.sync_queue")


/**
    A CancellationRequest is a means to let clients signal a task which they initiated,
    that they are no more interested in the result. The task will be notified about the
    cancellation request signaled by its client and may now cancel its operation.
*/
public class CancellationRequest  : CancellationRequestProtocol {
    
    private typealias ValueType = Int32
    
    private var _result: ValueType = 0
    private var _handler_queue: dispatch_queue_t? = nil
    
    // MARK: init
    
    /**
        Default initializer.
    */
    public init() {
        OSAtomicCompareAndSwapInt(0, 0, &_result)
        print("CancelllationRequest created with id: \(self.id).")
    }

    deinit {
        dispatch_sync(sync.sync_queue) { /*[unowned self] in*/
            if let handlerQueue = self._handler_queue {
                // If we reach here, the last strong refernce to self has been destroyed,
                // and self has registered handlers but has not been cancelled.
                // What we do here effectively is "unregistering" all handlers,
                // since there is no chance that self can be cancelled anymore.
                // When resuming the handler_queue the handler will run as usual,
                // but the self's result equals 0 (no cancellation requested).
                dispatch_resume(handlerQueue)
                Log.Debug("CancelllationRequest destroyed: \(self.debugDescription).")
            }
        }
    }
    
    
    /**
        Returns a unique Id where this object can be identified.
    */
    public var id: UInt {
        return reflect(self).objectIdentifier!.uintValue
    }
    
    
    /**
        Returns true if a cancellation has been requested.
    */
    public var isCancellationRequested : Bool {
        return OSAtomicCompareAndSwapInt(1, 1, &_result)
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
        sync.write_async {
            if self._result == 0 {
                self._result = 1
                if self._handler_queue != nil {
                    // Caution:  handlers do not retain `self`, thus `cancel()` 
                    // MUST retain `self` until after all registered handlers have 
                    // been executed!
                    // TODO: check WHY we need to retain `self`
                    dispatch_barrier_async(self._handler_queue!) {
                        let _ = self // this is here in order to keep `self` alive until after all previous registered handlers have been executed.
                    }
                    dispatch_resume(self._handler_queue!)
                    self._handler_queue = nil
                }
            }
        }
    }


    /**
        Returns the associated "cancellation token" - an instance of a 
        CancellationTokenProtocol.
    */
    public var token : CancellationTokenProtocol {
        return CancellationToken(cancellationRequest: self)
    }
    
    
    private final func createHandlerQueue() -> dispatch_queue_t {
        assert(sync.is_synchronized())
        assert(self._handler_queue == nil)
        assert(self._result == 0)
        // Caution: the handler queue MUST be a serial queue!
        let queue = dispatch_queue_create("CancellationRequest.handler_queue", DISPATCH_QUEUE_SERIAL)!
        dispatch_set_target_queue(queue, sync.sync_queue)
        dispatch_suspend(queue)
        return queue
    }
    
    // Enqueues the closure f on the given handler queue.
    // Here we MUST execute on the sync queue with a write barrier!
    private final func _register(f: ()->()) {
        assert(sync.is_synchronized())
        if self._handler_queue == nil {
            self._handler_queue = self.createHandlerQueue()
        }
        dispatch_async(self._handler_queue!, f)
    }
    
    
    
    
    // Registers the closure f which is called on the given execution context 
    // when self is cancelled and when self still exists.
    // Closure f passes through the cancelable in its parameter. The cancelable is 
    // not retained. When the cancelable does not exist anymore when self has been 
    // cancelled, the closure is not called.
    // Does not retain self. Does not retain the cancelable.
    internal final func onCancel(cancelable: Cancelable, on executor: ExecutionContext, _ f: (Cancelable)->()) {
        sync.read_sync { [unowned self] in
            if self._result == 1 { // self already cancelled
                executor.execute() {
                    f(cancelable)
                }
            }
            else { // self still pending
                sync.write_async {
                    if self._result == 1 { // self has been cancelled in the meantime
                        executor.execute() {
                            f(cancelable)
                        }
                        return
                    }
                    self._register() { [weak self, weak cancelable] in
                        // Caution: in order to work correctly, `self` MUST be retained elsewhere
                        // when it has been cancelled until after the handler (all handlers)
                        // have been executed!
                        assert(sync.is_synchronized())
                        if self?._result == 1 {
                            if let theCancelable = cancelable {
                                executor.execute() {
                                    f(theCancelable)
                                }
                            } else {
                                // the weak cancelable is nil - we do not call the registered handler.
                                // (assuming that cancelable is already completed and does not require cancellation)
                            }
                        } else {
                            // weak self is nil - this means, that the CancellationRequest
                            // has been destroyed *before* it has been cancelled.
                            // We skip the handler in this case.
                        }
                    }
                }
            }
        }
    }

    // Executes closure f on the given execution context when it is cancelled
    // and when self still exists.
    // Does not retain self.
    // Remarks: The closure should not import a strong reference to a cancelable.
    // Instead a weak reference should be imported. This ensures that the operation
    // behind the cancelable can be destroyed when it is finished - and does not
    // hang around until after the CancellationRequest holding a reference to the
    // cancelable has been destroyed, too.
    internal final func onCancel(on executor: ExecutionContext, _ f: ()->()) {
        sync.read_sync {
            if self._result == 1 { // self already cancelled
                executor.execute(f)
            }
            else { // self still pending
                sync.write_async {
                    self._register() { [weak self] in
                        assert(sync.is_synchronized())
                        if self?._result == 1 {
                            executor.execute(f)
                        }
                    }
                }
            }
        }
    }
    
    
    // Executes closure f on a private execution context when it is cancelled
    // and when self still exists. Closure f passes through the cancelable in
    // its parameter. The cancelable is not retained. When the cancelable does
    // not exist anymore when self has been cancelled, the closure is not called.
    // Does not retain self. Does not retain the cancelable.
    internal final func onCancel(cancelable: Cancelable, _ f: (Cancelable)->()) {
        onCancel(cancelable, on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    
    // Executes closure f on a private execution context when it is cancelled
    // and when self still exists.
    // Does not retain self.
    internal final func onCancel(f: ()->()) {
        onCancel(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    
    
}



extension CancellationRequest : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var s:String = ""
        sync.read_sync_safe {
            let stateString: String = OSAtomicCompareAndSwapInt(1, 1, &self._result) ?  "cancellation requested" : "no cancellation requested"
            s = "CancelllationRequest id: \(self.id) state: \(stateString)"
        }
        return s
    }
 
}


