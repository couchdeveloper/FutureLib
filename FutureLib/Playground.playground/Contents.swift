//: Playground - noun: a place where people can play

import FutureLib



typealias CoffeeBeans = String
typealias GroundCoffee = String
typealias Milk = String
typealias FrothedMilk = String
typealias Espresso = String
typealias Cappuccino = String



enum Error : ErrorType {
    
    case GrindingError(String)
    
}


func grind(beans: CoffeeBeans) () -> Future<GroundCoffee>  {
    return future {
        print("start grinding...")
        usleep(1000)
        if (beans == "baked beans") {
            throw Error.GrindingError("are you joking?")
        }
        print("finished grinding...")
        return "ground coffee of \(beans)"
    }
    
}


grind("coffee beans")()

sleep(1)

