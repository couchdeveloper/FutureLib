//
//  CancellationSequenceTypeExtension.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
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
        on ec: ExecutionContext = ConcurrentAsync())
        -> CancellationTokenType {
        let scs = SharedCancellationState()
        let ct = CancellationToken(sharedState: scs)
        let sync_queue = DispatchQueue(label: "private sync queue", attributes: [.serial, .qosUserInitiated])
        let private_ec = GCDAsyncExecutionContext(sync_queue)
        private_ec.execute {
            var count = 0
            var ids = [Int]()
            var allCancelled = true
            for token in self {
                count += 1
                let id = token.register(on: private_ec) { cancelled in
                    count -= 1
                    allCancelled = allCancelled && cancelled
                    if !cancelled {
                        scs.invalidate()
                        for (i, ct) in self.enumerated() {
                            ct.unregister(ids[i])
                        }
                    } else if count == 0 && allCancelled {
                        scs.cancel()
                    }
                }
                ids.append(id)
            }
        }
        return ct
    }


    /**
     Returns a new cancellation token which will be completed when any cancellation
     tokens in `self` has been cancelled or when all of the cancellation tokens
     in `self` have been completed with "not cancelled".

     - parameter on: An asynchronous execution context where `f` will be executed.
     The return value is not used.
     - returns: A cancellation token.
     */
    public func anyCancelled(
        on ec: ExecutionContext = ConcurrentAsync())
        -> CancellationTokenType {
        let scs = SharedCancellationState()
        let ct = CancellationToken(sharedState: scs)
        let sync_queue = DispatchQueue(label: "private sync queue", attributes: [.serial, .qosUserInitiated])
        let private_ec = GCDAsyncExecutionContext(sync_queue)
        private_ec.execute {
            var count = 0
            var ids = [Int]()
            for token in self {
                count += 1
                let id = token.register(on: private_ec) { cancelled in
                    count  -= 1
                    if cancelled {
                        scs.cancel()
                        for (i, ct) in self.enumerated() {
                            ct.unregister(ids[i])
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
