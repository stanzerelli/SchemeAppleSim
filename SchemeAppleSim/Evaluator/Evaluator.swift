import Foundation

// MARK: - Evaluator
public class Evaluator {
    private var environment: Environment
    private var tailCallOptimization: Bool
    private var maxRecursionDepth: Int
    private var currentRecursionDepth: Int
    
    public init(environment: Environment? = nil, enableTCO: Bool = true, maxDepth: Int = 1000) {
        self.environment = environment ?? StandardLibrary.createGlobalEnvironment()
        self.tailCallOptimization = enableTCO
        self.maxRecursionDepth = maxDepth
        self.currentRecursionDepth = 0
    }
    
    /// Evaluate a single expression in the current environment
    public func evaluate(_ expression: SExpression) throws -> SExpression {
        return try evaluateWithTailOptimization(expression, self.environment)
    }
    
    /// Evaluate multiple expressions and return the result of the last one
    public func evaluateProgram(_ expressions: [SExpression]) throws -> SExpression {
        guard !expressions.isEmpty else {
            return .null
        }
        
        var result: SExpression = .null
        for expression in expressions {
            result = try evaluate(expression)
        }
        return result
    }
    
    /// Get the current environment (for REPL introspection)
    public func getCurrentEnvironment() -> Environment {
        return environment
    }
    
    /// Set a new environment
    public func setEnvironment(_ env: Environment) {
        self.environment = env
    }
    
    /// Enable or disable tail call optimization
    public func setTailCallOptimization(_ enabled: Bool) {
        self.tailCallOptimization = enabled
    }
    
    // MARK: - Tail Call Optimization
    
    private func evaluateWithTailOptimization(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        var currentExpression = expr
        var currentEnvironment = env
        var tailCallDepth = 0
        
        while true {
            do {
                let result = try evaluateInEnvironment(currentExpression, currentEnvironment, inTailPosition: true)
                return result
            } catch let error as TailCallException {
                // Handle tail call
                if !tailCallOptimization {
                    throw SchemeError.evaluationError("Tail call optimization disabled")
                }
                
                tailCallDepth += 1
                if tailCallDepth > maxRecursionDepth {
                    throw SchemeError.evaluationError("Maximum tail call depth exceeded")
                }
                
                let continuation = error.continuation
                currentExpression = .pair(.procedure(continuation.procedure), 
                                        SExpression.fromArray(continuation.arguments))
                currentEnvironment = continuation.environment
            }
        }
    }
    
    // MARK: - Core Evaluation Logic with Tail Position Tracking
    
    private func evaluateInEnvironment(_ expr: SExpression, _ env: Environment, inTailPosition: Bool = false) throws -> SExpression {
        currentRecursionDepth += 1
        defer { currentRecursionDepth -= 1 }
        
        if currentRecursionDepth > maxRecursionDepth && !tailCallOptimization {
            throw SchemeError.evaluationError("Maximum recursion depth exceeded")
        }
        
        switch expr {
        case .number(_), .string(_), .boolean(_), .null, .unspecified:
            // Self-evaluating expressions
            return expr
            
        case .symbol(let name):
            // Variable lookup
            guard let value = env.lookup(symbol: name) else {
                throw SchemeError.unboundSymbol(name)
            }
            return value
            
        case .pair(_, _):
            // Function application or special form
            return try evaluateList(expr, env, inTailPosition: inTailPosition)
            
        case .procedure(_):
            // Procedures are values
            return expr
        }
    }
    
    private func evaluateList(_ expr: SExpression, _ env: Environment, inTailPosition: Bool = false) throws -> SExpression {
        guard expr.isPair else {
            throw SchemeError.evaluationError("Cannot evaluate non-list as application")
        }
        
        let op = try expr.car()
        
        // Check for special forms first
        if case .symbol(let name) = op {
            switch name {
            case "quote":
                return try evaluateQuote(expr, env)
            case "if":
                return try evaluateIf(expr, env, inTailPosition: inTailPosition)
            case "define":
                return try evaluateDefine(expr, env)
            case "set!":
                return try evaluateSet(expr, env)
            case "lambda":
                return try evaluateLambda(expr, env)
            case "begin":
                return try evaluateBegin(expr, env, inTailPosition: inTailPosition)
            case "cond":
                return try evaluateCond(expr, env, inTailPosition: inTailPosition)
            case "case":
                return try evaluateCase(expr, env, inTailPosition: inTailPosition)
            case "and":
                return try evaluateAnd(expr, env, inTailPosition: inTailPosition)
            case "or":
                return try evaluateOr(expr, env, inTailPosition: inTailPosition)
            case "let":
                return try evaluateLet(expr, env, inTailPosition: inTailPosition)
            case "let*":
                return try evaluateLetStar(expr, env, inTailPosition: inTailPosition)
            case "letrec":
                return try evaluateLetRec(expr, env, inTailPosition: inTailPosition)
            default:
                break
            }
        }
        
        // Regular function application
        return try evaluateApplication(expr, env, inTailPosition: inTailPosition)
    }
    
