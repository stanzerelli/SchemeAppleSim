import Foundation
import SwiftUI

/// Scheme language support utilities for syntax highlighting and editor features
struct SchemeLanguageSupport {
    
    // MARK: - Scheme Keywords and Primitives
    
    static let keywords = Set([
        // Core special forms
        "define", "lambda", "if", "cond", "case", "and", "or", "not",
        "let", "let*", "letrec", "begin", "quote", "quasiquote", "unquote",
        "unquote-splicing", "set!", "delay", "force",
        
        // Control flow
        "do", "when", "unless", "while", "for-each", "map", "filter", "fold",
        
        // Type predicates
        "null?", "pair?", "list?", "symbol?", "number?", "string?", "char?",
        "boolean?", "procedure?", "vector?", "port?", "eof-object?",
        
        // Arithmetic
        "+", "-", "*", "/", "=", "<", ">", "<=", ">=", "abs", "max", "min",
        "quotient", "remainder", "modulo", "gcd", "lcm", "numerator", "denominator",
        "floor", "ceiling", "truncate", "round", "sqrt", "expt", "log", "exp",
        "sin", "cos", "tan", "asin", "acos", "atan",
        
        // List operations
        "cons", "car", "cdr", "caar", "cadr", "cdar", "cddr", "caaar", "caadr",
        "cadar", "caddr", "cdaar", "cdadr", "cddar", "cdddr", "length", "append",
        "reverse", "list-tail", "list-ref", "memq", "memv", "member", "assq",
        "assv", "assoc",
        
        // String operations
        "make-string", "string-length", "string-ref", "string-set!", "string=?",
        "string<?", "string>?", "string<=?", "string>=?", "substring", "string-append",
        "string->list", "list->string", "string-copy", "string-fill!",
        
        // Character operations
        "char=?", "char<?", "char>?", "char<=?", "char>=?", "char-ci=?", "char-ci<?",
        "char-ci>?", "char-ci<=?", "char-ci>=?", "char-alphabetic?", "char-numeric?",
        "char-whitespace?", "char-upper-case?", "char-lower-case?", "char->integer",
        "integer->char", "char-upcase", "char-downcase",
        
        // Vector operations
        "make-vector", "vector", "vector-length", "vector-ref", "vector-set!",
        "vector->list", "list->vector", "vector-fill!",
        
        // I/O operations
        "input-port?", "output-port?", "current-input-port", "current-output-port",
        "open-input-file", "open-output-file", "close-input-port", "close-output-port",
        "read", "read-char", "peek-char", "eof-object?", "char-ready?", "write",
        "display", "newline", "write-char",
        
        // Evaluation
        "eval", "apply", "call-with-current-continuation", "call/cc",
        
        // Constants
        "#t", "#f", "#\\space", "#\\newline"
    ])
    
    static let constants = Set([
        "#t", "#f", "nil", "#\\space", "#\\newline", "#\\tab"
    ])
    
    // MARK: - Syntax Highlighting Colors
    
    static func colorForToken(_ token: String) -> Color {
        if keywords.contains(token.lowercased()) {
            return .blue
        } else if constants.contains(token.lowercased()) {
            return .purple
        } else if token.starts(with: "\"") && token.hasSuffix("\"") {
            return .green
        } else if token.starts(with: "#\\") {
            return .orange
        } else if Double(token) != nil {
            return .red
        } else if token.starts(with: ";") {
            return .gray
        }
        return .primary
    }
    
    // MARK: - Enhanced Auto-Indentation
    
    static func calculateIndentation(for line: String, previousLine: String) -> Int {
        let trimmedPrevious = previousLine.trimmingCharacters(in: .whitespaces)
        let trimmedCurrent = line.trimmingCharacters(in: .whitespaces)
        
        // Base indentation from previous line
        let previousIndent = previousLine.prefix { $0.isWhitespace }.count
        
        // If current line starts with closing paren, reduce indent
        if trimmedCurrent.hasPrefix(")") || trimmedCurrent.hasPrefix("]") {
            return max(0, previousIndent - 2)
        }
        
        // Count unclosed brackets in previous line
        let bracketDiff = countUnclosedBrackets(in: trimmedPrevious)
        let baseIndent = previousIndent + (bracketDiff * 2)
        
        // Special Scheme form indentation rules
        return calculateSchemeSpecificIndentation(
            previousLine: trimmedPrevious,
            baseIndent: baseIndent,
            previousIndent: previousIndent
        )
    }
    
