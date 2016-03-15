//
//  CancellationRequestType.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//


/**
 A `CancellationRequestType` declares methods and defines the behavior for a concrete
 `CancellationRequest` implementation.
 
 The `CancellationRequest` is a means to let clients signal a target object which
 they created, that they are no more interested in their service. This object can
 be a _cancelabel_, a task or operation or a callback handler or anything that
 implements some sort of _cancellation_.
 
 In order to be notified about a cancellation request, the target object observes
 the cancellation request's _cancellation token_, that is, it either registers a
 callback using the `onCancel` method which gets called when a cancellation has been
 requested or it periodically tests the cancellation state with using the property
 `isCancellationRequested` of the cancellation token.
 
 The client of that target object will create and hold a `CancellationRequest` and
 passes the cancellation request's associated cancellation token to the target object.
 When the client has no more interest in the service that the target object provides,
 the client calls `cancel()` for its cancellation request. The target object which
 observes the associated cancellation token will be notified by this cancellation
 request and can handle this event appropriately.
*/
public protocol CancellationRequestType {


    typealias CancellationTokenType

    /**
     - returns: `true` if a cancellation has been requested.
    */
     var isCancellationRequested: Bool { get }


    /**
     Request a cancellation. Clients will call this method in order to signal
     a cancellation request to any object which has registered handlers for this
     CancellationRequest.

     Cancellation is _asynchronous_, that is, the effect of requesting a cancellation
     may not yet be visible on the same thread immediately after `cancel` returns.
    */
    func cancel()

    /**
     - returns:  The associated cancellation token.
    */
    var token: CancellationTokenType { get }

}