    // MARK: - Special Forms
    
    private func evaluateQuote(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return args[0]
    }
    
    private func evaluateIf(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard args.count >= 2 && args.count <= 3 else {
            throw SchemeError.incorrectArity(expected: "2 or 3", actual: args.count)
        }
        
        let condition = try evaluateInEnvironment(args[0], env)
        let isTruthy = !condition.isFalse
        
        if isTruthy {
            return try evaluateInEnvironment(args[1], env)
        } else if args.count == 3 {
            return try evaluateInEnvironment(args[2], env)
        } else {
            return .null // undefined behavior in R5RS, but we return null
        }
    }
    
    private func evaluateDefine(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard args.count == 2 else {
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        
        let first = args[0]
        let second = args[1]
        
        if case .symbol(let name) = first {
            // Simple variable definition: (define x value)
            let value = try evaluateInEnvironment(second, env)
            env.define(symbol: name, value: value)
            return .symbol(name)
        } else if first.isPair {
            // Function definition: (define (name args...) body)
            let nameAndArgs = try first.toArray()
            guard !nameAndArgs.isEmpty else {
                throw SchemeError.syntaxError("define: Empty function signature")
            }
            
            guard case .symbol(let name) = nameAndArgs[0] else {
                throw SchemeError.syntaxError("define: Function name must be a symbol")
            }
            
            let parameters = Array(nameAndArgs[1...])
            let lambda = SExpression.pair(.symbol("lambda"), 
                                        .pair(SExpression.fromArray(parameters), 
                                              .pair(second, .null)))
            let procedure = try evaluateInEnvironment(lambda, env)
            env.define(symbol: name, value: procedure)
            return .symbol(name)
        } else {
            throw SchemeError.syntaxError("define: Invalid syntax")
        }
    }
    
    private func evaluateSet(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard args.count == 2 else {
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        
        guard case .symbol(let name) = args[0] else {
            throw SchemeError.syntaxError("set!: First argument must be a symbol")
        }
        
        let value = try evaluateInEnvironment(args[1], env)
        try env.set(symbol: name, value: value)
        return .null
    }
    
    private func evaluateLambda(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard args.count >= 2 else {
            throw SchemeError.incorrectArity(expected: "at least 2", actual: args.count)
        }
        
        let params = args[0]
        let body = Array(args[1...])
        
        // Extract parameter names
        var paramNames: [String] = []
        var variadic = false
        
        if params.isNull {
            // No parameters
        } else if case .symbol(let name) = params {
            // Variadic: (lambda args body)
            paramNames = [name]
            variadic = true
        } else if params.isList {
            // Fixed arity: (lambda (a b c) body)
            let paramArray = try params.toArray()
            for param in paramArray {
                guard case .symbol(let name) = param else {
                    throw SchemeError.syntaxError("lambda: Parameter must be a symbol")
                }
                paramNames.append(name)
            }
        } else {
            // Dotted list: (lambda (a b . rest) body)
            var current = params
            while current.isPair {
                let car = try current.car()
                guard case .symbol(let name) = car else {
                    throw SchemeError.syntaxError("lambda: Parameter must be a symbol")
                }
                paramNames.append(name)
                current = try current.cdr()
            }
            
            if !current.isNull {
                guard case .symbol(let restName) = current else {
                    throw SchemeError.syntaxError("lambda: Rest parameter must be a symbol")
                }
                paramNames.append(restName)
                variadic = true
            }
        }
        
        return .procedure(.compound(paramNames, body, env, variadic))
    }
    
    private func evaluateBegin(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard !args.isEmpty else {
            throw SchemeError.incorrectArity(expected: "at least 1", actual: 0)
        }
        
        var result: SExpression = .null
        for arg in args {
            result = try evaluateInEnvironment(arg, env)
        }
        return result
    }
    
    private func evaluateCond(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let clauses = try expr.cdr().toArray()
        
        for clause in clauses {
            guard clause.isList else {
                throw SchemeError.syntaxError("cond: Each clause must be a list")
            }
            
            let clauseItems = try clause.toArray()
            guard !clauseItems.isEmpty else {
                throw SchemeError.syntaxError("cond: Empty clause")
            }
            
            let test = clauseItems[0]
            
            // Handle (else expr...)
            if case .symbol("else") = test {
                if clauseItems.count == 1 {
                    return .null
                } else {
                    return try evaluateBegin(.pair(.symbol("begin"), 
                                                 SExpression.fromArray(Array(clauseItems[1...]))), env)
                }
            }
            
            // Evaluate test
            let testResult = try evaluateInEnvironment(test, env)
            if !testResult.isFalse {
                if clauseItems.count == 1 {
                    return testResult
                } else {
                    return try evaluateBegin(.pair(.symbol("begin"), 
                                                 SExpression.fromArray(Array(clauseItems[1...]))), env)
                }
            }
        }
        
        return .null
    }
    
    private func evaluateCase(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard args.count >= 1 else {
            throw SchemeError.incorrectArity(expected: "at least 1", actual: args.count)
        }
        
        let key = try evaluateInEnvironment(args[0], env)
        let clauses = Array(args[1...])
        
        for clause in clauses {
            guard clause.isList else {
                throw SchemeError.syntaxError("case: Each clause must be a list")
            }
            
            let clauseItems = try clause.toArray()
            guard clauseItems.count >= 2 else {
                throw SchemeError.syntaxError("case: Clause must have at least 2 elements")
            }
            
            let datums = clauseItems[0]
            let expressions = Array(clauseItems[1...])
            
            // Handle (else expr...)
            if case .symbol("else") = datums {
                return try evaluateBegin(.pair(.symbol("begin"), 
                                             SExpression.fromArray(expressions)), env)
            }
            
            // Check if key matches any datum
            guard datums.isList else {
                throw SchemeError.syntaxError("case: Datum list must be a proper list")
            }
            
            let datumArray = try datums.toArray()
            for datum in datumArray {
                if ComparisonPrimitives.isEqv(key, datum) {
                    return try evaluateBegin(.pair(.symbol("begin"), 
                                                 SExpression.fromArray(expressions)), env)
                }
            }
        }
        
        return .null
    }
    
    private func evaluateAnd(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        
        if args.isEmpty {
            return .boolean(true)
        }
        
        for i in 0..<args.count {
            let result = try evaluateInEnvironment(args[i], env)
            if result.isFalse {
                return .boolean(false)
            }
            if i == args.count - 1 {
                return result // Return the last value if all are truthy
            }
        }
        
        return .boolean(true)
    }
    
    private func evaluateOr(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        
        if args.isEmpty {
            return .boolean(false)
        }
        
        for arg in args {
            let result = try evaluateInEnvironment(arg, env)
            if !result.isFalse {
                return result // Return the first truthy value
            }
        }
        
        return .boolean(false)
    }
    
    private func evaluateLet(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard args.count >= 2 else {
            throw SchemeError.incorrectArity(expected: "at least 2", actual: args.count)
        }
        
        let bindings = args[0]
        let body = Array(args[1...])
        
        guard bindings.isList else {
            throw SchemeError.syntaxError("let: Bindings must be a list")
        }
        
        let bindingArray = try bindings.toArray()
        let newEnv = Environment(parent: env)
        
        // Evaluate all values in the original environment first
        var values: [SExpression] = []
        var names: [String] = []
        
        for binding in bindingArray {
            guard binding.isList else {
                throw SchemeError.syntaxError("let: Each binding must be a list")
            }
            
            let bindingItems = try binding.toArray()
            guard bindingItems.count == 2 else {
                throw SchemeError.syntaxError("let: Each binding must have exactly 2 elements")
            }
            
            guard case .symbol(let name) = bindingItems[0] else {
                throw SchemeError.syntaxError("let: Binding name must be a symbol")
            }
            
            names.append(name)
            values.append(try evaluateInEnvironment(bindingItems[1], env))
        }
        
        // Define bindings in new environment
        for (name, value) in zip(names, values) {
            newEnv.define(symbol: name, value: value)
        }
        
        return try evaluateBegin(.pair(.symbol("begin"), SExpression.fromArray(body)), newEnv)
    }
    
    private func evaluateLetStar(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard args.count >= 2 else {
            throw SchemeError.incorrectArity(expected: "at least 2", actual: args.count)
        }
        
        let bindings = args[0]
        let body = Array(args[1...])
        
        guard bindings.isList else {
            throw SchemeError.syntaxError("let*: Bindings must be a list")
        }
        
        let bindingArray = try bindings.toArray()
        var currentEnv = Environment(parent: env)
        
        // Evaluate and bind each variable sequentially
        for binding in bindingArray {
            guard binding.isList else {
                throw SchemeError.syntaxError("let*: Each binding must be a list")
            }
            
            let bindingItems = try binding.toArray()
            guard bindingItems.count == 2 else {
                throw SchemeError.syntaxError("let*: Each binding must have exactly 2 elements")
            }
            
            guard case .symbol(let name) = bindingItems[0] else {
                throw SchemeError.syntaxError("let*: Binding name must be a symbol")
            }
            
            let value = try evaluateInEnvironment(bindingItems[1], currentEnv)
            currentEnv.define(symbol: name, value: value)
        }
        
        return try evaluateBegin(.pair(.symbol("begin"), SExpression.fromArray(body)), currentEnv)
    }
    
    private func evaluateLetRec(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let args = try expr.cdr().toArray()
        guard args.count >= 2 else {
            throw SchemeError.incorrectArity(expected: "at least 2", actual: args.count)
        }
        
        let bindings = args[0]
        let body = Array(args[1...])
        
        guard bindings.isList else {
            throw SchemeError.syntaxError("letrec: Bindings must be a list")
        }
        
        let bindingArray = try bindings.toArray()
        let newEnv = Environment(parent: env)
        
        // First, bind all names to unspecified values
        var names: [String] = []
        var expressions: [SExpression] = []
        
        for binding in bindingArray {
            guard binding.isList else {
                throw SchemeError.syntaxError("letrec: Each binding must be a list")
            }
            
            let bindingItems = try binding.toArray()
            guard bindingItems.count == 2 else {
                throw SchemeError.syntaxError("letrec: Each binding must have exactly 2 elements")
            }
            
            guard case .symbol(let name) = bindingItems[0] else {
                throw SchemeError.syntaxError("letrec: Binding name must be a symbol")
            }
            
            names.append(name)
            expressions.append(bindingItems[1])
            newEnv.define(symbol: name, value: .null) // Placeholder
        }
        
        // Now evaluate all expressions in the new environment and update bindings
        for (name, expr) in zip(names, expressions) {
            let value = try evaluateInEnvironment(expr, newEnv)
            try newEnv.set(symbol: name, value: value)
        }
        
        return try evaluateBegin(.pair(.symbol("begin"), SExpression.fromArray(body)), newEnv)
    }
    
    // MARK: - Function Application
    
    private func evaluateApplication(_ expr: SExpression, _ env: Environment) throws -> SExpression {
        let items = try expr.toArray()
        guard !items.isEmpty else {
            throw SchemeError.syntaxError("Empty application")
        }
        
        let op = try evaluateInEnvironment(items[0], env)
        let operands = Array(items[1...])
        
        guard case .procedure(let proc) = op else {
            throw SchemeError.typeMismatch("Cannot apply non-procedure: \(op)")
        }
        
        let args = try operands.map { try evaluateInEnvironment($0, env) }
        
        return try applyProcedure(proc, args: args)
    }
    
    private func applyProcedure(_ procedure: Procedure, args: [SExpression]) throws -> SExpression {
        switch procedure {
        case .primitive(let fn):
            return try fn(args)
            
        case .compound(let params, let body, let closureEnv, let isVariadic):
            let newEnv = Environment(parent: closureEnv)
            
            if isVariadic {
                // Handle variadic procedures
                guard args.count >= params.count - 1 else {
                    throw SchemeError.incorrectArity(expected: "at least \(params.count - 1)", actual: args.count)
                }
                
                // Bind fixed parameters
                for i in 0..<(params.count - 1) {
                    newEnv.define(symbol: params[i], value: args[i])
                }
                
                // Bind rest parameter to remaining arguments
                let restArgs = Array(args[(params.count - 1)...])
                newEnv.define(symbol: params[params.count - 1], value: SExpression.fromArray(restArgs))
            } else {
                // Handle fixed arity procedures
                guard args.count == params.count else {
                    throw SchemeError.incorrectArity(expected: params.count, actual: args.count)
                }
                
                for (param, arg) in zip(params, args) {
                    newEnv.define(symbol: param, value: arg)
                }
            }
            
            // Evaluate body
            return try evaluateBegin(.pair(.symbol("begin"), SExpression.fromArray(body)), newEnv)
        }
    }
}