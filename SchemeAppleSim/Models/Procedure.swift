import Foundation

/// Represents a Scheme procedure (function)
public indirect enum Procedure {
    case primitive(PrimitiveFunction)
    case compound([String], [SExpression], Environment, Bool) // params, body, closure, isVariadic
    case continuation(TailContinuation) // For tail call optimization
}

/// Type alias for primitive function implementations
public typealias PrimitiveFunction = ([SExpression]) throws -> SExpression

/// Represents a tail continuation for tail call optimization
public struct TailContinuation {
    let procedure: Procedure
    let arguments: [SExpression]
    let environment: Environment
    
    public init(procedure: Procedure, arguments: [SExpression], environment: Environment) {
        self.procedure = procedure
        self.arguments = arguments
        self.environment = environment
    }
}

/// Exception for tail call optimization - not a real error
public struct TailCallException: Error {
    let continuation: TailContinuation
    
    public init(continuation: TailContinuation) {
        self.continuation = continuation
    }
}

// MARK: - Procedure Extensions for Tail Recursion
public extension Procedure {
    /// Check if this procedure is the same as another (for tail recursion detection)
    func isSameAs(_ other: Procedure) -> Bool {
        switch (self, other) {
        case (.primitive(let f1), .primitive(let f2)):
            // Primitive functions are compared by address (not perfect but workable)
            return withUnsafePointer(to: f1) { p1 in
                withUnsafePointer(to: f2) { p2 in
                    p1 == p2
                }
            }
        case (.compound(let params1, let body1, let env1, let var1), 
              .compound(let params2, let body2, let env2, let var2)):
            // For compound procedures, compare parameters and body
            return params1 == params2 && 
                   body1.count == body2.count &&
                   var1 == var2 &&
                   env1 === env2 // Same environment reference
        default:
            return false
        }
    }
    
    /// Get the parameter count for this procedure
    var parameterCount: Int {
        switch self {
        case .primitive(_):
            return -1 // Unknown arity for primitives
        case .compound(let params, _, _, let isVariadic):
            return isVariadic ? params.count - 1 : params.count
        case .continuation(_):
            return 0
        }
    }
    
    /// Check if this procedure is variadic
    var isVariadic: Bool {
        switch self {
        case .primitive(_):
            return false // Most primitives are not variadic
        case .compound(_, _, _, let variadic):
            return variadic
        case .continuation(_):
            return false
        }
    }
}