//
//  CancellationSequenceTypeExtension.swift
//  FutureLib
//
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import Dispatch

extension Sequence where Iterator.Element: CancellationTokenType {


    /**
     Returns a new cancellation token which will be completed when all cancellation
     tokens in `self` have been cancelled or when any of the cancellation tokens
     in `self` has been completed with "not cancelled".

     - parameter on: An asynchronous execution context where `f` will be executed.
     The return value is not used.
     - returns: A cancellation token.
     */
    public func allCancelled(
        _ queue: DispatchQueue = DispatchQueue.global())
        -> CancellationTokenType {
        let scs = CancellationState()
        let returnedCancellationToken = CancellationToken(sharedState: scs)
        let sync_queue = DispatchQueue(label: "private sync queue", qos: .userInitiated)
        sync_queue.async {
            var count = 0
            var ids = [EventHandlerIdType?]()
            var allCancelled = true
            for token in self {
                count += 1
                let id = token.onComplete(queue: queue) { cancelled in
                    count -= 1
                    allCancelled = allCancelled && cancelled
                    if !cancelled {
                        scs.invalidate()
                        ids.forEach {
                            $0?.invalidate()
                        }
                    } else if count == 0 && allCancelled {
                        scs.cancel()
                    }
                }
                ids.append(id)
            }
        }
        return returnedCancellationToken
    }


    /**
     Returns a new cancellation token which will be completed when any cancellation
     token in `self` has been cancelled or when all of the cancellation tokens
     in `self` have been completed with "not cancelled".

     - parameter on: An asynchronous execution context where `f` will be executed.
     The return value is not used.
     
     - returns: A cancellation token.
     */
    public func anyCancelled(
        _ queue: DispatchQueue /*DispatchQueue = DispatchQueue.global()*/)
        -> CancellationTokenType {
        let scs = CancellationState()
        let ct = CancellationToken(sharedState: scs)
        let sync_queue = DispatchQueue(label: "private sync queue", qos: .userInitiated)
        sync_queue.async {
            var count = 0
            var ids = [EventHandlerIdType?]()
            for token in self {
                count += 1
                let id = token.onComplete(queue: queue) { cancelled in
                    count  -= 1
                    if cancelled {
                        scs.cancel()
                        ids.forEach {
                            $0?.invalidate()
                        }
                    } else if count == 0 {
                        scs.invalidate()
                    }
                }
                ids.append(id)
            }
        }
        return ct
    }

}
