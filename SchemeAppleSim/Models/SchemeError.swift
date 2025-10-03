import Foundation

/// Errors that can occur during Scheme interpretation
public enum SchemeError: Error, LocalizedError, Equatable {
    case syntaxError(String)
    case unboundSymbol(String)
    case typeMismatch(String)
    case incorrectArity(expected: String, actual: Int)
    case divisionByZero
    case indexOutOfBounds(Int)
    case fileNotFound(String)
    case runtimeError(String)
    case evaluationError(String)
    case notImplemented(String)
    case userError(String)
    
    public var errorDescription: String? {
        switch self {
        case .syntaxError(let message):
            return "Syntax Error: \(message)"
        case .unboundSymbol(let symbol):
            return "Unbound Symbol: '\(symbol)'"
        case .typeMismatch(let message):
            return "Type Mismatch: \(message)"
        case .incorrectArity(let expected, let actual):
            return "Incorrect number of arguments: expected \(expected), got \(actual)"
        case .divisionByZero:
            return "Division by zero"
        case .indexOutOfBounds(let index):
            return "Index out of bounds: \(index)"
        case .fileNotFound(let filename):
            return "File not found: \(filename)"
        case .runtimeError(let message):
            return "Runtime Error: \(message)"
        case .evaluationError(let message):
            return "Evaluation Error: \(message)"
        case .notImplemented(let message):
            return "Not Implemented: \(message)"
        case .userError(let message):
            return "Error: \(message)"
        }
    }
    
    public var failureReason: String? {
        return errorDescription
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .syntaxError:
            return "Check your Scheme syntax. Make sure parentheses are balanced."
        case .unboundSymbol:
            return "Make sure the symbol is defined before using it."
        case .typeMismatch:
            return "Check that you're using the correct types for this operation."
        case .incorrectArity:
            return "Check the number of arguments you're passing to the function."
        case .divisionByZero:
            return "Avoid dividing by zero."
        case .indexOutOfBounds:
            return "Check that your index is within the valid range."
        case .fileNotFound:
            return "Make sure the file exists and the path is correct."
        case .runtimeError, .evaluationError:
            return "Check your code for logical errors."
        case .notImplemented:
            return "This feature is not yet implemented."
        case .userError:
            return "Review your code for the error condition."
        }
    }
}

// MARK: - Convenience Constructors
extension SchemeError {
    public static func incorrectArity(expected: Int, actual: Int) -> SchemeError {
        return .incorrectArity(expected: String(expected), actual: actual)
    }
}