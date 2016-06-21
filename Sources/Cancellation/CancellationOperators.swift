//
//  CancellationOperators.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//



public func || (left: CancellationTokenType, right: CancellationTokenType)
    -> CancellationTokenType {
    let scs = SharedCancellationState()
    let ec = ConcurrentAsync()
    var rid = -1
    let lid = left.register(on: ec) { cancelled in
        if cancelled {
            scs.cancel()
            right.unregister(rid)
        }
    }
    rid = right.register(on: ec) { cancelled in
        if cancelled {
            scs.cancel()
            left.unregister(lid)
        }
    }
    return CancellationToken(sharedState: scs)
}



public func && (left: CancellationTokenType, right: CancellationTokenType)
    -> CancellationTokenType {
    let scs = SharedCancellationState()
    let ec = ConcurrentAsync()
    _ = left.register(on: ec) { cancelled in
        if cancelled {
            _ = right.register(on: ec) { cancelled in
                scs.cancel()
            }
        }
    }
    return CancellationToken(sharedState: scs)
}
