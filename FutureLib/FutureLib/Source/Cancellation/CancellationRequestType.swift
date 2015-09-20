//
//  CancellationRequestProtokol.swift
//  Future
//
//  Created by Andreas Grosam on 26/06/15.
//
//


/**
    A `CancellationRequestType` declares methods and defines the behavior for a concrete
    `CancellationRequest` implementation. The `CancellationRequest` is a means to let clients
    signal a task which they created, that they are no more interested in the result. The
    task will be notified about the cancellation request through observing the cancellation
    token. The client of a task will create and hold a `CancellationRequest` and pass the
    cancellation request's cancellation token to the task which it created. When the client
    has no more interest in the eventual result which is computed by the task, the client
    calls `cancel()` to its cancellation request. The task which observes the associated
    cancellation token will be notified by this cancellation request and can handle this
    event appropriately.
*/
public protocol CancellationRequestType  {
    
    
    typealias CancellationTokenType
    
    /**
        Returns true if a cancellation has been requested.
    */
     var isCancellationRequested : Bool { get }
    
    
    /**
        Request a cancellation. Clients will call this method in order to signal
        a cancellation request to any object which has registered handlers for this
        CancellationRequest.
        
        Cancellation is asynchronous, that is, the effect of requesting a cancellation
        may not yet be visible on the same thread immediately after `cancel` returns.
    */
    func cancel()
    
    /**
        Returns the cancellation token.
    */
    var token : CancellationTokenType { get }
    
}

