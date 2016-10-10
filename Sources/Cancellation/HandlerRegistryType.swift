//
//  HandlerRegistryType.swift
//  Cancellation
//
//  Created by Andreas Grosam on 30/08/16.
//
//


internal protocol HandlerRegistryType {
    associatedtype Param 
    associatedtype HandlerId
    
    typealias HandlerType = (Param) -> ()
        
    init()
    
    var count: Int {get}
    
    mutating func register(f: @escaping (Param) -> ()) -> HandlerId    
    
    mutating func unregister(id: HandlerId) -> HandlerType?    
    
    func execute(withParameter value: Param) 
    
    mutating func invalidate()
}

