//
//  PromiseExtensions.swift
//  FutureLib
//
//  Created by Andreas Grosam on 09.08.15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch




public func promiseWithTimeout(timeout : Double) -> Promise<Void> {
    let promise = Promise<Void>.resolveAfter(timeout, with: Result<Void>(error: PromiseError.Timeout))
    return promise
}




extension Promise {

    public static func resolveAfter(delay:Double, with result : Result<T>) -> Promise {
        let promise = Promise<T>()
        let cr = CancellationRequest()
        let timer = Timer(delay: delay, tolerance: 0, cancellationToken: cr.token, queue: DISPATCH_TARGET_QUEUE_DEFAULT) { timer in
            promise.resolve(result)
        }
        timer.start()
        promise.onRevocation {
            cr.cancel()
        }
        return promise
    }
    
    
}