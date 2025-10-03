import Foundation
import SwiftUI
import Combine

@MainActor
class EditorViewModel: ObservableObject {
    @Published var files: [SchemeFile] = []
    @Published var openFiles: [SchemeFile] = []
    @Published var activeFileId: UUID?
    @Published var editorState: EditorState = EditorState()
    @Published var currentTheme: EditorTheme = .defaultLight
    @Published var fontSize: CGFloat = 14
    @Published var showSidebar: Bool = true
    @Published var showREPL: Bool = true
    @Published var showMinimap: Bool = false
    @Published var enableAutoComplete: Bool = true
    @Published var enableAutoIndent: Bool = true
    @Published var tabSize: Int = 2
    @Published var insertSpaces: Bool = true
    @Published var searchText: String = ""
    @Published var isSearchVisible: Bool = false
    @Published var consoleOutput: [ConsoleEntry] = []
    
    private let interpreter = SchemeInterpreterViewModel()
    private let fileManager = FileManager.default
    
    // Scheme-specific auto-complete items
    private let schemeKeywords = [
        "define", "lambda", "let", "let*", "letrec", "if", "cond", "case", "and", "or",
        "begin", "do", "quote", "quasiquote", "unquote", "unquote-splicing", "set!",
        "delay", "force", "call-with-current-continuation", "call/cc", "values",
        "call-with-values", "dynamic-wind", "eval", "apply", "map", "for-each",
        "null?", "pair?", "list?", "symbol?", "procedure?", "boolean?", "number?",
        "char?", "string?", "vector?", "cons", "car", "cdr", "list", "append",
        "reverse", "length", "memq", "memv", "member", "assq", "assv", "assoc",
        "+", "-", "*", "/", "=", "<", ">", "<=", ">=", "max", "min", "abs",
        "quotient", "remainder", "modulo", "gcd", "lcm", "floor", "ceiling",
        "truncate", "round", "exp", "log", "sin", "cos", "tan", "asin", "acos",
        "atan", "sqrt", "expt", "make-string", "string", "string-length",
        "string-ref", "string-set!", "string=?", "string<?", "string>?",
        "string<=?", "string>=?", "substring", "string-append", "string->list",
        "list->string", "string-copy", "string-fill!", "display", "newline",
        "write", "read", "read-char", "peek-char", "eof-object?", "char-ready?",
        "write-char", "load", "transcript-on", "transcript-off"
    ]
    
    init() {
        setupDefaultFiles()
        updateAutoCompleteItems()
    }
    
    var activeFile: SchemeFile? {
        guard let activeFileId = activeFileId else { return nil }
        return openFiles.first { $0.id == activeFileId }
    }
    
    // MARK: - File Operations
    
    func setupDefaultFiles() {
        let welcomeFile = SchemeFile(
            name: "welcome.scm",
            content: """
            ;; Welcome to Scheme Editor!
            ;; This is a complete R5RS Scheme implementation with IDE features
            
            ;; Basic arithmetic
            (+ 1 2 3 4)
            (* 2 3 4)
            (/ 10 2)
            
            ;; Function definition
            (define (factorial n)
              (if (<= n 1)
                  1
                  (* n (factorial (- n 1)))))
            
            ;; Test the function
            (factorial 5)
            
            ;; Higher-order functions
            (define (square x) (* x x))
            (map square '(1 2 3 4 5))
            
            ;; List operations
            (define my-list '(a b c d e))
            (car my-list)
            (cdr my-list)
            (append my-list '(f g h))
            
            ;; String operations
            (string-append "Hello" " " "World!")
            (string-length "Scheme")
            
            ;; Conditional expressions
            (cond
              ((> 5 3) "five is greater than three")
              ((< 5 3) "five is less than three")
              (else "five equals three"))
            """,
            path: "/welcome.scm"
        )
        
        let examplesFile = SchemeFile(
            name: "examples.scm",
            content: """
            ;; Advanced Scheme Examples
            
            ;; Closure and lexical scoping
            (define (make-counter)
              (let ((count 0))
                (lambda ()
                  (set! count (+ count 1))
                  count)))
            
            (define counter1 (make-counter))
            (define counter2 (make-counter))
            
            (counter1)  ; => 1
            (counter1)  ; => 2
            (counter2)  ; => 1
            (counter1)  ; => 3
            
            ;; Recursive list processing
            (define (filter predicate lst)
              (cond
                ((null? lst) '())
                ((predicate (car lst))
                 (cons (car lst) (filter predicate (cdr lst))))
                (else (filter predicate (cdr lst)))))
            
            (filter (lambda (x) (> x 5)) '(1 6 2 8 3 9 4))
            
            ;; Quicksort implementation
            (define (quicksort lst)
              (if (null? lst)
                  '()
                  (let ((pivot (car lst))
                        (rest (cdr lst)))
                    (append
                      (quicksort (filter (lambda (x) (< x pivot)) rest))
                      (list pivot)
                      (quicksort (filter (lambda (x) (>= x pivot)) rest))))))
            
            (quicksort '(3 1 4 1 5 9 2 6 5 3 5))
            """,
            path: "/examples.scm"
        )
        
        files = [welcomeFile, examplesFile]
        openFiles = [welcomeFile]
        activeFileId = welcomeFile.id
    }
    
    func createNewFile(name: String = "untitled.scm") {
        let newFile = SchemeFile(
            name: name,
            content: ";; New Scheme file\n\n",
            path: "/\(name)"
        )
        files.append(newFile)
        openFile(newFile)
    }
    
