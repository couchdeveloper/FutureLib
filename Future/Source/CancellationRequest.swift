//
//  CancellationRequest.swift
//  Future
//
//  Created by Andreas Grosam on 27.03.15.
//  Copyright (c) 2015 Andreas Grosam. All rights reserved.
//

import Foundation
import Darwin

/**
    An error type that represents a cancellation.
*/
public class CancellationError : NSError {
    
    /**
        A designated initializer which creates a CancellationError with an underlying error.
        The domain equals "Cancellation" and the error code equals -1. The userInfo will have
        a key `NSLocalizedFailureReasonErrorKey` whose value equals "Operation Canclled".
    */
    public init(underlyingError: NSError) {
        super.init(domain: "Cancellation", code: -1,
            userInfo: [NSLocalizedFailureReasonErrorKey:"Operation Cancelled",
                NSUnderlyingErrorKey: underlyingError])
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    /**
        A designated initializer which creates a CancellationError.
        The domain equals "Cancellation" and the error code equals -1.
    */
    public init(_ : Int = 0) {
        super.init(domain: "Cancellation", code: -1,
            userInfo: [NSLocalizedFailureReasonErrorKey:"Operation Cancelled"])
    }

}



/**
    A `Cancelable` is a thing, usually an operation, a service or task, which can be 
    cancelled.

    Calling cancel on a Cancelable _may eventually_ cancel it. Due to the inherently
    asynchronous behavior of cancelling a task there is however no guarantee that after
    calling cancel the state of the Cancelable becomes _immediately_ "cancelled". There
    may be even no guarantee that the Cancelable becomes eventually cancelled at all -
    it may fail or succeed afterward.

    The contract a Cancelable should fulfill says that after receiving a cancel
    signal - and if it is still executing - a Cancelable _should as soon as possible_
    cancel its operation. However, a Cancelable may also succeed or fail before
    this cancel request becomes effective. When the Cancelable is already in a finished
    state, calling cancel on it has no effect.

    If a Cancelable is an operation which signals its eventual result via a promise,
    on a cancel signal it should reject its promise *after* its operation is actually
    cancelled with a corresponding error reason. The clients can get a cancellation
    signal through registering an error handler on the corresponding future.
*/
public protocol Cancelable : class {
    func cancel() -> ()
    func cancel(error:NSError) -> ()
}



/**
    The `CancellationTokenProtokol` defines the methods and behavior for a concrete
    implementation of a `CancellationToken`. A cancellation token is associated to
    a corresponding `CancellationRequest` with a one-to-one relationship.
    A cancellation token is passed from a client to a potentially long lasting task or
    operation when the client creates this task. The task will observe the state of
    the cancellation token or registers a handler function which let it know when 
    the client has requested a cancellation.  When a client requested a cancellation 
    the task should take the appropriate steps to cancel/terminate its operation. It 
    may however also to decide _not_ to cancel its operation, for example when there
    are yet other clients still waiting for the result. One cancellation token may be
    shared by many observers.
*/
public protocol CancellationTokenProtocol {
    
    /**
        Returns true if `self`'s associated CancellationRequest has requested
        a cancellation. Otherwise, it returns false.
    */
    var isCancellationRequested : Bool { get }
    
    /**
        Registers the continuation `f` with a Cancelable and with an ExecutionContext
        which will be executed on the given execution context when its associated 
        CancellationRequest requested a cancellation. Registering a closure shall not 
        retain self.
        The cancelable shall not be retained for the duration the handler is registered.
        The closure shall only be called when the cancelable still exists at this time.
        When closure `f` is called, its parameter is the specified cancelable.
        
        - parameter cancelable: The `cancelable` which is usually an underlying task that can be cancelled.
        - parameter executor: An execution context which executes the continuation.
        - parameter f: The continuation.
    */
    func onCancel(cancelable: Cancelable, on executor: ExecutionContext, _ f: (Cancelable)->())
    
