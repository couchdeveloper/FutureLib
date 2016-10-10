//
//  CancellationOperators.swift
//  FutureLib
//
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import Dispatch


private let syncQueue = DispatchQueue(label: "cancellation.operators.syncqueue")

public func || (left: CancellationTokenType, right: CancellationTokenType)
    -> CancellationTokenType 
{
    let scs = CancellationState()
    syncQueue.sync {
        var rid: EventHandlerIdType?
        let lid = left.onCancel(queue: syncQueue) {
            scs.cancel()
            rid?.invalidate()
        }
        rid = right.onCancel(queue: syncQueue) {
            scs.cancel()
            lid?.invalidate()
        }    
    }
    return CancellationToken(sharedState: scs)
}



public func && (left: CancellationTokenType, right: CancellationTokenType)
    -> CancellationTokenType 
{    
    let scs = CancellationState()
    _ = left.onCancel(queue: syncQueue) {
        _ = right.onCancel(queue: syncQueue) {
            scs.cancel()
        }
    }
    return CancellationToken(sharedState: scs)
}
