//
//  CancellationRequest.swift
//  Future
//
//  Created by Andreas Grosam on 27.03.15.
//  Copyright (c) 2015 Andreas Grosam. All rights reserved.
//

import Foundation
import Darwin


public class CancellationError : NSError {
    
    public init(underlyingError: NSError) {
        super.init(domain: "Cancellation", code: -1,
            userInfo: [NSLocalizedFailureReasonErrorKey:"Operation Cancelled",
                NSUnderlyingErrorKey: underlyingError])
    }
    
    public init() {
        super.init(domain: "Cancellation", code: -1,
            userInfo: [NSLocalizedFailureReasonErrorKey:"Operation Cancelled"])
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}


/// A thing, usually an operation or task, which can be cancelled.
///
/// Calling cancel on a Cancelable may eventually cancel it. Due to the inherently
/// asynchronous behavior of Cancelables there is however no guarantee that after
/// calling cancel the state of the Cancelable becomes eventually or actually "cancelled".
///
/// The contract a Cancelable should fulfill says that after receiving a cancel
/// signal - and if it is still executing - a Cancelable should as soon as possible
/// cancel its operation. However, a Cancelable may also succeed or fail before
/// this cancel request becomes effective. When the Cancelable is already in a finished
/// state, calling cancel on it has no effect.
///
/// If a Cancelable is an operation which signals its eventual result via a promise,
/// on a cancel signal it should reject its promise *after* its operation is actually
/// cancelled with a corresponding error reason. The clients can get a cancellation
/// signal through registering an error handler on their future.
public protocol Cancelable : class {
    func cancel() -> ()
    func cancel(error:NSError) -> ()
}





public protocol CancellationTokenProtocol {
    
    
    /// Returns true if `self`'s associated CancellationRequest has requested 
    /// a cancellation. Otherwise, it returns false.
    var isCancellationRequested : Bool { get }
    
    
    /// Registers the continuation `f` which takes a parameter `cancelable` which
    /// will be executed on the given execution context when its associated
    /// CancellationRequest requested a cancellation. Registering a closure shall
    /// not retain self.
    /// The cancelable shall not be retained for the duration the handler is registered.
    /// The closure shall only be called when the cancelable still exists at this time.
    /// When closure f is called, its parameter is the specified cancelable.
    ///
    /// :param: cancelable The `cancelable` which is usually an underlying task that can be cancelled.
    /// :param: executor An execution context which executes the continuation.
    /// :param: f The continuation.
    func onCancel(cancelable: Cancelable, on executor: ExecutionContext, _ f: (Cancelable)->())
    
    
    /// Registers the continuation `f` which will be executed on the given execution 
    /// context when its associated CancellationRequest requested a cancellation.
    /// Registering a closure shall not retain self.
    ///
    /// :param: executor An execution context which executes the continuation.
    /// :param: f The continuation.
    func onCancel(on executor: ExecutionContext, _ f: ()->())
    
    
    
    /// Registers the continuation `f` which takes a parameter `cancelable` which
    /// will be executed on a private execution context when its associated
    /// CancellationRequest requested a cancellation. Registering a closure shall
    /// not retain self.
    /// The cancelable shall not be retained for the duration the handler is registered.
    /// The closure shall only be called when the cancelable still exists at this time.
    /// When closure f is called, its parameter is the specified cancelable.
    ///
    /// :param: cancelable The `cancelable` which is usually an underlying task that can be cancelled.
    /// :param: f The continuation.
    func onCancel(cancelable: Cancelable, _ f: (Cancelable)->())
    
    
    /// Registers the continuation `f` which will be executed on a private execution
    /// context when its associated CancellationRequest requested a cancellation.
    /// Registering a closure shall not retain self.
    ///
    /// :param: f The continuation.
    func onCancel(f: ()->())
}




private let sync = Synchronize()

public class CancellationRequest : DebugPrintable {
    
