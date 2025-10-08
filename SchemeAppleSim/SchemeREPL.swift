import Foundation

/// A Read-Eval-Print Loop for interactive Scheme evaluation
public class SchemeREPL {
    private let evaluator: Evaluator
    private let parser: Parser
    private var shouldContinue: Bool = true
    
    public init() {
        self.evaluator = Evaluator()
        self.parser = Parser()
    }
    
    /// Start the interactive REPL
    public func start() {
        printWelcome()
        
        while shouldContinue {
            print("scheme> ", terminator: "")
            
            guard let input = readLine() else {
                break
            }
            
            processInput(input.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        print("Goodbye!")
    }
    
    /// Process a single line of input
    public func processInput(_ input: String) {
        // Handle REPL commands
        if input.hasPrefix(",") {
            handleREPLCommand(String(input.dropFirst()))
            return
        }
        
        // Skip empty input
        if input.isEmpty {
            return
        }
        
        // Handle special cases
        switch input {
        case "exit", "quit", "(exit)", "(quit)":
            shouldContinue = false
            return
        default:
            break
        }
        
        // Parse and evaluate Scheme expression
        do {
            let expressions = try parser.parseMultiple(input)
            
            for expression in expressions {
                let result = try evaluator.evaluate(expression)
                print(formatResult(result))
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    /// Evaluate a string and return the result (for programmatic use)
    public func evaluate(_ input: String) throws -> SExpression {
        let expressions = try parser.parseMultiple(input)
        guard !expressions.isEmpty else {
            return .null
        }
        
        return try evaluator.evaluateProgram(expressions)
    }
    
    /// Load and evaluate a file
    public func loadFile(_ filename: String) throws {
        let url = URL(fileURLWithPath: filename)
        let content = try String(contentsOf: url, encoding: .utf8)
        
        print("Loading \(filename)...")
        
        let expressions = try parser.parseMultiple(content)
        for expression in expressions {
            _ = try evaluator.evaluate(expression)
        }
        
        print("Loaded \(expressions.count) expression(s) from \(filename)")
    }
    
    // MARK: - REPL Commands
    
    private func handleREPLCommand(_ command: String) {
        let parts = command.split(separator: " ", maxSplits: 1).map(String.init)
        let cmd = parts[0]
        let arg = parts.count > 1 ? parts[1] : ""
        
        switch cmd {
        case "help", "h":
            printHelp()
        case "env", "environment":
            showEnvironment()
        case "load", "l":
            if !arg.isEmpty {
                do {
                    try loadFile(arg)
                } catch {
                    print("Error loading file: \(error)")
                }
            } else {
                print("Usage: ,load <filename>")
            }
        case "clear", "c":
            clearScreen()
        case "reset", "r":
            resetEnvironment()
        case "quit", "q", "exit":
            shouldContinue = false
        default:
            print("Unknown command: \(cmd). Type ,help for available commands.")
        }
    }
    
    private func printWelcome() {
        print("""
        Welcome to Scheme Apple Sim!
        R5RS Scheme Interpreter v1.0
        
        Type ,help for available commands or ,quit to exit.
        """)
    }
    
    private func printHelp() {
        print("""
        Available REPL commands:
        ,help       - Show this help message
        ,env        - Show current environment bindings
        ,load <file> - Load and evaluate a Scheme file
        ,clear      - Clear the screen
        ,reset      - Reset the environment to initial state
        ,quit       - Exit the REPL
        
        Enter any Scheme expression to evaluate it.
        """)
    }
    
    private func showEnvironment() {
        let env = evaluator.getCurrentEnvironment()
        let symbols = env.getAllSymbols()
        
        if symbols.isEmpty {
            print("Environment is empty")
        } else {
            print("Current environment bindings:")
            for symbol in symbols.sorted() {
                if let value = try? env.lookup(symbol: symbol) {
                    let formattedValue = formatResult(value, maxLength: 50)
                    print("  \(symbol) = \(formattedValue)")
                }
            }
        }
    }
    
    private func clearScreen() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
    }
    
    private func resetEnvironment() {
        evaluator.setEnvironment(StandardLibrary.createGlobalEnvironment())
        print("Environment reset to initial state")
    }
    
    private func formatResult(_ expr: SExpression, maxLength: Int = -1) -> String {
        let result = formatExpression(expr)
        if maxLength > 0 && result.count > maxLength {
            return String(result.prefix(maxLength - 3)) + "..."
        }
        return result
    }
    
    private func formatExpression(_ expr: SExpression) -> String {
        switch expr {
        case .number(let n):
            if n.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(n))
            } else {
                return String(n)
            }
        case .string(let s):
            return "\"\(s)\""
        case .symbol(let s):
            return s
        case .boolean(let b):
            return b ? "#t" : "#f"
        case .null:
            return "()"
        case .unspecified:
            return "#<unspecified>"
        case .pair(_, _):
            return formatList(expr)
        case .procedure(.primitive(_)):
            return "#<primitive-procedure>"
        case .procedure(.compound(let params, _, _, let isVariadic)):
            if isVariadic && !params.isEmpty {
                let fixedParams = Array(params.dropLast())
                let restParam = params.last!
                if fixedParams.isEmpty {
                    return "#<procedure(\(restParam)...)>"
                } else {
                    return "#<procedure(\(fixedParams.joined(separator: " ")) . \(restParam))>"
                }
            } else {
                return "#<procedure(\(params.joined(separator: " ")))>"
            }
        case .procedure(.continuation(_)):
            return "#<continuation>"
        }
    }
    
    private func formatList(_ expr: SExpression) -> String {
        if expr.isList {
            do {
                let elements = try expr.toArray()
                let formatted = elements.map(formatExpression).joined(separator: " ")
                return "(\(formatted))"
            } catch {
                return "#<invalid-list>"
            }
        } else {
            // Improper list (dotted pair)
            var result = "("
            var current = expr
            var first = true
            
            while case .pair(let car, let cdr) = current {
                if !first {
                    result += " "
                }
                first = false
                result += formatExpression(car)
                current = cdr
            }
            
            if !current.isNull {
                result += " . " + formatExpression(current)
            }
            
            result += ")"
            return result
        }
    }
}

// MARK: - Batch Processing
extension SchemeREPL {
    /// Evaluate multiple expressions from a string
    public func evaluateScript(_ script: String) throws -> [SExpression] {
        let expressions = try parser.parseMultiple(script)
        var results: [SExpression] = []
        
        for expression in expressions {
            let result = try evaluator.evaluate(expression)
            results.append(result)
        }
        
        return results
    }
    
    /// Run a Scheme file as a script
    public func runScript(_ filename: String) throws -> SExpression {
        let url = URL(fileURLWithPath: filename)
        let content = try String(contentsOf: url, encoding: .utf8)
        
        let expressions = try parser.parseMultiple(content)
        return try evaluator.evaluateProgram(expressions)
    }
}