    /// Calculate Scheme-specific indentation based on special forms
    private static func calculateSchemeSpecificIndentation(
        previousLine: String,
        baseIndent: Int,
        previousIndent: Int
    ) -> Int {
        // Define special forms with their indentation rules
        let specialForms: [(String, IndentRule)] = [
            ("define", .alignWithSecondArgument),
            ("lambda", .alignWithSecondArgument),
            ("let", .alignWithSecondArgument),
            ("let*", .alignWithSecondArgument),
            ("letrec", .alignWithSecondArgument),
            ("cond", .uniformIndent(4)),
            ("case", .uniformIndent(4)),
            ("if", .conditionalIndent),
            ("when", .uniformIndent(2)),
            ("unless", .uniformIndent(2)),
            ("begin", .uniformIndent(2)),
            ("do", .uniformIndent(2))
        ]
        
        // Check for special forms
        for (form, rule) in specialForms {
            if let range = previousLine.range(of: "(\(form)") {
                return applyIndentRule(rule, to: previousLine, baseIndent: baseIndent, previousIndent: previousIndent, formPosition: range.lowerBound)
            }
        }
        
        return baseIndent
    }
    
    /// Indentation rules for different Scheme constructs
    private enum IndentRule {
        case alignWithSecondArgument
        case uniformIndent(Int)
        case conditionalIndent
    }
    
    /// Apply specific indentation rule
    private static func applyIndentRule(
        _ rule: IndentRule,
        to line: String,
        baseIndent: Int,
        previousIndent: Int,
        formPosition: String.Index
    ) -> Int {
        switch rule {
        case .alignWithSecondArgument:
            // Try to align with the second argument if present
            return findSecondArgumentAlignment(in: line, formPosition: formPosition, baseIndent: baseIndent)
            
        case .uniformIndent(let spaces):
            return previousIndent + spaces
            
        case .conditionalIndent:
            // Special handling for if statements
            return previousIndent + (hasMultipleArguments(in: line, after: formPosition) ? 4 : 2)
        }
    }
    
    /// Find alignment position for second argument
    private static func findSecondArgumentAlignment(
        in line: String,
        formPosition: String.Index,
        baseIndent: Int
    ) -> Int {
        let suffix = String(line[formPosition...])
        var parenCount = 0
        var firstArgEnd: String.Index?
        var secondArgStart: String.Index?
        
        for (offset, char) in suffix.enumerated() {
            let currentIndex = suffix.index(suffix.startIndex, offsetBy: offset)
            
            switch char {
            case "(":
                parenCount += 1
            case ")":
                parenCount -= 1
            case " ", "\t":
                if parenCount == 1 && firstArgEnd == nil {
                    // Found end of first argument (form name)
                    firstArgEnd = currentIndex
                } else if parenCount == 1 && firstArgEnd != nil && secondArgStart == nil && !char.isWhitespace {
                    // Found start of second argument
                    secondArgStart = currentIndex
                    break
                }
            default:
                if parenCount == 1 && firstArgEnd != nil && secondArgStart == nil {
                    secondArgStart = currentIndex
                    break
                }
            }
        }
        
        if let secondArgStart = secondArgStart {
            let distanceFromStart = line.distance(from: line.startIndex, to: formPosition)
            let distanceToSecondArg = suffix.distance(from: suffix.startIndex, to: secondArgStart)
            return distanceFromStart + distanceToSecondArg
        }
        
        return baseIndent
    }
    
    /// Check if a form has multiple arguments
    private static func hasMultipleArguments(in line: String, after position: String.Index) -> Bool {
        let suffix = String(line[position...])
        var parenCount = 0
        var spaceCount = 0
        
        for char in suffix {
            switch char {
            case "(":
                parenCount += 1
            case ")":
                parenCount -= 1
                if parenCount == 0 { break }
            case " ", "\t":
                if parenCount == 1 {
                    spaceCount += 1
                }
            default:
                break
            }
        }
        
        return spaceCount >= 2 // Form name + at least one space + arguments
    }
    
