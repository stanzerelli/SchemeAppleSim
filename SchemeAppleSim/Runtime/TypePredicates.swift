import Foundation

// MARK: - Type Predicates
struct TypePredicates {
    static func register(in env: Environment) {
        env.define(symbol: "null?", value: .procedure(.primitive(isNull)))
        env.define(symbol: "boolean?", value: .procedure(.primitive(isBoolean)))
        env.define(symbol: "symbol?", value: .procedure(.primitive(isSymbol)))
        env.define(symbol: "number?", value: .procedure(.primitive(isNumber)))
        env.define(symbol: "string?", value: .procedure(.primitive(isString)))
        env.define(symbol: "procedure?", value: .procedure(.primitive(isProcedure)))
        env.define(symbol: "pair?", value: .procedure(.primitive(isPair)))
        env.define(symbol: "list?", value: .procedure(.primitive(isList)))
        
        // Numeric type predicates
        env.define(symbol: "integer?", value: .procedure(.primitive(isInteger)))
        env.define(symbol: "rational?", value: .procedure(.primitive(isRational)))
        env.define(symbol: "real?", value: .procedure(.primitive(isReal)))
        env.define(symbol: "complex?", value: .procedure(.primitive(isComplex)))
        env.define(symbol: "exact?", value: .procedure(.primitive(isExact)))
        env.define(symbol: "inexact?", value: .procedure(.primitive(isInexact)))
        
        // Additional type predicates
        env.define(symbol: "zero?", value: .procedure(.primitive(isZero)))
        env.define(symbol: "positive?", value: .procedure(.primitive(isPositive)))
        env.define(symbol: "negative?", value: .procedure(.primitive(isNegative)))
        env.define(symbol: "odd?", value: .procedure(.primitive(isOdd)))
        env.define(symbol: "even?", value: .procedure(.primitive(isEven)))
    }
    
    // MARK: - Basic Type Predicates
    
    static func isNull(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return .boolean(args[0].isNull)
    }
    
    static func isBoolean(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return .boolean(args[0].isBoolean)
    }
    
    static func isSymbol(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return .boolean(args[0].isSymbol)
    }
    
    static func isNumber(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return .boolean(args[0].isNumber)
    }
    
    static func isString(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return .boolean(args[0].isString)
    }
    
    static func isProcedure(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return .boolean(args[0].isProcedure)
    }
    
    static func isPair(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return .boolean(args[0].isPair)
    }
    
    static func isList(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return .boolean(args[0].isList)
    }
    
    // MARK: - Numeric Type Predicates
    
    static func isInteger(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        guard case .number(let n) = args[0] else {
            return .boolean(false)
        }
        
        return .boolean(n.truncatingRemainder(dividingBy: 1) == 0)
    }
    
    static func isRational(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        guard case .number(let n) = args[0] else {
            return .boolean(false)
        }
        
        // In this implementation, all numbers are rational (finite floating point)
        return .boolean(n.isFinite)
    }
    
    static func isReal(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        // In this implementation, all numbers are real
        return .boolean(args[0].isNumber)
    }
    
    static func isComplex(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        // In this implementation, all numbers are complex (real is a subset of complex)
        return .boolean(args[0].isNumber)
    }
    
    static func isExact(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        guard case .number(let n) = args[0] else {
            throw SchemeError.typeMismatch("exact?: Expected number")
        }
        
        // In this implementation, integers are exact, others are inexact
        return .boolean(n.truncatingRemainder(dividingBy: 1) == 0)
    }
    
    static func isInexact(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        guard case .number(let n) = args[0] else {
            throw SchemeError.typeMismatch("inexact?: Expected number")
        }
        
        // In this implementation, non-integers are inexact
        return .boolean(n.truncatingRemainder(dividingBy: 1) != 0)
    }
    
    // MARK: - Numeric Value Predicates
    
    static func isZero(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let n = try unpackNumber(args[0])
        return .boolean(n == 0)
    }
    
    static func isPositive(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let n = try unpackNumber(args[0])
        return .boolean(n > 0)
    }
    
    static func isNegative(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let n = try unpackNumber(args[0])
        return .boolean(n < 0)
    }
    
    static func isOdd(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let n = try unpackNumber(args[0])
        
        // Check if it's an integer
        guard n.truncatingRemainder(dividingBy: 1) == 0 else {
            throw SchemeError.typeMismatch("odd?: Expected integer")
        }
        
        return .boolean(Int(n) % 2 == 1)
    }
    
    static func isEven(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let n = try unpackNumber(args[0])
        
        // Check if it's an integer
        guard n.truncatingRemainder(dividingBy: 1) == 0 else {
            throw SchemeError.typeMismatch("even?: Expected integer")
        }
        
        return .boolean(Int(n) % 2 == 0)
    }
}