//: [Previous](@previous)

import FutureLib
import Foundation
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true



func delay(duration: NSTimeInterval, f: () -> ()) {
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(duration * Double(NSEC_PER_SEC)))
    dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), f)
} 

enum ServerError: ErrorType {
    case SearchNotFound
}

public protocol SearchType {
    var searchID: String { get }
    var isCompleted: Bool { get }
    var progress: Double { get }
    var result: AnyObject? { get }
}

private class ServerSearch: SearchType {
    
    private init() {
        self.searchID = NSUUID().UUIDString
        self.start = NSDate()
        self.duration = Double(arc4random_uniform(UInt32(10)) + UInt32(10))
    }
    let searchID: String
    let start: NSDate
    let duration: NSTimeInterval
    var isCompleted: Bool {
        return NSDate().timeIntervalSinceDate(self.start) > self.duration
    }
    var progress: Double {
        let duration = NSDate().timeIntervalSinceDate(self.start)
        if duration > self.duration {
            return 1.0
        } else {
            return 1.0 - ((self.duration - duration) / self.duration)
        }
    }
    var result: AnyObject? {
        if isCompleted {
            return "Result"
        } else {
            return nil
        }
    }
    
}

private var searches: [String: ServerSearch] = [:]





internal class Search: SearchType {
    internal init(searchID: String) {
        self.searchID = searchID
    }
    let searchID: String
    var isCompleted: Bool { return progress >= 1.0 } 
    var progress: Double = 0.0
    var result: AnyObject? = nil
}


// The first API call which create a "Search" on the server:
// func createSearch(completion: (SearchType?, ErrorType?) -> () )
func createSearch() -> Future<SearchType> {
    NSLog("Start create Search...")
    return Promise.resolveAfter(1.0) {
        let serverSearch = ServerSearch()
        searches.updateValue(serverSearch, forKey: serverSearch.searchID)
        let search: SearchType = Search(searchID: serverSearch.searchID)
        NSLog("Finished creating Search with ID: \(search.searchID)")
        return search
    }.future!
}


// func fetchSearch(searchID: String, completion: (SearchType?, ErrorType?) -> () )
func fetchSearch(searchID: String) -> Future<SearchType> {
    NSLog("Start fetch Search with ID \(searchID)...")
    return Promise.resolveAfter(1.0) {
        if let serverSearch = searches[searchID] {
            let search = Search(searchID: searchID)
            search.progress = serverSearch.progress
            search.result = serverSearch.result
            NSLog("Finished creating Search with ID: \(search.searchID)")
            return search as SearchType
        } else {
            throw ServerError.SearchNotFound
        }
    }.future!
}


// func fetchResult(searchID: String, completion: (AnyObject?, ErrorType?) -> () )
func fetchResult(searchID: String) -> Future<AnyObject> {
    let promise = Promise<AnyObject>()
    func poll() {
        fetchSearch(searchID).map { search in
            if search.isCompleted {
                promise.fulfill(search.result!)
            } else {
                delay(1.0, f: poll)
            }
        }
    }
    poll()
    return promise.future!
}

createSearch().flatMap { search in
    fetchResult(search.searchID).map { result in
        print(result)
    }
}.onFailure { error in
    print("Error: \(error)")
}//: [Next](@next)
