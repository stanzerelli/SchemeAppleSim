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
    
    // MARK: - Auto-Indentation
    
    static func calculateIndentation(for line: String, previousLine: String) -> Int {
        let trimmedPrevious = previousLine.trimmingCharacters(in: .whitespaces)
        let trimmedCurrent = line.trimmingCharacters(in: .whitespaces)
        
        // Base indentation from previous line
        let previousIndent = previousLine.prefix { $0.isWhitespace }.count
        
        // If previous line ends with opening paren, indent further
        if trimmedPrevious.hasSuffix("(") {
            return previousIndent + 2
        }
        
        // If current line starts with closing paren, reduce indent
        if trimmedCurrent.hasPrefix(")") {
            return max(0, previousIndent - 2)
        }
        
        // Special forms get extra indentation
        let specialForms = ["define", "lambda", "let", "let*", "letrec", "cond", "case", "if"]
        for form in specialForms {
            if trimmedPrevious.contains("(\(form)") {
                return previousIndent + 2
            }
        }
        
        return previousIndent
    }
    
    // MARK: - Bracket Matching
    
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
        
        while current >= 0 && current < chars.count {
            let char = chars[current]
            
            if char == opening {
                level += direction > 0 ? 1 : -1
            } else if char == closing {
                level += direction > 0 ? -1 : 1
            }
            
            if level == 0 && current != position {
                return current
            }
            
            current += direction
        }
        
        return nil
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