    /**
        Registers the continuation `f` which will be executed on the given execution
        context when its associated CancellationRequest requested a cancellation.
        Registering a closure shall not retain self.

        - parameter executor: An execution context which executes the continuation.
        - parameter f: The continuation.
    */
    func onCancel(on executor: ExecutionContext, _ f: ()->())
    
    
    /**
        Registers the continuation `f` which takes a parameter `cancelable` which
        will be executed on a private execution context when its associated
        CancellationRequest requested a cancellation. Registering a closure shall
        not retain self.
        The cancelable shall not be retained for the duration the handler is registered.
        The closure shall only be called when the cancelable still exists at this time.
        When closure f is called, its parameter is the specified cancelable.

        - parameter cancelable: The `cancelable` which is usually an underlying task that can be cancelled.
        - parameter f: The continuation.
    */
    func onCancel(cancelable: Cancelable, _ f: (Cancelable)->())
    
    /**
        Registers the continuation `f` which will be executed on a private execution
        context when its associated CancellationRequest requested a cancellation.
        Registering a closure shall not retain self.

        - parameter f: The continuation.
    */
    func onCancel(f: ()->())
}



/**
    A CancellationRequestProtokol declares methods and defines the behavior for a concrete
    CancellationRequest implementation. The CancellationRequest is a means to let clients 
    signal a task which they created, that they are no more interested in the result. The 
    task will be notified about the cancellation request through observing the cancellation 
    token. The client of a task will create and hold a CancellationRequest and pass the
    cancellation request's cancellation token to the task which it created. When the client
    has no more interest in the eventual result which is computed by the task, the client
    calls `cancel()` to its cancellation request. The task which observes the associated
    cancellation token will be notified by this cancellation request and can handle this 
    event appropriately.
*/
public protocol CancellationRequestProtokol  {
    
    /**
        Returns true if a cancellation has been requested.
    */
    var isCancellationRequested : Bool { get }
    
    
    /**
        Request a cancellation. Clients will call this method in order to signal a cancellation request
        to any object which has registered handlers for this CancellationRequest.
    */
    func cancel()
    
    /**
        Returns the cancellation token.
    */
    var token : CancellationTokenProtocol { get }

}



private let sync = Synchronize(name: "CancellationRequest.sync_queue")


/**
    A CancellationRequest is a means to let clients signal a task which they initiated,
    that they are no more interested in the result. The task will be notified about the
    cancellation request signaled by its client and may now cancel its operation.
*/
public class CancellationRequest  : CancellationRequestProtokol {
    
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
                print("CancelllationRequest destroyed: \(self.debugDescription).")
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
        Request a cancellation. Clients will call this method in order to signal a cancellation request
        to any object which has registered handlers for this CancellationRequest.
    */
    public final func cancel() {
        sync.write_async {
            if self._result == 0 {
                self._result = 1
                if self._handler_queue != nil {
                    // Caution:  handlers do not retain self, thus cancel() MUST retain `self`
                    // until after all registered handlers have been executed somehow!
                    dispatch_barrier_async(self._handler_queue!) {
                        let _ = self // this is here in order to keep `self` alive until after all previous registered handlers have been executed.
                    }
                    dispatch_resume(self._handler_queue!)
                    self._handler_queue = nil
                }
            }
        }
    }


