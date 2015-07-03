//
//  CancellationToken.swift
//  Future
//
//  Created by Andreas Grosam on 26/06/15.
//
//



/**
    The CancelationToken is passed from the client to a task when it creates the task
    to let it know when the client has requested a cancellation.
*/
public class CancellationToken : CancellationTokenProtocol {
    private let _cancellationRequest : CancellationRequest
    
    internal init(cancellationRequest : CancellationRequest) {
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