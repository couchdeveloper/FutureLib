//
//  schedule_after.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import Dispatch


public typealias TimeInterval = Double

public func schedule_after(delay: TimeInterval, queue: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f: () -> ()) {
    let d = Int64(delay * Double(NSEC_PER_SEC) + 0.5)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, d), queue, f)
}