import Foundation

// MARK: - Comparison Primitives
struct ComparisonPrimitives {
    static func register(in env: Environment) {
        env.define(symbol: "=", value: .procedure(.primitive(numericEqual)))
        env.define(symbol: "<", value: .procedure(.primitive(lessThan)))
        env.define(symbol: ">", value: .procedure(.primitive(greaterThan)))
        env.define(symbol: "<=", value: .procedure(.primitive(lessThanOrEqual)))
        env.define(symbol: ">=", value: .procedure(.primitive(greaterThanOrEqual)))
        env.define(symbol: "eq?", value: .procedure(.primitive(eq)))
        env.define(symbol: "eqv?", value: .procedure(.primitive(eqv)))
        env.define(symbol: "equal?", value: .procedure(.primitive(equal)))
    }
    
    static func numericEqual(args: [SExpression]) throws -> SExpression {
        guard args.count >= 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let numbers = try args.map(unpackNumber)
        let first = numbers.first!
        return .boolean(numbers.dropFirst().allSatisfy { $0 == first })
    }
    
    static func lessThan(args: [SExpression]) throws -> SExpression {
        guard args.count >= 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let numbers = try args.map(unpackNumber)
        return .boolean(zip(numbers, numbers.dropFirst()).allSatisfy { $0 < $1 })
    }
    
    static func greaterThan(args: [SExpression]) throws -> SExpression {
        guard args.count >= 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let numbers = try args.map(unpackNumber)
        return .boolean(zip(numbers, numbers.dropFirst()).allSatisfy { $0 > $1 })
    }
    
    static func lessThanOrEqual(args: [SExpression]) throws -> SExpression {
        guard args.count >= 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let numbers = try args.map(unpackNumber)
        return .boolean(zip(numbers, numbers.dropFirst()).allSatisfy { $0 <= $1 })
    }
    
    static func greaterThanOrEqual(args: [SExpression]) throws -> SExpression {
        guard args.count >= 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let numbers = try args.map(unpackNumber)
        return .boolean(zip(numbers, numbers.dropFirst()).allSatisfy { $0 >= $1 })
    }
    
    static func eq(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        return .boolean(eqImpl(args[0], args[1]))
    }
    
    static func eqv(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        return .boolean(eqvImpl(args[0], args[1]))
    }
    
    static func equal(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        return .boolean(equalImpl(args[0], args[1]))
    }
    
    private static func eqImpl(_ a: SExpression, _ b: SExpression) -> Bool {
        switch (a, b) {
        case (.symbol(let s1), .symbol(let s2)):
            return s1 == s2
        case (.boolean(let b1), .boolean(let b2)):
            return b1 == b2
        case (.null, .null):
            return true
        default:
            return false
        }
    }
    
    private static func eqvImpl(_ a: SExpression, _ b: SExpression) -> Bool {
        if eqImpl(a, b) { return true }
        
        switch (a, b) {
        case (.number(let n1), .number(let n2)):
            return n1 == n2
        case (.string(let s1), .string(let s2)):
            return s1 == s2
        default:
            return false
        }
    }
    
    private static func equalImpl(_ a: SExpression, _ b: SExpression) -> Bool {
        if eqvImpl(a, b) { return true }
        
        switch (a, b) {
        case (.pair(let a1, let b1), .pair(let a2, let b2)):
            return equalImpl(a1, a2) && equalImpl(b1, b2)
        default:
            return false
        }
    }
}