    /// Count unclosed brackets in a line
    private static func countUnclosedBrackets(in line: String) -> Int {
        var count = 0
        var inString = false
        var inComment = false
        var previousChar: Character = " "
        
        for char in line {
            switch char {
            case "\"":
                if previousChar != "\\" {
                    inString.toggle()
                }
            case ";":
                if !inString {
                    inComment = true
                }
            case "(", "[":
                if !inString && !inComment {
                    count += 1
                }
            case ")", "]":
                if !inString && !inComment {
                    count -= 1
                }
            default:
                break
            }
            previousChar = char
        }
        
        return max(0, count)
    }
    
    // MARK: - Enhanced Bracket Matching and Pairing
    
    static func matchingBracket(for position: Int, in text: String) -> Int? {
        let chars = Array(text)
        guard position < chars.count else { return nil }
        
        let targetChar = chars[position]
        let (opening, closing): (Character, Character)
        let direction: Int
        
        switch targetChar {
        case "(":
            opening = "("
            closing = ")"
            direction = 1
        case ")":
            opening = "("
            closing = ")"
            direction = -1
        case "[":
            opening = "["
            closing = "]"
            direction = 1
        case "]":
            opening = "["
            closing = "]"
            direction = -1
        default:
            return nil
        }
        
        var level = 0
        var current = position
        var inString = false
        var inComment = false
        
        while current >= 0 && current < chars.count {
            let char = chars[current]
            
            // Handle string and comment states
            if char == "\"" && (current == 0 || chars[current - 1] != "\\") {
                inString.toggle()
            }
            if char == ";" && !inString {
                inComment = true
            }
            if char == "\n" {
                inComment = false
            }
            
            // Only process brackets outside strings and comments
            if !inString && !inComment {
                if char == opening {
                    level += direction > 0 ? 1 : -1
                } else if char == closing {
                    level += direction > 0 ? -1 : 1
                }
                
                if level == 0 && current != position {
                    return current
                }
            }
            
            current += direction
        }
        
        return nil
    }
    
    /// Enhanced bracket pairing with smart cursor positioning
    static func processBracketInput(_ input: String, cursorPosition: Int, in text: String) -> BracketPairResult {
        guard let char = input.first else {
            return BracketPairResult(text: text, cursorOffset: 0)
        }
        
        let chars = Array(text)
        let position = min(cursorPosition, chars.count)
        
        switch char {
        case "(":
            return handleOpeningBracket("(", ")", at: position, in: text)
        case "[":
            return handleOpeningBracket("[", "]", at: position, in: text)
        case ")":
            return handleClosingBracket(")", at: position, in: text)
        case "]":
            return handleClosingBracket("]", at: position, in: text)
        case "\"":
            return handleStringQuote(at: position, in: text)
        default:
            return BracketPairResult(text: text, cursorOffset: 0)
        }
    }
    
    private static func handleOpeningBracket(_ open: String, _ close: String, at position: Int, in text: String) -> BracketPairResult {
        let prefix = String(text.prefix(position))
        let suffix = String(text.suffix(from: text.index(text.startIndex, offsetBy: position)))
        
        // Check if we're in a string or comment
        if isInStringOrComment(at: position, in: text) {
            return BracketPairResult(text: text, cursorOffset: 0)
        }
        
        // Smart bracket pairing - only add closing bracket if needed
        let shouldAddClosing = !hasMatchingClosingBracket(for: open, after: position, in: text)
        
        if shouldAddClosing {
            let newText = prefix + open + close + suffix
            return BracketPairResult(text: newText, cursorOffset: 1) // Position cursor between brackets
        } else {
            let newText = prefix + open + suffix
            return BracketPairResult(text: newText, cursorOffset: 1)
        }
    }
    
    private static func handleClosingBracket(_ close: String, at position: Int, in text: String) -> BracketPairResult {
        let chars = Array(text)
        
        // Check if the next character is already the closing bracket
        if position < chars.count && String(chars[position]) == close {
            // Skip over the existing closing bracket
            return BracketPairResult(text: text, cursorOffset: 1, skipExisting: true)
        }
        
        return BracketPairResult(text: text, cursorOffset: 0)
    }
    