    public var token : CancellationTokenProtocol {
        return CancellationToken(cancellationRequest: self)
    }
    
    
    private final func createHandlerQueue() -> dispatch_queue_t {
        assert(sync.on_sync_queue())
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
        assert(sync.on_sync_queue())
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
    private final func onCancel(cancelable: Cancelable, on executor: ExecutionContext, _ f: (Cancelable)->()) {
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
                        assert(sync.on_sync_queue())
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
    private final func onCancel(on executor: ExecutionContext, _ f: ()->()) {
        sync.read_sync {
            if self._result == 1 { // self already cancelled
                executor.execute(f)
            }
            else { // self still pending
                sync.write_async {
                    if self._result == 1 { // self has been cancelled in the meantime
                        executor.execute(f)
                        return
                    }
                    self._register() { [weak self] in
                        assert(sync.on_sync_queue())
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
    private final func onCancel(cancelable: Cancelable, _ f: (Cancelable)->()) {
        onCancel(cancelable, on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    
    // Executes closure f on a private execution context when it is cancelled
    // and when self still exists.
    // Does not retain self.
    private final func onCancel(f: ()->()) {
        onCancel(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    
    
}



extension CancellationRequest : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var s:String = ""
        sync.read_sync_safe {  [unowned self] in
            let stateString: String = OSAtomicCompareAndSwapInt(1, 1, &self._result) ?  "cancellation requested" : "no cancellation requested"
            s = "CancelllationRequest id: \(self.id) state: \(stateString)"
        }
        return s
    }
 
}


/**
    The CancelationToken is passed from the client to a task when it creates the task
    to let it know when the client has requested a cancellation.
*/
public class CancellationToken : CancellationTokenProtocol {
    private let _cancellationRequest : CancellationRequest
    
    private init(cancellationRequest : CancellationRequest) {
        _cancellationRequest = cancellationRequest
    }
    
    /**
        Returns true if the client requested a cancellation.
    */
    public var isCancellationRequested : Bool {
        return _cancellationRequest.isCancellationRequested
    }
    
    /**
        Executes closure `f` on a private execution context when its associated
        `CancellationRequest` has been cancelled.

        The cancelable is not retained for the duration the handler is registered.
        The closure is only called when the cancelable still exists at this time.
        When closure f is called, its parameter is the specified cancelable.
        Usually, the closure would simply perform `cancelable.cancel()`.
        A "cancelable" is usually an underlying task that can be cancelled.

        Registering a closure does not retain `self`. Registered handlers
        won't get unregistered when `self` gets destroyed. Registered handlers
        only get unregistered (ignored) when the associated `CancellationRequest`
        gets destroyed without being cancelled. A `CancellationRequest` should be
        destroyed when all registered cancelables have been resolved (which implies 
        that a cancellation would have no effect).  
    
        - parameter cancelable: The "cancelable", that is - the object that registered 
                this handler.
        
        - parameter executor: The execution context which executes the closure `f`.
        
        - parameter f:  The closure which will be executed when a cancellation has
                been requested.
    */
    public final func onCancel(cancelable: Cancelable, on executor: ExecutionContext, _ f: (Cancelable)->()) {
        _cancellationRequest.onCancel(cancelable, on: executor, f)
    }
    
    /**
        Executes closure f on a private execution context when its associated
        `CancellationRequest` has been cancelled.

        **Remarks:**
        The closure should not import a _strong_ reference to a cancelable.
        Instead a _weak_ reference should be imported. This ensures that the resolver
        behind the cancelable can be destroyed when it is finished - and does not
        hang around until after the `CancellationRequest` holding a reference to the
        cancelable has been destroyed, too.

        Registering a closure does not retain self. Registered handlers
        won't get unregistered when self gets destroyed. Registered handlers
        only get silently unregistred when the associated `CancellationRequest`
        gets destroyed without being cancelled.
    
        - parameter executor: The execution context which executes the closure `f`.
    
        - parameter f: The closure which will be executed when a cancellation has been requested.
    */
    public final func onCancel(on executor: ExecutionContext, _ f: ()->()) {
        _cancellationRequest.onCancel(on: executor, f)
    }
    
    
    /**
        Executes closure f on a private execution context when its associated
        `CancellationRequest` has been cancelled. Closure f passes through the cancelable 
        in its parameter. 

        - parameter cancelable: The "cancelable", that is - the object that registered
            this handler.
    
        - parameter f:  The closure which will be executed when a cancellation has
            been requested.
        
        **Remarks:**
        The cancelable is not retained. When the cancelable does not exist anymore
        at the time when self has been cancelled, the closure is not called.
        Calling this method does not retain self and does not retain the cancelable.
    
        Registering a closure does not retain self. Registered handlers
        won't get unregistered when self gets destroyed. Registered handlers
        only get silently unregistred when the associated `CancellationRequest`
        gets destroyed without being cancelled.
    */
    public final func onCancel(cancelable: Cancelable, _ f: (Cancelable)->()) {
        _cancellationRequest.onCancel(cancelable, f)
    }
    
    /**
        Executes closure f on a private execution context when its associated
        `CancellationRequest` has been cancelled.

        Registering a closure does not retain self. Registered handlers
        won't get unregistered when self gets destroyed. Registered handlers
        only get silently unregistred when the associated `CancellationRequest`
        gets destroyed without being cancelled.
    */
    public final func onCancel(f: ()->()) {
        _cancellationRequest.onCancel(f)
    }
    
}