    private typealias ValueType = Int32
    
    private var _result: ValueType = 0
    private var _handler_queue: dispatch_queue_t? = nil
    
    // MARK: init
    
    public init() {
        OSAtomicCompareAndSwapInt(0, 0, &_result)
        println("CancelllationRequest created with id: \(self.id).")
    }

    deinit {
        sync.read_sync_safe  { [unowned self] in
            if (self._handler_queue != nil) {
                // If we reach here, the last strong refernce to self has been destroyed, 
                // and self has registered handlers but has not been cancelled.
                // What we do here effectively is "unregistering" all handlers, 
                // since there is no chance that self can be cancelled anymore. 
                // When resuming the handler_queue the handler will run as usual,
                // but the self's result equals 0 (no cancellation requested).
                dispatch_resume(self._handler_queue!)
            }
            println("CancelllationRequest destroyed: \(self.debugDescription).")
        }
    }
    
    public var id: UInt {
        return reflect(self).objectIdentifier!.uintValue
    }
    
    
    private func createHandlerQueue() -> dispatch_queue_t {
        assert(sync.on_sync_queue())
        assert(self._handler_queue == nil)
        assert(self._result == 0)
        // Caution: the handler queue MUST be a serial queue!
        let queue = dispatch_queue_create("handler_queue", DISPATCH_QUEUE_SERIAL)!
        dispatch_set_target_queue(queue, sync.sync_queue)
        dispatch_suspend(queue)
        return queue
    }

    public var debugDescription: String {
        var s:String = ""
        sync.read_sync_safe {  [unowned self] in
            let stateString: String = OSAtomicCompareAndSwapInt(1, 1, &self._result) ?  "cancellation requested" : "no cancellation requested"
            let s = "CancelllationRequest id: \(self.id) state: \(stateString)"
        }
        return s
    }
    
    
    var isCancellationRequested : Bool {
        return OSAtomicCompareAndSwapInt(1, 1, &_result)
    }
    
    
    /// Request cancellation.
    public final func cancel() {
        sync.write_async {
            if self._result == 0 {
                self._result = 1
                if self._handler_queue != nil {
                    // Caution:  handlers do not retaining self, thus cancel() MUST retain `self`
                    // until after all registered handlers have been executed somehow!
                    dispatch_barrier_async(self._handler_queue!) {
                        let dummy = self // this is here in order to keep `self` alive until after all previous registered handlers have been executed.
                    }
                    dispatch_resume(self._handler_queue!)
                    self._handler_queue = nil
                }
            }
        }
    }
    
    
    public final func token() ->  CancellationToken {
        return CancellationToken(cancellationRequest: self)
    }
    
    /// Enqueues the closure f on the given handler queue.
    /// Here we MUST execute on the sync queue with a write barrier!
    private final func _register(f: ()->()) {
        assert(sync.on_sync_queue())
        if self._handler_queue == nil {
            self._handler_queue = self.createHandlerQueue()
        }
        dispatch_async(self._handler_queue!, f)
    }
    
    
    
    
    /// Registers the closure f which is called on the given execution context 
    /// when self is cancelled and when self still exists.
    /// Closure f passes through the cancelable in its parameter. The cancelable is 
    /// not retained. When the cancelable does not exist anymore when self has been 
    /// cancelled, the closure is not called.
    /// Does not retain self. Does not retain the cancelable.
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

