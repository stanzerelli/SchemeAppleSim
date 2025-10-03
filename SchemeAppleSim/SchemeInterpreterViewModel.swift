import SwiftUI
import Combine
import UniformTypeIdentifiers

/// ViewModel for the Scheme interpreter interface
@MainActor
public class SchemeInterpreterViewModel: ObservableObject {
    @Published var outputHistory: [OutputEntry] = []
    @Published var currentInput: String = ""
    @Published var inputHistory: [String] = []
    @Published var environmentBindings: [EnvironmentBinding] = []
    @Published var showEnvironmentPanel: Bool = false
    @Published var showInputHistory: Bool = false
    @Published var showFileImporter: Bool = false
    
    private let repl: SchemeREPL
    private let evaluator: Evaluator
    private let parser: Parser
    
    public init() {
        self.repl = SchemeREPL()
        self.evaluator = Evaluator()
        self.parser = Parser()
        
        // Add welcome message
        addOutputEntry("", "Welcome to Scheme Apple Sim!\nR5RS Scheme Interpreter v1.0\n", false)
        
        // Initialize environment bindings
        refreshEnvironment()
    }
    
    // MARK: - Public Methods
    
    func evaluateInput() {
        let input = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        // Add to input history
        if !inputHistory.contains(input) {
            inputHistory.append(input)
            if inputHistory.count > 50 { // Keep last 50 inputs
                inputHistory.removeFirst()
            }
        }
        
        // Clear current input
        currentInput = ""
        showInputHistory = false
        
        // Evaluate the input
        do {
            let expressions = try parser.parseMultiple(input)
            var output = ""
            
            for expression in expressions {
                let result = try evaluator.evaluate(expression)
                let formattedResult = formatResult(result)
                output += formattedResult
                if expressions.count > 1 {
                    output += "\n"
                }
            }
            
            addOutputEntry(input, output, false)
        } catch {
            addOutputEntry(input, "Error: \(error)", true)
        }
        
        // Refresh environment if panel is visible
        if showEnvironmentPanel {
            refreshEnvironment()
        }
    }
    
    func clearOutput() {
        outputHistory.removeAll()
        addOutputEntry("", "Output cleared.\n", false)
    }
    
    func resetEnvironment() {
        evaluator.setEnvironment(StandardLibrary.createGlobalEnvironment())
        addOutputEntry("", "Environment reset to initial state.\n", false)
        refreshEnvironment()
    }
    
    func refreshEnvironment() {
        let env = evaluator.getCurrentEnvironment()
        let symbols = env.getAllSymbols().sorted()
        
        environmentBindings = symbols.compactMap { symbol in
            guard let value = try? env.lookup(symbol: symbol) else { return nil }
            
            let formattedValue = formatResult(value, maxLength: 100)
            let type = getTypeDescription(value)
            
            return EnvironmentBinding(
                name: symbol,
                value: formattedValue,
                type: type
            )
        }
    }
    
    func loadExample(_ example: SchemeExamples) {
        currentInput = example.code
    }
    
    func saveSession() {
        let panel = NSSavePanel()
        panel.title = "Save Scheme Session"
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "scheme-session.txt"
        
        panel.begin { result in
            if result == .OK, let url = panel.url {
                Task { @MainActor in
                    await self.saveSessionToFile(url)
                }
            }
        }
    }
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                await loadFileContent(url)
            }
            
        case .failure(let error):
            addOutputEntry("", "Error importing file: \(error)", true)
        }
    }
    
    // MARK: - Private Methods
    
    private func addOutputEntry(_ input: String, _ output: String, _ isError: Bool) {
        let entry = OutputEntry(
            input: input,
            output: output,
            isError: isError
        )
        outputHistory.append(entry)
        
        // Limit history to prevent memory issues
        if outputHistory.count > 1000 {
            outputHistory.removeFirst(100)
        }
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
    
    private func getTypeDescription(_ expr: SExpression) -> String {
        switch expr {
        case .number(_): return "number"
        case .string(_): return "string"
        case .symbol(_): return "symbol"
        case .boolean(_): return "boolean"
        case .null: return "null"
        case .pair(_, _): return expr.isList ? "list" : "pair"
        case .procedure(.primitive(_)): return "primitive"
        case .procedure(.compound(_, _, _, _)): return "procedure"
        }
    }
    
    private func saveSessionToFile(_ url: URL) async {
        do {
            var content = "# Scheme Apple Sim Session\n"
            content += "# Generated on \(Date())\n\n"
            
            for entry in outputHistory {
                if !entry.input.isEmpty {
                    content += "scheme> \(entry.input)\n"
                }
                if !entry.output.isEmpty {
                    content += "\(entry.output)\n"
                }
                content += "\n"
            }
            
            try content.write(to: url, atomically: true, encoding: .utf8)
            addOutputEntry("", "Session saved to \(url.lastPathComponent)", false)
        } catch {
            addOutputEntry("", "Error saving session: \(error)", true)
        }
    }
    
    private func loadFileContent(_ url: URL) async {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            
            addOutputEntry("", "Loading \(url.lastPathComponent)...", false)
            
            let expressions = try parser.parseMultiple(content)
            var results: [String] = []
            
            for expression in expressions {
                let result = try evaluator.evaluate(expression)
                results.append(formatResult(result))
            }
            
            let output = "Loaded \(expressions.count) expression(s):\n" + results.joined(separator: "\n")
            addOutputEntry("(load \"\(url.lastPathComponent)\")", output, false)
            
            if showEnvironmentPanel {
                refreshEnvironment()
            }
        } catch {
            addOutputEntry("", "Error loading file: \(error)", true)
        }
    }
}

// MARK: - Keyboard Shortcuts Support
extension SchemeInterpreterViewModel {
    func handleKeyboardShortcut(_ key: String) {
        switch key {
        case "clear":
            clearOutput()
        case "reset":
            resetEnvironment()
        case "environment":
            showEnvironmentPanel.toggle()
        case "history":
            showInputHistory.toggle()
        default:
            break
        }
    }
}