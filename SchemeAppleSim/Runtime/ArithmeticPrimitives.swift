import Foundation

// MARK: - Arithmetic Primitives
struct ArithmeticPrimitives {
    static func register(in env: Environment) {
        env.define(symbol: "+", value: .procedure(.primitive(add)))
        env.define(symbol: "-", value: .procedure(.primitive(subtract)))
        env.define(symbol: "*", value: .procedure(.primitive(multiply)))
        env.define(symbol: "/", value: .procedure(.primitive(divide)))
        env.define(symbol: "quotient", value: .procedure(.primitive(quotient)))
        env.define(symbol: "remainder", value: .procedure(.primitive(remainder)))
        env.define(symbol: "modulo", value: .procedure(.primitive(modulo)))
        env.define(symbol: "abs", value: .procedure(.primitive(abs)))
        env.define(symbol: "max", value: .procedure(.primitive(max)))
        env.define(symbol: "min", value: .procedure(.primitive(min)))
        env.define(symbol: "floor", value: .procedure(.primitive(floor)))
        env.define(symbol: "ceiling", value: .procedure(.primitive(ceiling)))
        env.define(symbol: "truncate", value: .procedure(.primitive(truncate)))
        env.define(symbol: "round", value: .procedure(.primitive(round)))
        env.define(symbol: "sqrt", value: .procedure(.primitive(sqrt)))
        env.define(symbol: "expt", value: .procedure(.primitive(expt)))
        env.define(symbol: "exp", value: .procedure(.primitive(exp)))
        env.define(symbol: "log", value: .procedure(.primitive(log)))
        env.define(symbol: "sin", value: .procedure(.primitive(sin)))
        env.define(symbol: "cos", value: .procedure(.primitive(cos)))
        env.define(symbol: "tan", value: .procedure(.primitive(tan)))
        env.define(symbol: "asin", value: .procedure(.primitive(asin)))
        env.define(symbol: "acos", value: .procedure(.primitive(acos)))
        env.define(symbol: "atan", value: .procedure(.primitive(atan)))
    }
    
    static func add(args: [SExpression]) throws -> SExpression {
        let numbers = try args.map(unpackNumber)
        return .number(numbers.reduce(0, +))
    }
    
    static func subtract(args: [SExpression]) throws -> SExpression {
        guard !args.isEmpty else {
            throw SchemeError.incorrectArity(expected: 1, actual: 0)
        }
        
        let numbers = try args.map(unpackNumber)
        
        if numbers.count == 1 {
            return .number(-numbers[0])
        } else {
            return .number(numbers.dropFirst().reduce(numbers[0], -))
        }
    }
    
    static func multiply(args: [SExpression]) throws -> SExpression {
        let numbers = try args.map(unpackNumber)
        return .number(numbers.reduce(1, *))
    }
    
    static func divide(args: [SExpression]) throws -> SExpression {
        guard !args.isEmpty else {
            throw SchemeError.incorrectArity(expected: 1, actual: 0)
        }
        
        let numbers = try args.map(unpackNumber)
        
        if numbers.count == 1 {
            guard numbers[0] != 0 else {
                throw SchemeError.divisionByZero
            }
            return .number(1 / numbers[0])
        } else {
            let result = try numbers.dropFirst().reduce(numbers[0]) { acc, n in
                guard n != 0 else {
                    throw SchemeError.divisionByZero
                }
                return acc / n
            }
            return .number(result)
        }
    }
    
    static func quotient(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else {
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        
        let dividend = try unpackNumber(args[0])
        let divisor = try unpackNumber(args[1])
        
        guard divisor != 0 else {
            throw SchemeError.divisionByZero
        }
        
        return .number(Double(Int(dividend / divisor)))
    }
    
    static func remainder(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else {
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        
        let dividend = try unpackNumber(args[0])
        let divisor = try unpackNumber(args[1])
        
        guard divisor != 0 else {
            throw SchemeError.divisionByZero
        }
        
        return .number(dividend.truncatingRemainder(dividingBy: divisor))
    }
    
    static func modulo(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else {
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        
        let dividend = try unpackNumber(args[0])
        let divisor = try unpackNumber(args[1])
        
        guard divisor != 0 else {
            throw SchemeError.divisionByZero
        }
        
        let result = dividend - divisor * Foundation.floor(dividend / divisor)
        return .number(result)
    }
    
    static func abs(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Swift.abs(number))
    }
    
    static func max(args: [SExpression]) throws -> SExpression {
        guard !args.isEmpty else {
            throw SchemeError.incorrectArity(expected: 1, actual: 0)
        }
        
        let numbers = try args.map(unpackNumber)
        return .number(numbers.max()!)
    }
    
    static func min(args: [SExpression]) throws -> SExpression {
        guard !args.isEmpty else {
            throw SchemeError.incorrectArity(expected: 1, actual: 0)
        }
        
        let numbers = try args.map(unpackNumber)
        return .number(numbers.min()!)
    }
    
    static func floor(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Foundation.floor(number))
    }
    
    static func ceiling(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Foundation.ceil(number))
    }
    
    static func truncate(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Foundation.trunc(number))
    }
    
    static func round(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Foundation.round(number))
    }
    
    static func sqrt(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        guard number >= 0 else {
            throw SchemeError.evaluationError("sqrt: negative argument")
        }
        
        return .number(Foundation.sqrt(number))
    }
    
    static func expt(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else {
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        
        let base = try unpackNumber(args[0])
        let exponent = try unpackNumber(args[1])
        
        return .number(pow(base, exponent))
    }
    
    static func exp(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Foundation.exp(number))
    }
    
    static func log(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        guard number > 0 else {
            throw SchemeError.evaluationError("log: non-positive argument")
        }
        
        return .number(Foundation.log(number))
    }
    
    static func sin(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Foundation.sin(number))
    }
    
    static func cos(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Foundation.cos(number))
    }
    
    static func tan(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Foundation.tan(number))
    }
    
    static func asin(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        guard number >= -1 && number <= 1 else {
            throw SchemeError.evaluationError("asin: argument out of range")
        }
        
        return .number(Foundation.asin(number))
    }
    
    static func acos(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        guard number >= -1 && number <= 1 else {
            throw SchemeError.evaluationError("acos: argument out of range")
        }
        
        return .number(Foundation.acos(number))
    }
    
    static func atan(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let number = try unpackNumber(args[0])
        return .number(Foundation.atan(number))
    }
}