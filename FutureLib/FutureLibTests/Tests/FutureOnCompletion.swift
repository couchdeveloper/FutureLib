import Quick
import Nimble
import FutureLib



func currentContextName() -> String {
    return String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))!
}

class ObjectWrapper : NSObject {
    typealias ValueType = Result<String>
    
    let value: ValueType
    
    init(_ result: ValueType) {
        self.value = result
    }
    init (value: String) {
        self.value = Result(value)
    }
    init (error: NSError) {
        self.value = Result(error)
    }
}


class FutureOnCompletion: QuickSpec {
    
    
    override func spec() {
        
        var continuationDidRun: Int32 = 0
        var promise: Promise<String>?
        var future: Future<String>?
        var result: Result<String>? = nil
        var continuationContextName:String?
        
        
        sharedExamples("eventuallyCompletes", closure: { (paramsf:SharedExampleContext)-> () in
            it ("eventually completes") {
                var timeout = 100.0
                if paramsf()["timeout"] as? Double  != nil {
                    timeout = paramsf()["timeout"] as! Double
                }
                expect(future!.isCompleted).toEventually(beTrue(), timeout: timeout)
                OSAtomicCompareAndSwap32(1, 0, &continuationDidRun)        
            }
            if paramsf()["result"] != nil {
                it ("with result") {
                    var r = (paramsf()["result"] as! ObjectWrapper).value
                    expect(r == future!.result!).to(beTrue())
               }
            }
            if paramsf()["continuation"] as! Bool == true {
                it ("did execute its continuation") {
                    expect(OSAtomicCompareAndSwap32(1, 1, &continuationDidRun)).to(beTrue())
                }
            }

            
        })

        
        sharedExamples("continuationNotExecutingOnContext", closure: {(paramsf:SharedExampleContext) -> () in
            if (paramsf()["context"] != nil) {
                let ctxName = paramsf()["context"] as! String
                it ("does not execute on context named \(ctxName)") {
                    expect(continuationContextName).notTo(beNil())
                    if let name = continuationContextName {
                        expect(ctxName).toNot(equal(name))
                    }
                }
            }
        })
        
        sharedExamples("continuationExecutingOnContext", closure: {(paramsf:SharedExampleContext) -> () in
            if (paramsf()["context"] != nil) {
                let ctxName = paramsf()["context"] as! String
                it ("does execute on context named \(ctxName)") {
                    expect(continuationContextName).notTo(beNil())
                    if let name = continuationContextName {
                        expect(ctxName).to(equal(name))
                    }
                }
            }
        })
        
        
        describe("the pending future") {
            
            FutureLib.Log.logLevel = Logger.Severity.Info
            
            beforeEach(){ () -> () in
                precondition(OSAtomicCompareAndSwap32(0, 0, &continuationDidRun))
                promise = Promise<String>()
                future = promise!.future!
            }
            
            
            context("when registering onComplete") {
                beforeEach(){ () -> () in
                    continuationContextName = nil
                    result = nil
                    OSAtomicCompareAndSwap32(1, 0, &continuationDidRun)
                    future!.onComplete { r -> () in
                        continuationContextName = currentContextName()
                        sleep(2)
                        result = r
                        precondition(OSAtomicCompareAndSwap32(0, 1, &continuationDidRun))
                    }
                }

                context("when fulfilled") {
                    beforeEach(){ () -> () in
                        promise!.fulfill("OK")
                    }
                    itBehavesLike("eventuallyCompletes") {["result": ObjectWrapper(Result<String>("OK")), "continuation": true ]}
                    itBehavesLike("continuationNotExecutingOnContext") {["context": currentContextName(), "continuation":true, ]}
                }
                
                context("when rejected") {
                    beforeEach({ () -> () in
                        promise!.reject(NSError(domain: "Test", code: -1, userInfo: nil))
                    })
                    itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result<String>(NSError(domain: "Test", code: -1, userInfo: nil))), "continuation": true]}
                    itBehavesLike("continuationNotExecutingOnContext") {["context": currentContextName()]}
                }
            }
            
            context("when registering onComplete with execution context") {
                beforeEach(){ () -> () in
                    continuationContextName = nil
                    result = nil
                    OSAtomicCompareAndSwap32(1, 0, &continuationDidRun)
                    future!.onComplete(on: dispatch_get_main_queue()) { r -> () in
                        continuationContextName = currentContextName()
                        result = r
                        precondition(OSAtomicCompareAndSwap32(0, 1, &continuationDidRun))
                    }
                }
                
                context("when fulfilled") {
                    beforeEach(){ () -> () in
                        promise!.fulfill("OK")
                    }
                    itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result<String>("OK")), "continuation": true]}
                    itBehavesLike("continuationExecutingOnContext") {["context": currentContextName()]}
                }
                
                context("when rejected") {
                    beforeEach({ () -> () in
                        promise!.reject(NSError(domain: "Test", code: -1, userInfo: nil))
                    })
                    itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result(NSError(domain: "Test", code: -1, userInfo: nil))), "continuation": true]}
                    itBehavesLike("continuationExecutingOnContext") {["context": currentContextName()]}
                }
            }
            
            context("when registering onSuccess") {
                beforeEach(){ () -> () in
                    continuationContextName = nil
                    result = nil
                    OSAtomicCompareAndSwap32(1, 0, &continuationDidRun)
                    future!.onSuccess() { str -> () in
                        continuationContextName = currentContextName()
                        result = Result(str)
                        precondition(OSAtomicCompareAndSwap32(0, 1, &continuationDidRun))
                    }
                }
                
                context("when fulfilled") {
                    beforeEach(){ () -> () in
                        promise!.fulfill("OK")
                    }
                    itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result("OK")), "continuation": true]}
                    itBehavesLike("continuationNotExecutingOnContext") {["context": currentContextName()]}
                }
                
                context("when rejected") {
                    beforeEach({ () -> () in
                        promise!.reject(NSError(domain: "Test", code: -1, userInfo: nil))
                    })
                    itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result(NSError(domain: "Test", code: -1, userInfo: nil))), "continuation": false]}
                }
            }
            
            context("when registering onSuccess with execution context") {
                beforeEach(){ () -> () in
                    continuationContextName = nil
                    result = nil
                    OSAtomicCompareAndSwap32(1, 0, &continuationDidRun)
                    future!.onSuccess(on: dispatch_get_main_queue()) { str -> () in
                        continuationContextName = currentContextName()
                        result = Result(str)
                        precondition(OSAtomicCompareAndSwap32(0, 1, &continuationDidRun))
                    }
                }
                
                context("when fulfilled") {
                    beforeEach(){ () -> () in
                        promise!.fulfill("OK")
                    }
                    itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result("OK")), "continuation": true]}
                    itBehavesLike("continuationNotExecutingOnContext") {["context": currentContextName()]}
                }
                
                context("when rejected") {
                    beforeEach({ () -> () in
                        promise!.reject(NSError(domain: "Test", code: -1, userInfo: nil))
                    })
                    itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result(NSError(domain: "Test", code: -1, userInfo: nil))), "continuation": false]}
                }
            }
            
            
        }
        
        
        describe("the fulfilled future") {
            
            beforeEach(){ () -> () in
                promise = Promise<String>()
                future = promise!.future!
                promise!.fulfill("OK")
            }
            
            context("when registering onComplete") {
                beforeEach(){ () -> () in
                    continuationContextName = nil
                    result = nil
                    OSAtomicCompareAndSwap32(1, 0, &continuationDidRun)
                    future!.onComplete { r -> () in
                        continuationContextName = currentContextName()
                        result = r
                        precondition(OSAtomicCompareAndSwap32(0, 1, &continuationDidRun))
                    }
                }
                itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result("OK")), "continuation": true]}
                itBehavesLike("continuationNotExecutingOnContext") {["context": currentContextName()]}
            }
            
            context("when registering onComplete with execution context") {
                beforeEach(){ () -> () in
                    OSAtomicCompareAndSwap32(1, 0, &continuationDidRun)
                    future!.onComplete(on: dispatch_get_main_queue()) { r -> () in
                        continuationContextName = currentContextName()
                        result = r
                        precondition(OSAtomicCompareAndSwap32(0, 1, &continuationDidRun))
                    }
                }
                itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result("OK")), "continuation": true]}
                itBehavesLike("continuationExecutingOnContext") {["context": currentContextName()]}
            }
            
        }


        describe("the rejected future") {
            
            beforeEach(){ () -> () in
                promise = Promise<String>()
                future = promise!.future!
                promise!.reject(NSError(domain: "Test", code: -1, userInfo: nil))
            }
            
            context("when registering onComplete") {
                beforeEach(){ () -> () in
                    continuationContextName = nil
                    result = nil
                    OSAtomicCompareAndSwap32(1, 0, &continuationDidRun)
                    future!.onComplete { r -> () in
                        continuationContextName = currentContextName()
                        result = r
                        precondition(OSAtomicCompareAndSwap32(0, 1, &continuationDidRun))
                    }
                }
                itBehavesLike("eventuallyCompletes"){["result": ObjectWrapper(Result(NSError(domain: "Test", code: -1, userInfo: nil))), "continuation": true]}
                itBehavesLike("continuationNotExecutingOnContext") {["context": currentContextName()]}
            }
            
            context("when registering onComplete with execution context") {
                beforeEach(){ () -> () in
                    continuationContextName = nil
                    result = nil
                    OSAtomicCompareAndSwap32(1, 0, &continuationDidRun)
                    future!.onComplete(on: dispatch_get_main_queue()) { r -> () in
                        continuationContextName = currentContextName()
                        result = r
                        precondition(OSAtomicCompareAndSwap32(0, 1, &continuationDidRun))
                    }
                }
                itBehavesLike("eventuallyCompletes"){["result":     ObjectWrapper(Result(NSError(domain: "Test", code: -1, userInfo: nil))), "continuation": true]}
                itBehavesLike("continuationExecutingOnContext") {["context": currentContextName()]}
            }
            
        }
        
        
    }
}
