import Foundation

/// Provides the R5RS standard library procedures for Scheme
public struct StandardLibrary {
    
    /// Create a global environment with all standard library procedures
    public static func createGlobalEnvironment() -> Environment {
        let env = Environment()
        populateEnvironment(env)
        return env
    }
    
    /// Populate an environment with all standard library procedures
    public static func populateEnvironment(_ env: Environment) {
        // Arithmetic operations
        ArithmeticPrimitives.register(in: env)
        
        // Comparison operations
        ComparisonPrimitives.register(in: env)
        
        // List operations
        ListPrimitives.register(in: env)
        
        // String operations
        StringPrimitives.register(in: env)
        
        // Type predicates
        TypePredicates.register(in: env)
        
        // I/O operations
        IOPrimitives.register(in: env)
        
        // Control flow and higher-order functions
        ControlPrimitives.register(in: env)
        ControlPrimitives.registerErrorHandling(in: env)
    }
}

// MARK: - Helper Functions
internal func unpackNumber(_ expr: SExpression) throws -> Double {
    guard case .number(let num) = expr else {
        throw SchemeError.typeMismatch("Expected number, got \(expr)")
    }
    return num
}

internal func unpackBool(_ expr: SExpression) throws -> Bool {
    guard case .boolean(let b) = expr else {
        throw SchemeError.typeMismatch("Expected boolean, got \(expr)")
    }
    return b
}

internal func unpackString(_ expr: SExpression) throws -> String {
    guard case .string(let s) = expr else {
        throw SchemeError.typeMismatch("Expected string, got \(expr)")
    }
    return s
}

internal func unpackSymbol(_ expr: SExpression) throws -> String {
    guard case .symbol(let s) = expr else {
        throw SchemeError.typeMismatch("Expected symbol, got \(expr)")
    }
    return s
}