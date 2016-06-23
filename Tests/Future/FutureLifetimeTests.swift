//
//  FutureLifetimeTests.swift
//  FutureTests
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib



class Dummy: CustomStringConvertible {
    let expect: XCTestExpectation
    let name: String
    init(name: String, expect: XCTestExpectation) {
        self.name = name
        self.expect = expect
    }
    deinit {
        NSLog("Dealloc Dummy: \(self.name)")
        expect.fulfill()
    }
    
    var description: String {
        return "Dummy: \(self.name)"
    }
}




/// Initialize and configure the Logger
internal var Log: Logger  = {
    var target = ConsoleEventTarget()
    target.writeOptions = .Sync
    return Logger(category: "FutureLibTests", verbosity: Logger.Severity.trace, targets: [target])
}()



class Foo<T> {
    typealias ArrayClosure = ([T])->()
}

class FutureLifetimeTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    func testGCD() {
        let expect1 = self.expectation(withDescription: "cancellation handler should be unregistered")
        DispatchQueue.global().after(when: .now() + .milliseconds(1000)) {
            let d1 = Dummy(name: "d1", expect: expect1) // imported object should be deinitialized after executing.
            print(d1)
        }
        waitForExpectations(withTimeout: 1000, handler: nil)
    }
    
    
    //    // Livetime
    
    func testFutureShouldDeallocateIfThereAreNoObservers() {
        let promise = Promise<Int>()
        weak var weakRef: Future<Int>?
        func t() {
            let future = promise.future
            weakRef = future
        }
        t()
        XCTAssertNil(weakRef)
    }
    
    func testContinuationShouldDeallocateAfterComplete() {
        let promise = Promise<Int>()
        let expect = self.expectation(withDescription: "continuation should deallocate")
        DispatchQueue.global().async {
            let future = promise.future!
            future.onComplete { result in
                // After this closure has been run, local strong variable (d3) should be deallocated!
                _ = Dummy(name: "Continuation", expect: expect)
                if case .failure = result {
                    XCTFail("unexpected failure")
                }
            }
        }
        schedule_after(0.1) {
            promise.resolve(Try(0))
        }
        waitForExpectations(withTimeout: 0.2, handler: nil)
    }
    
    func testImportedVariableShouldDeallocateAfterComplete() {
        let promise = Promise<Int>()
        let expect = self.expectation(withDescription: "imported variable should deallocate")
        let expect1 = self.expectation(withDescription: "onComplete handler should be called")
        DispatchQueue.global().async {
            let future = promise.future!
            let importedVariable = Dummy(name: "Imported variable", expect: expect)
            future.onComplete { result in
                // Note: after this closure has been run, imported strong variable should be deallocated!
                _ = importedVariable
                if case .failure = result {
                    XCTFail("unexpected failure")
                }
                schedule_after(0.1) {
                    expect1.fulfill()
                }
            }
        }
        schedule_after(0.1) {
            promise.resolve(Try(0))
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    // FIXME: Thread Sanitizer fails    
    func testFutureShouldDeallocateAfterThereAreNoObservers() {
        let promise = Promise<Int>()
        let expect = self.expectation(withDescription: "future should deallocate")
        DispatchQueue.global().async {
            let future = promise.future!
            future.onComplete { result in
                if case .failure = result {
                    XCTFail("unexpected")
                }
                // Note: all continuations must have been run, before future will be released
                schedule_after(0.1) { [weak future] in
                    if let _ = future {
                        XCTFail("future should be deallocated")
                    }
                    expect.fulfill()
                }
            }
        }
        schedule_after(0.1) { 
            promise.resolve(Try(0))
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    func test1() {
        let expect = self.expectation(withDescription: "dummy should deallocate")
        let expect2 = self.expectation(withDescription: "finished")
        DispatchQueue.global().async {
            let d = Dummy(name: "imported variable", expect: expect)
            schedule_after(0.1) { 
                let _ = d
                schedule_after(0.1) { [weak d] in
                    print("========test========")
                    if let _ = d {
                        XCTFail("dummy should be deallocated")
                    }
                    expect2.fulfill()
                }
            }
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    

    
    
    func testFutureShouldDeallocateIfThereAreNoObservers2() {
        let cr = CancellationRequest()
        let ct = cr.token
        let promise = Promise<Int>()
        let expect1 = self.expectation(withDescription: "cancellation handler should be unregistered")
        
        DispatchQueue.global().async {
            let future = promise.future!
            let d1 = Dummy(name: "Imported", expect: expect1) // imported object should be deinitialized when continuation will be cancelled.
            future.onComplete(ct: ct) { result in
                if case .success = result {
                    XCTFail("unexpected")
                }
                print(d1)
                print(result)
            }
        }
        
        DispatchQueue.global().after(when: .now() + .milliseconds(100)) {
            cr.cancel()
        }
        waitForExpectations(withTimeout: 1000, handler: nil)
    }
    
    func testFutureShouldDeallocateIfThereAreNoObservers3() {
        let cr = CancellationRequest()
        let ct = cr.token
        let promise = Promise<Int>()
        let expect1 = self.expectation(withDescription: "cancellation handler should be unregistered")
        let expect2 = self.expectation(withDescription: "cancellation handler should be unregistered")
        
        DispatchQueue.global().async {
            let future = promise.future!
            let d1 = Dummy(name: "d1", expect: expect1)
            let d2 = Dummy(name: "d2", expect: expect2)
            
            future.onSuccess(ct: ct) { i -> () in
                XCTFail("unexpected")
                print(d1)
            }
            future.onSuccess(ct: ct) { i -> () in
                XCTFail("unexpected")
                print(d2)
            }
        }
        DispatchQueue.global().after(when: .now() + 0.01) {
            cr.cancel()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    // FIXME: Thread Sanitizer fails    
    func testFutureShouldDeallocateIfThereAreNoObservers4() {
        let cr = CancellationRequest()
        let ct = cr.token
        let promise = Promise<Int>()
        let expect1 = self.expectation(withDescription: "cancellation handler should be unregistered")
        let expect2 = self.expectation(withDescription: "cancellation handler should be unregistered")
        let expect3 = self.expectation(withDescription: "cancellation handler should be unregistered")
        
        DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(0))).async {
            let future = promise.future!
            let d1 = Dummy(name: "d1", expect: expect1)
            let d2 = Dummy(name: "d2", expect: expect2)
            
            future.onSuccess(ct: ct) { i -> () in
                XCTFail("unexpected")
                print(d1)
            }
            future.onSuccess(ct: ct) { i -> () in
                XCTFail("unexpected")
                print(d2)
            }
            DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(0))).after(when: DispatchTime.now() + Double((Int64)(10 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)) {
                cr.cancel()
                DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes(rawValue: UInt64(0))).after(when: DispatchTime.now() + Double((Int64)(10 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)) {
                    let d3 = Dummy(name: "d3", expect: expect3)
                    future.onSuccess(ct: cr.token) { i -> () in
                        XCTFail("unexpected")
                        print(d3)
                    }
                }
            }
        }
        
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    
    
    
    func testFutureShouldNotDeallocateIfThereIsOneObserver() {
        weak var weakRef: Future<Int>?
        let promise = Promise<Int>()
        let sem = DispatchSemaphore(value: 0)
        func t() {
            let future = promise.future!
            future.onSuccess { value -> () in
                sem.signal()
            }
            weakRef = future
        }
        t()
        XCTAssertNotNil(weakRef)
        promise.fulfill(0)
        _ = sem.wait(timeout: DispatchTime.distantFuture)
        let future = weakRef
        XCTAssertNil(future)
    }
    
    func testFutureShouldCompleteWithBrokenPromiseIfPromiseDeallocatesPrematurely() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        DispatchQueue.global().async {
            let promise = Promise<String>()
            promise.future!.onFailure { error in
                if case PromiseError.brokenPromise = error where error is PromiseError {
                } else {
                    XCTFail("Invalid kind of error: \(String(reflecting: error)))")
                }
                expect.fulfill()
            }
            let delay = DispatchTime.now() + 0.05
            DispatchQueue.global().after(when: delay) {
                _ = promise
            }
        }
        waitForExpectations(withTimeout: 0.4, handler: nil)
    }
    
    
    
    func testPromiseChainShouldNotDeallocatePrematurely() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let delay = DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.global().async {
            let promise = Promise<String>()
            let future = promise.future!
            future.map { str -> String in
                usleep(1000)
                return "1"
            }
            .map { str in
                "2"
            }
            .onSuccess { str in
                expect.fulfill()
            }
            
            DispatchQueue.global().after(when: delay) {
                promise.fulfill("OK")
            }
        }
        waitForExpectations(withTimeout: 1, handler: nil)
    }
    

}
