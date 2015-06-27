//
//  CancellationTokenProtocol.swift
//  Future
//
//  Created by Andreas Grosam on 26/06/15.
//
//


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


