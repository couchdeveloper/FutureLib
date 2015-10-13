//
//  CancellationTokenType.swift
//  Future
//
//  Created by Andreas Grosam on 26/06/15.
//
//


/**
    The `CancellationTokenType` defines the methods and behavior for a concrete
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
public protocol CancellationTokenType {
    
    /**
        Returns true if `self`'s associated CancellationRequest has requested
        a cancellation. Otherwise, it returns false.
    */
    var isCancellationRequested : Bool { get }
        
    
    
    /**
        Registers the closure `f` which is invoked on a given execution context
        when its associated `CancellationRequest` has been cancelled and when the
        `cancelable` still exists.
        
        `Closure `f` will be called with the given cancellable as its argument.
        `self` and the `cancelable` shall not be retained.
    
        **Remarks:**
    
        When the corresponding cancellation request has not been cancelled it may 
        deinit at any time, or it may have been already deinited when this method 
        will be called. In this case, registered closures will not execute, but 
        instead the closure will be deinited itself and any imported strong references 
        will be released.
    
        If the corresponding cancellation request has been cancelled the closure
        `f` will be dispatched immediately on the specified execution context.
        
        - parameter on: An execution context where the colsure will be scheduled on.
        
        - parameter cancelable: The "cancelable", that is - the object that registered
        this handler.
        
        - parameter f:  The closure which will be executed when a cancellation has
        been requested.
    */
    func onCancel(on executor: AsyncExecutionContext, cancelable: Cancelable, _ f: (Cancelable)->())
    
    
    /**
        Executes closure `f` on the given execution context when its associated
        `CancellationRequest` has been cancelled.
        
        **Caution:** An implementation MUST not retain `self` when registering a 
        closure .
    
        **Remarks:**
        
        When the corresponding cancellation request has not been cancelled it may
        deinit at any time, or it may have been already deinited when this method
        will be called. In this case, registered closures will not execute, but
        instead the closure will be deinited itself and any imported strong references
        will be released.
        
        If the corresponding cancellation request has been cancelled the closure
        `f` will be dispatched immediately on the specified execution context.
        
    
        - parameter on: An execution context where the colsure will be scheduled on.
        
        - parameter f:  The closure which will be executed when a cancellation has
        been requested.
    */
    func onCancel(on executor: AsyncExecutionContext, _ f: ()->())


}



public extension CancellationTokenType {


    /**
        Registers the closure `f` which is invoked on a private execution context
        when its associated `CancellationRequest` has been cancelled and when the
        `cancelable` still exists.

        `Closure `f` will be called with the given cancellable as its argument.
        `self` and the `cancelable` shall not be retained.

        **Remarks:**

        When the corresponding cancellation request has not been cancelled it may
        deinit at any time, or it may have been already deinited when this method
        will be called. In this case, registered closures will not execute, but
        instead the closure will be deinited itself and any imported strong references
        will be released.

        If the corresponding cancellation request has been cancelled the closure
        `f` will be dispatched immediately on the specified execution context.

        - parameter cancelable: The "cancelable", that is - the object that registered
        this handler.

        - parameter f:  The closure which will be executed when a cancellation has
        been requested.
    */
    public func onCancel(cancelable: Cancelable, _ f: (Cancelable)->()) {
        self.onCancel(on: GCDAsyncExecutionContext(), cancelable: cancelable, f)
    }
    
    
    /**
        Executes closure `f` on a private execution context when its associated
        `CancellationRequest` has been cancelled.
        
        **Caution:** An implementation MUST not retain `self` when registering a
        closure .
        
        **Remarks:**
        
        When the corresponding cancellation request has not been cancelled it may
        deinit at any time, or it may have been already deinited when this method
        will be called. In this case, registered closures will not execute, but
        instead the closure will be deinited itself and any imported strong references
        will be released.
        
        If the corresponding cancellation request has been cancelled the closure
        `f` will be dispatched immediately on the specified execution context.
        
        
    
        - parameter f:  The closure which will be executed when a cancellation has
        been requested.
    */
    public func onCancel(f: ()->()) {
        self.onCancel(on: GCDAsyncExecutionContext(), f)
    }
    
    
    
}


