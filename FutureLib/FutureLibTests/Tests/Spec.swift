import Quick
import Nimble

class Spec: QuickSpec {
    
    
    override func spec() {
        
        beforeSuite() {
            print("L0 beforeSuite ")
        }

        beforeEach() {
            print("L0 beforeEach ")
        }

        it("test L0: 1") {
            print("test L0: 1")
        }
        it("test L0: 2") {
            print("test L0: 2")
        }
        
        describe("L1") {

            beforeEach() {
                print("    L1 beforeEach ")
            }
            
            it("test L1: 1") {
                print("    test L1: 1")
            }
            it("test L1: 2") {
                print("    test L1: 2")
            }
            
            afterEach() {
                print("    L1 afterEach ")
            }
            
            
            describe("L2") {
                
                beforeEach() {
                    print("        L2 beforeEach ")
                }
                afterEach() {
                    print("        L2 afterEach ")
                }

                it("test L2: 1") {
                    print("        test L2: 1")
                }
                it("test L2: 2") {
                    print("        test L2: 2")
                }
                
            }
            
        
        }
        
        afterEach() {
            print("L0 afterEach ")
        }
        afterSuite() {
            print("L0 afterSuite ")
        }

    }
}