    func openFile(_ file: SchemeFile) {
        if !openFiles.contains(where: { $0.id == file.id }) {
            openFiles.append(file)
        }
        activeFileId = file.id
    }
    
    func closeFile(_ file: SchemeFile) {
        openFiles.removeAll { $0.id == file.id }
        if activeFileId == file.id {
            activeFileId = openFiles.first?.id
        }
    }
    
    func saveFile(_ file: SchemeFile) {
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files[index] = file
        }
        if let index = openFiles.firstIndex(where: { $0.id == file.id }) {
            openFiles[index] = file
        }
        addConsoleEntry("Saved: \(file.name)", type: .info)
    }
    
    func updateFileContent(_ file: SchemeFile, content: String) {
        var updatedFile = file
        updatedFile.content = content
        updatedFile.lastModified = Date()
        
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files[index] = updatedFile
        }
        if let index = openFiles.firstIndex(where: { $0.id == file.id }) {
            openFiles[index] = updatedFile
        }
    }
    
    // MARK: - Editor Features
    
    func updateAutoCompleteItems() {
        let items = schemeKeywords.map { keyword in
            AutoCompleteItem(
                text: keyword,
                kind: isFunction(keyword) ? .function : .keyword,
                detail: getDescription(for: keyword)
            )
        }
        editorState.autoCompleteItems = items
    }
    
    private func isFunction(_ keyword: String) -> Bool {
        let functions = ["cons", "car", "cdr", "list", "append", "map", "for-each",
                        "string-append", "string-length", "display", "newline"]
        return functions.contains(keyword)
    }
    
    private func getDescription(for keyword: String) -> String? {
        let descriptions = [
            "define": "Define a variable or function",
            "lambda": "Create an anonymous function",
            "if": "Conditional expression",
            "cond": "Multi-way conditional",
            "let": "Local variable binding",
            "cons": "Construct a pair",
            "car": "First element of a pair",
            "cdr": "Rest of a pair",
            "list": "Create a list",
            "append": "Concatenate lists",
            "map": "Apply function to each element",
            "display": "Print value to output",
            "+": "Addition",
            "-": "Subtraction",
            "*": "Multiplication",
            "/": "Division"
        ]
        return descriptions[keyword]
    }
    
    func formatCode(_ content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var formatted: [String] = []
        var indentLevel = 0
        let indentString = insertSpaces ? String(repeating: " ", count: tabSize) : "\t"
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                formatted.append("")
                continue
            }
            
            // Count opening and closing parentheses
            let openParens = trimmed.filter { $0 == "(" }.count
            let closeParens = trimmed.filter { $0 == ")" }.count
            
            // Decrease indent for closing parens at start
            if trimmed.hasPrefix(")") {
                indentLevel = max(0, indentLevel - closeParens)
            }
            
            // Add formatted line
            let indent = String(repeating: indentString, count: indentLevel)
            formatted.append(indent + trimmed)
            
            // Increase indent for opening parens
            if !trimmed.hasPrefix(")") {
                indentLevel += openParens - closeParens
            } else if openParens > 0 {
                indentLevel += openParens
            }
            
            indentLevel = max(0, indentLevel)
        }
        
        return formatted.joined(separator: "\n")
    }
    
    func getAutoIndentForNewLine(at position: TextPosition, in content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        guard position.line < lines.count else { return "" }
        
        let currentLine = lines[position.line]
        let beforeCursor = String(currentLine.prefix(position.column))
        
        // Count unclosed parentheses
        let openParens = beforeCursor.filter { $0 == "(" }.count
        let closeParens = beforeCursor.filter { $0 == ")" }.count
        let indentLevel = max(0, openParens - closeParens)
        
        let indentString = insertSpaces ? String(repeating: " ", count: tabSize) : "\t"
        return String(repeating: indentString, count: indentLevel)
    }
    
    // MARK: - REPL Integration
    
    func runCurrentFile() {
        guard let file = activeFile else { return }
        runSchemeCode(file.content, filename: file.name)
    }
    
    func runSelectedCode(_ code: String) {
        runSchemeCode(code, filename: "selection")
    }
    
    private func runSchemeCode(_ code: String, filename: String) {
        addConsoleEntry("Running \(filename)...", type: .info)
        
        interpreter.currentInput = code
        interpreter.evaluateInput()
        // Get the last output entry
        if let lastOutput = interpreter.outputHistory.last {
            addConsoleEntry("=> \(lastOutput.output)", type: .output)
        }
    }
    
    func clearConsole() {
        consoleOutput.removeAll()
    }
    
    private func addConsoleEntry(_ message: String, type: ConsoleEntry.EntryType) {
        let entry = ConsoleEntry(message: message, type: type, timestamp: Date())
        consoleOutput.append(entry)
        
        // Limit console history
        if consoleOutput.count > 1000 {
            consoleOutput.removeFirst(100)
        }
    }
    
    // MARK: - Theme Management
    
    func switchTheme(to theme: EditorTheme) {
        currentTheme = theme
    }
    
    func toggleDarkMode() {
        currentTheme = currentTheme.name.contains("Dark") ? .defaultLight : .defaultDark
    }
}

struct ConsoleEntry: Identifiable {
    let id = UUID()
    let message: String
    let type: EntryType
    let timestamp: Date
    
    enum EntryType {
        case info
        case output
        case error
        case warning
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .output: return .primary
            case .error: return .red
            case .warning: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .output: return "arrow.right.circle"
            case .error: return "xmark.circle"
            case .warning: return "exclamationmark.triangle"
            }
        }
    }
}