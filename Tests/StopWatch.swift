//
//  StopWatch.swift
//  FutureLib
//
//  Created by Andreas Grosam on 28/06/16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import Foundation
import Darwin

private let sTimebaseInfo: mach_timebase_info_data_t = {
    var timebaseInfo = mach_timebase_info_data_t()
    mach_timebase_info(&timebaseInfo)
    return timebaseInfo
}()

private func toSeconds(_ absoluteDuration: UInt64) -> Double {
    return Double(absoluteDuration) * 1.0e-9 * Double(sTimebaseInfo.numer) / Double(sTimebaseInfo.denom)
}

public class StopWatch {
    
    private var _t0: UInt64 = 0
    private var _time: Double = 0
        
    public func reset() {
        _t0 = 0
        _time = 0
    }
    
    public func start() {
        _time = 0
        _t0 = mach_absolute_time()
    }
    
    public func stop() -> Double {
        if _t0 != 0 {
            _time = toSeconds(mach_absolute_time() - _t0)
            _t0 = 0
        }
        return _time
    }
    
    public func time() -> Double {
        if _t0 != 0 {
            return toSeconds(mach_absolute_time() - _t0)
        } else {
            return _time
        }
    }
}
