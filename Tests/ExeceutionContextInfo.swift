//
//  ExeceutionContextInfo.swift
//  FutureLib
//
//  Created by Andreas Grosam on 24/06/16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import Dispatch




public struct ExecutionContextInfo {
    
    public static var current: ExecutionContextInfo {
        return ExecutionContextInfo(qname: DispatchQueue.currentLabel, threadId: pthread_mach_thread_np(pthread_self()))
    }
    
    private init(qname: String, threadId: mach_port_t) {
        self.queueName = qname
        self.threadId = threadId
    }
    
    public private(set) var queueName: String 
    public private(set) var threadId: mach_port_t
}


extension ExecutionContextInfo: CustomStringConvertible {
    public var description: String {
        return "dispatch queue: \(self.queueName) - Thread \(threadId)"
    }
}


fileprivate extension DispatchQueue {
    fileprivate static var currentLabel: String {
        return String(cString: __dispatch_queue_get_label(nil))
    }
}