    /// Executes closure f on the given execution context when it is cancelled
    /// and when self still exists.
    /// Does not retain self.
    /// Remarks: The closure should not import a strong reference to a cancelable.
    /// Instead a weak reference should be imported. This ensures that the operation
    /// behind the cancelable can be destroyed when it is finished - and does not
    /// hang around until after the CancellationRequest holding a reference to the
    /// cancelable has been destroyed, too.
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
    
    
    /// Executes closure f on a private execution context when it is cancelled
    /// and when self still exists. Closure f passes through the cancelable in
    /// its parameter. The cancelable is not retained. When the cancelable does
    /// not exist anymore when self has been cancelled, the closure is not called.
    /// Does not retain self. Does not retain the cancelable.
    private final func onCancel(cancelable: Cancelable, _ f: (Cancelable)->()) {
        onCancel(cancelable, on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    
    /// Executes closure f on a private execution context when it is cancelled
    /// and when self still exists.
    /// Does not retain self.
    private final func onCancel(f: ()->()) {
        onCancel(on: dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
    }
    
    
}




public class CancellationToken : CancellationTokenProtocol {
    private let _cancellationRequest : CancellationRequest
    
    private init(cancellationRequest : CancellationRequest) {
        _cancellationRequest = cancellationRequest
    }
    
    
    public var isCancellationRequested : Bool {
        return _cancellationRequest.isCancellationRequested
    }
    
    
    /// Executes closure f on a private execution context when its associated
    /// CancellationRequest has been cancelled.
    ///
    /// The cancelable is not retained for the duration the handler is registered.
    /// The closure is only called when the cancelable still exists at this time.
    /// When closure f is called, its parameter is the specified cancelable.
    /// Usually, the closure would simply perform cancelable.cancel().
    /// A "cancelable" is usually an underlying task that can be cancelled.
    ///
    /// :Remarks: Registering a closure does not retain self. Registered handlers
    /// won't get unregistered when self gets destroyed. Registered handlers
    /// only get unregistered (ignored) when the associated CancellationRequest
    /// gets destroyed without being cancelled. A CancellationRequest should be
    /// destroyed when all registered cancelables have been resolved (which implies 
    /// that a cancellation would have no effect).
    public final func onCancel(cancelable: Cancelable, on executor: ExecutionContext, _ f: (Cancelable)->()) {
        _cancellationRequest.onCancel(cancelable, on: executor, f)
    }
    
    /// Executes closure f on a private execution context when its associated
    /// CancellationRequest has been cancelled.
    ///
    /// Remarks: The closure should not import a strong reference to a cancelable.
    /// Instead a weak reference should be imported. This ensures that the resolver
    /// behind the cancelable can be destroyed when it is finished - and does not
    /// hang around until after the CancellationRequest holding a reference to the
    /// cancelable has been destroyed, too.
    ///
    /// :Remarks: Registering a closure does not retain self. Registered handlers
    /// won't get unregistered when self gets destroyed. Registered handlers
    /// only get silently unregistred when the associated CancellationRequest
    /// gets destroyed without being cancelled.
    public final func onCancel(on executor: ExecutionContext, _ f: ()->()) {
        _cancellationRequest.onCancel(on: executor, f)
    }
    
    
    /// Executes closure f on a private execution context when its associated
    /// CancellationRequest has been cancelled. Closure f passes through the cancelable 
    /// in its parameter. 
    ///
    /// The cancelable is not retained. When the cancelable does not exist anymore 
    /// at the time when self has been cancelled, the closure is not called.
    /// Does not retain self. Does not retain the cancelable.
    ///
    /// :Remarks: Registering a closure does not retain self. Registered handlers
    /// won't get unregistered when self gets destroyed. Registered handlers
    /// only get silently unregistred when the associated CancellationRequest
    /// gets destroyed without being cancelled.
    public final func onCancel(cancelable: Cancelable, _ f: (Cancelable)->()) {
        _cancellationRequest.onCancel(cancelable, f)
    }
    
    /// Executes closure f on a private execution context when its associated 
    /// CancellationRequest has been cancelled.
    ///
    /// :Remarks: Registering a closure does not retain self. Registered handlers 
    /// won't get unregistered when self gets destroyed. Registered handlers
    /// only get silently unregistred when the associated CancellationRequest
    /// gets destroyed without being cancelled.
    public final func onCancel(f: ()->()) {
        _cancellationRequest.onCancel(f)
    }
    
}