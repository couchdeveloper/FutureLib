//
//  CancellationRequest.swift
//  Future
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


/**
 A CancellationRequest is a means to let clients signal a task which they initiated,
 that they are no more interested in the result. The task will be notified about the
 cancellation request signaled by its client and may now cancel its operation.
*/
public final class CancellationRequest: CancellationRequestType {

    public typealias CancellationToken = FutureLib.CancellationToken

    private let _sharedState = SharedCancellationState()

    /**
     Designated initializer. Initializes a CancellationRequest object.
    */
    public init() {
    }

    /**
     When `self` is being deinitialized it completes its shared state which in
     turn deregisters all handlers.
    */
    deinit {
        _sharedState.invalidate()
    }

    internal final var sharedState: SharedCancellationState {
        return _sharedState
    }


    /**
     - returns: A unique Id where this object can be identified.
    */
    public final var id: UInt {
        return UInt(ObjectIdentifier(self))
    }


    /**
     - returns: `true` if a cancellation has been requested.
    */
    public final var isCancellationRequested: Bool {
        return _sharedState.isCancelled
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
        _sharedState.cancel()
    }


    /**
     - returns: The associated "cancellation token" - an instance of a
     CancellationTokenType.
    */
    public final var token: CancellationToken {
        return FutureLib.CancellationToken(sharedState: _sharedState)
    }


}



extension CancellationRequest: CustomDebugStringConvertible {

    /// - returns: A description of `self`.
    public var debugDescription: String {
        let stateString: String = self.isCancellationRequested == true
            ? "cancellation requested"
            : "no cancellation requested"
        return "CancellationRequest id: \(self.id) state: \(stateString)"
    }

}