    private static func handleStringQuote(at position: Int, in text: String) -> BracketPairResult {
        let prefix = String(text.prefix(position))
        let suffix = String(text.suffix(from: text.index(text.startIndex, offsetBy: position)))
        
        // Check if we're already in a string
        if isInString(at: position, in: text) {
            return BracketPairResult(text: text, cursorOffset: 0)
        }
        
        // Add closing quote
        let newText = prefix + "\"\"" + suffix
        return BracketPairResult(text: newText, cursorOffset: 1)
    }
    
    private static func isInStringOrComment(at position: Int, in text: String) -> Bool {
        let prefix = String(text.prefix(position))
        var inString = false
        var inComment = false
        
        for (i, char) in prefix.enumerated() {
            if char == "\"" && (i == 0 || prefix[prefix.index(prefix.startIndex, offsetBy: i - 1)] != "\\") {
                inString.toggle()
            }
            if char == ";" && !inString {
                inComment = true
            }
            if char == "\n" {
                inComment = false
            }
        }
        
        return inString || inComment
    }
    
    private static func isInString(at position: Int, in text: String) -> Bool {
        let prefix = String(text.prefix(position))
        var inString = false
        
        for (i, char) in prefix.enumerated() {
            if char == "\"" && (i == 0 || prefix[prefix.index(prefix.startIndex, offsetBy: i - 1)] != "\\") {
                inString.toggle()
            }
        }
        
        return inString
    }
    
    private static func hasMatchingClosingBracket(for opening: String, after position: Int, in text: String) -> Bool {
        let closing = opening == "(" ? ")" : "]"
        let suffix = String(text.suffix(from: text.index(text.startIndex, offsetBy: position)))
        
        var level = 1
        var inString = false
        var inComment = false
        
        for char in suffix {
            if char == "\"" {
                inString.toggle()
            }
            if char == ";" && !inString {
                inComment = true
            }
            if char == "\n" {
                inComment = false
            }
            
            if !inString && !inComment {
                if String(char) == opening {
                    level += 1
                } else if String(char) == closing {
                    level -= 1
                    if level == 0 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    /// Result of bracket pairing operation
    struct BracketPairResult {
        let text: String
        let cursorOffset: Int
        let skipExisting: Bool
        
        init(text: String, cursorOffset: Int, skipExisting: Bool = false) {
            self.text = text
            self.cursorOffset = cursorOffset
            self.skipExisting = skipExisting
        }
    }
    
    // MARK: - Code Completion
    
    static func completionSuggestions(for prefix: String) -> [String] {
        let lowercasePrefix = prefix.lowercased()
        return keywords.filter { $0.hasPrefix(lowercasePrefix) }.sorted()
    }
    
    // MARK: - Pretty Printing
    
    static func formatSchemeCode(_ code: String) -> String {
        var result = ""
        var indentLevel = 0
        var inString = false
        var inComment = false
        var previousChar: Character = " "
        
        for char in code {
            switch char {
            case "\"":
                if previousChar != "\\" {
                    inString.toggle()
                }
                result.append(char)
                
            case ";":
                if !inString {
                    inComment = true
                }
                result.append(char)
                
            case "\n":
                inComment = false
                result.append(char)
                if !inString && !inComment {
                    result.append(String(repeating: " ", count: indentLevel * 2))
                }
                
            case "(":
                if !inString && !inComment {
                    result.append(char)
                    indentLevel += 1
                } else {
                    result.append(char)
                }
                
            case ")":
                if !inString && !inComment {
                    indentLevel = max(0, indentLevel - 1)
                }
                result.append(char)
                
            default:
                result.append(char)
            }
            
            previousChar = char
        }
        
        return result
    }
    
    // MARK: - Scheme Symbol Insertion Helpers
    
    static let commonSymbols = [
        ("λ", "lambda"),
        ("→", "->"),
        ("≤", "<="),
        ("≥", ">="),
        ("≠", "not equal"),
        ("∧", "and"),
        ("∨", "or"),
        ("¬", "not"),
        ("∀", "for all"),
        ("∃", "exists"),
        ("∈", "element of"),
        ("∅", "empty set")
    ]
}