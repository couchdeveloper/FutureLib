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
public struct CancellationToken : CancellationTokenType  {
    
    
    private weak var _cancellationRequest : CancellationRequest?
    private let _sharedState : SharedState
    
    internal init(cancellationRequest: CancellationRequest) {
        _cancellationRequest = cancellationRequest
        _sharedState = cancellationRequest.sharedState
    }
    
    /**
    Returns true if the client requested a cancellation.
    */
    public var isCancellationRequested : Bool {
        return _sharedState.isCompleted
    }
    
    
    
    /**
        Registers the closure `f` which is invoked on a given execution context
        when its associated `CancellationRequest` has been cancelled and when the 
        `cancelable` still exists. 
    
        `Closure `f` will be called with the given cancellable as its argument.
        `self` and the `cancelable` will not be retained.
    
        - parameter on: An execution context where the colsure will be scheduled on.
    
        - parameter cancelable: The "cancelable", that is - the object that registered
        this handler.
        
        - parameter f:  The closure which will be executed when a cancellation has
        been requested.
    */
    public func onCancel(
        on executor: AsyncExecutionContext = GCDAsyncExecutionContext(),
        cancelable: Cancelable,
        _ f: (Cancelable)->())
    {
        if _sharedState.isCompleted {
            executor.execute {
                f(cancelable)
            }
        }
        else if let cr = _cancellationRequest {
            cr.onCancel(on: executor, cancelable: cancelable, f: f)
        }
    }
    
    /**
        Executes closure `f` on the given execution context when its associated
        `CancellationRequest` has been cancelled.
        
        Registering a closure does not retain self.

        - parameter on: An execution context where the colsure will be scheduled on.
    
        - parameter f:  The closure which will be executed when a cancellation has
        been requested.
    */
    public func onCancel(on executor: AsyncExecutionContext = GCDAsyncExecutionContext(), _ f: ()->()) {
        if _sharedState.isCompleted {
            executor.execute(f)
        }
        else if let cr = _cancellationRequest {
            cr.onCancel(on: executor, f: f)
        }
    }

    
    
    
}




