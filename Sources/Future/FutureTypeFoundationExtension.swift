//
//  FutureTypeFoundationExtension.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Foundation

private var context = CFRunLoopSourceContext()
private let runLoopSource = CFRunLoopSourceCreate(nil, 0, &context)


extension FutureType {

    public final func runLoopWait() -> Self {
        // The current thread MUST have a run loop and at least one event source!
        // This is difficult to verfy in this method - thus this is simply
        // a prerequisite which must be ensured by the client. If there is no
        // event source, the run lopp may quickly return with the effect that the
        // while loop will "busy wait".

        let runLoop = CFRunLoopGetCurrent()
        CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode)
        self.onComplete(ec: ConcurrentAsync(), ct: CancellationTokenNone()) { _ in
            CFRunLoopStop(runLoop)
        }


        while !self.isCompleted {
            CFRunLoopRun()
        }
        CFRunLoopRemoveSource(runLoop, runLoopSource, kCFRunLoopDefaultMode)
        return self
    }

}
