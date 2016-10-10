//
//  HandlerRegistry.swift
//  FutureLib/Cancellation
//
//  Created by Andreas Grosam on 30/08/16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//





/**
 Implements a container for event handlers. Handlers can be added (registered) and 
 removed (unregistered) again.
 */
internal struct HandlerRegistry<T>: HandlerRegistryType {
    
    internal typealias HandlerType = (T) -> ()    
    internal typealias HandlerId = Int
    
    private typealias Element = (HandlerId, HandlerType)

    private var handlers: [Element] = []
    private var _id: Int = 0
    
    var count: Int { return self.handlers.count }
    
    internal mutating func register(f: @escaping (T) -> ()) -> HandlerId {
        let handlerId = _id
        _id += 1
        self.handlers.append((handlerId, f))
        return handlerId
    }
    
    internal mutating func unregister(id: HandlerId) -> HandlerType? {
        if let index = self.handlers.index(where: {$0.0 == id}) {
            let eventHandler = self.handlers[index].1 
            self.handlers.remove(at: index)
            return eventHandler
        }
        return nil
    }
    
    
    internal func execute(withParameter value: T) {
        self.handlers.forEach { (_, f) in
            f(value)
        }
    }
    
    internal mutating func invalidate() {
        self.handlers = []
    }
}


