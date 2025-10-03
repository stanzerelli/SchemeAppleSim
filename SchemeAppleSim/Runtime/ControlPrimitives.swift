import Foundation

// MARK: - Control Primitives
struct ControlPrimitives {
    static func register(in env: Environment) {
        // Note: These are basic implementations
        // Special forms like if, cond, case, and, or are typically handled in the evaluator
        
        // Procedure application and evaluation
        env.define(symbol: "apply", value: .procedure(.primitive(apply)))
        env.define(symbol: "eval", value: .procedure(.primitive(eval)))
        
        // Force and delay (for lazy evaluation)
        env.define(symbol: "force", value: .procedure(.primitive(force)))
        
        // Call with current continuation (simplified)
        env.define(symbol: "call-with-current-continuation", value: .procedure(.primitive(callcc)))
        env.define(symbol: "call/cc", value: .procedure(.primitive(callcc)))
        
        // Values and call-with-values
        env.define(symbol: "values", value: .procedure(.primitive(values)))
        env.define(symbol: "call-with-values", value: .procedure(.primitive(callWithValues)))
        
        // Dynamic wind
        env.define(symbol: "dynamic-wind", value: .procedure(.primitive(dynamicWind)))
    }
    
    // MARK: - Core Control Operations
    
    static func apply(args: [SExpression]) throws -> SExpression {
        guard args.count >= 2 else {
            throw SchemeError.incorrectArity(expected: "at least 2", actual: args.count)
        }
        
        let proc = args[0]
        guard proc.isProcedure else {
            throw SchemeError.typeMismatch("apply: First argument must be a procedure")
        }
        
        // Collect all arguments except the last one
        var allArgs: [SExpression] = Array(args[1..<args.count-1])
        
        // The last argument should be a list of additional arguments
        let lastArg = args.last!
        if !lastArg.isNull {
            guard lastArg.isList else {
                throw SchemeError.typeMismatch("apply: Last argument must be a proper list")
            }
            let listArgs = try lastArg.toArray()
            allArgs.append(contentsOf: listArgs)
        }
        
        // This is a placeholder - in a full implementation, this would invoke the evaluator
        throw SchemeError.notImplemented("apply: Requires evaluator integration")
    }
    
    static func eval(args: [SExpression]) throws -> SExpression {
        guard args.count >= 1 && args.count <= 2 else {
            throw SchemeError.incorrectArity(expected: "1 or 2", actual: args.count)
        }
        
        let expr = args[0]
        // Environment argument ignored in this simple implementation
        
        // This is a placeholder - in a full implementation, this would invoke the evaluator
        throw SchemeError.notImplemented("eval: Requires evaluator integration")
    }
    
    // MARK: - Lazy Evaluation
    
    static func force(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let obj = args[0]
        
        // In this simple implementation, we don't have promises/delays
        // So force just returns its argument
        return obj
    }
    
    // MARK: - Continuations
    
    static func callcc(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        let proc = args[0]
        guard proc.isProcedure else {
            throw SchemeError.typeMismatch("call/cc: Argument must be a procedure")
        }
        
        // This is a complex feature that requires deep integration with the evaluator
        throw SchemeError.notImplemented("call/cc: Continuations not implemented")
    }
    
    // MARK: - Multiple Values
    
    static func values(args: [SExpression]) throws -> SExpression {
        // In this simple implementation, multiple values are represented as a list
        // In a full R5RS implementation, this would be a special values object
        return SExpression.fromArray(args)
    }
    
    static func callWithValues(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else {
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        
        let producer = args[0]
        let consumer = args[1]
        
        guard producer.isProcedure && consumer.isProcedure else {
            throw SchemeError.typeMismatch("call-with-values: Both arguments must be procedures")
        }
        
        // This requires evaluator integration to actually call the procedures
        throw SchemeError.notImplemented("call-with-values: Requires evaluator integration")
    }
    
    // MARK: - Dynamic Wind
    
    static func dynamicWind(args: [SExpression]) throws -> SExpression {
        guard args.count == 3 else {
            throw SchemeError.incorrectArity(expected: 3, actual: args.count)
        }
        
        let before = args[0]
        let thunk = args[1] 
        let after = args[2]
        
        guard before.isProcedure && thunk.isProcedure && after.isProcedure else {
            throw SchemeError.typeMismatch("dynamic-wind: All arguments must be procedures")
        }
        
        // This is a complex feature for exception handling and continuation integration
        throw SchemeError.notImplemented("dynamic-wind: Not implemented")
    }
}

// MARK: - Error Handling (Basic Implementation)
extension ControlPrimitives {
    static func registerErrorHandling(in env: Environment) {
        env.define(symbol: "error", value: .procedure(.primitive(error)))
    }
    
    static func error(args: [SExpression]) throws -> SExpression {
        guard !args.isEmpty else {
            throw SchemeError.incorrectArity(expected: "at least 1", actual: args.count)
        }
        
        var message = ""
        
        if case .string(let str) = args[0] {
            message = str
        } else {
            message = args[0].description
        }
        
        // Add additional arguments to error message
        if args.count > 1 {
            let additionalInfo = args[1...].map { $0.description }.joined(separator: " ")
            message += ": " + additionalInfo
        }
        
        throw SchemeError.userError(message)
    }
}