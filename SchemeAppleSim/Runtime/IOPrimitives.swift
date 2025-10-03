import Foundation

// MARK: - I/O Primitives
struct IOPrimitives {
    static func register(in env: Environment) {
        // Display and output
        env.define(symbol: "display", value: .procedure(.primitive(display)))
        env.define(symbol: "write", value: .procedure(.primitive(write)))
        env.define(symbol: "newline", value: .procedure(.primitive(newline)))
        
        // File operations (simplified implementation)
        env.define(symbol: "load", value: .procedure(.primitive(load)))
        
        // Input operations (basic implementation)
        env.define(symbol: "read", value: .procedure(.primitive(read)))
        env.define(symbol: "read-char", value: .procedure(.primitive(readChar)))
        env.define(symbol: "peek-char", value: .procedure(.primitive(peekChar)))
        env.define(symbol: "eof-object?", value: .procedure(.primitive(isEofObject)))
        
        // Port operations (minimal implementation)
        env.define(symbol: "input-port?", value: .procedure(.primitive(isInputPort)))
        env.define(symbol: "output-port?", value: .procedure(.primitive(isOutputPort)))
        env.define(symbol: "current-input-port", value: .procedure(.primitive(currentInputPort)))
        env.define(symbol: "current-output-port", value: .procedure(.primitive(currentOutputPort)))
    }
    
    // MARK: - Output Operations
    
    static func display(args: [SExpression]) throws -> SExpression {
        guard args.count >= 1 && args.count <= 2 else {
            throw SchemeError.incorrectArity(expected: "1 or 2", actual: args.count)
        }
        
        let obj = args[0]
        // Port argument ignored in this simple implementation
        
        let output = formatForDisplay(obj)
        print(output, terminator: "")
        
        return .null
    }
    
    static func write(args: [SExpression]) throws -> SExpression {
        guard args.count >= 1 && args.count <= 2 else {
            throw SchemeError.incorrectArity(expected: "1 or 2", actual: args.count)
        }
        
        let obj = args[0]
        // Port argument ignored in this simple implementation
        
        let output = formatForWrite(obj)
        print(output, terminator: "")
        
        return .null
    }
    
    static func newline(args: [SExpression]) throws -> SExpression {
        guard args.count <= 1 else {
            throw SchemeError.incorrectArity(expected: "0 or 1", actual: args.count)
        }
        
        // Port argument ignored in this simple implementation
        print()
        
        return .null
    }
    
    // MARK: - File Operations
    
    static func load(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        guard case .string(let filename) = args[0] else {
            throw SchemeError.typeMismatch("load: Expected string filename")
        }
        
        // This is a placeholder - in a full implementation, this would:
        // 1. Read the file
        // 2. Parse the contents
        // 3. Evaluate each expression in the current environment
        throw SchemeError.notImplemented("load: File operations not fully implemented")
    }
    
    // MARK: - Input Operations
    
    static func read(args: [SExpression]) throws -> SExpression {
        guard args.count <= 1 else {
            throw SchemeError.incorrectArity(expected: "0 or 1", actual: args.count)
        }
        
        // Port argument ignored in this simple implementation
        // This is a placeholder - in a full implementation, this would read from input
        throw SchemeError.notImplemented("read: Interactive input not implemented")
    }
    
    static func readChar(args: [SExpression]) throws -> SExpression {
        guard args.count <= 1 else {
            throw SchemeError.incorrectArity(expected: "0 or 1", actual: args.count)
        }
        
        // Port argument ignored in this simple implementation
        throw SchemeError.notImplemented("read-char: Character input not implemented")
    }
    
    static func peekChar(args: [SExpression]) throws -> SExpression {
        guard args.count <= 1 else {
            throw SchemeError.incorrectArity(expected: "0 or 1", actual: args.count)
        }
        
        // Port argument ignored in this simple implementation
        throw SchemeError.notImplemented("peek-char: Character peeking not implemented")
    }
    
    static func isEofObject(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        // In this implementation, we don't have EOF objects
        return .boolean(false)
    }
    
    // MARK: - Port Operations
    
    static func isInputPort(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        // In this simple implementation, we don't have port objects
        return .boolean(false)
    }
    
    static func isOutputPort(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else {
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        
        // In this simple implementation, we don't have port objects
        return .boolean(false)
    }
    
    static func currentInputPort(args: [SExpression]) throws -> SExpression {
        guard args.count == 0 else {
            throw SchemeError.incorrectArity(expected: 0, actual: args.count)
        }
        
        // Return a symbol representing stdin
        return .symbol("stdin")
    }
    
    static func currentOutputPort(args: [SExpression]) throws -> SExpression {
        guard args.count == 0 else {
            throw SchemeError.incorrectArity(expected: 0, actual: args.count)
        }
        
        // Return a symbol representing stdout
        return .symbol("stdout")
    }
    
    // MARK: - Formatting Helpers
    
    private static func formatForDisplay(_ expr: SExpression) -> String {
        switch expr {
        case .string(let s):
            return s  // Display strings without quotes
        case .symbol(let s):
            return s
        case .number(let n):
            if n.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(n))
            } else {
                return String(n)
            }
        case .boolean(let b):
            return b ? "#t" : "#f"
        case .null:
            return "()"
        case .pair(_, _):
            return formatList(expr)
        case .procedure(_):
            return "#<procedure>"
        }
    }
    
    private static func formatForWrite(_ expr: SExpression) -> String {
        switch expr {
        case .string(let s):
            return "\"" + s.replacingOccurrences(of: "\\", with: "\\\\")
                           .replacingOccurrences(of: "\"", with: "\\\"")
                           .replacingOccurrences(of: "\n", with: "\\n")
                           .replacingOccurrences(of: "\t", with: "\\t") + "\""
        default:
            return formatForDisplay(expr)
        }
    }
    
    private static func formatList(_ expr: SExpression) -> String {
        var result = "("
        var current = expr
        var first = true
        
        while case .pair(let car, let cdr) = current {
            if !first {
                result += " "
            }
            first = false
            result += formatForDisplay(car)
            current = cdr
        }
        
        if !current.isNull {
            result += " . " + formatForDisplay(current)
        }
        
        result += ")"
        return result
    }
}