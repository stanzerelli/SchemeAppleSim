import Foundation

/// Tokenizes Scheme source code into individual tokens
public struct Tokenizer {
    
    /// Tokenize input string into an array of tokens
    public static func tokenize(_ input: String) -> [Token] {
        var tokens: [Token] = []
        var current = ""
        var inString = false
        var stringValue = ""
        var line = 1
        var column = 1
        
        var i = input.startIndex
        
        while i < input.endIndex {
            let char = input[i]
            let position = SourcePosition(line: line, column: column)
            
            // Update position tracking
            if char == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            
            // Handle string literals
            if char == "\"" {
                if inString {
                    // End of string
                    tokens.append(Token(type: .string(stringValue), position: position))
                    stringValue = ""
                    inString = false
                } else {
                    // Start of string
                    if !current.isEmpty {
                        tokens.append(tokenFromString(current, at: position))
                        current = ""
                    }
                    inString = true
                }
                i = input.index(after: i)
                continue
            }
            
            if inString {
                if char == "\\" && input.index(after: i) < input.endIndex {
                    // Handle escape sequences
                    i = input.index(after: i)
                    let nextChar = input[i]
                    switch nextChar {
                    case "n": stringValue += "\n"
                    case "t": stringValue += "\t"
                    case "r": stringValue += "\r"
                    case "\\": stringValue += "\\"
                    case "\"": stringValue += "\""
                    default: stringValue += String(nextChar)
                    }
                } else {
                    stringValue += String(char)
                }
                i = input.index(after: i)
                continue
            }
            
            // Handle comments
            if char == ";" {
                // Add current token if any
                if !current.isEmpty {
                    tokens.append(tokenFromString(current, at: position))
                    current = ""
                }
                // Skip to end of line
                while i < input.endIndex && input[i] != "\n" {
                    i = input.index(after: i)
                }
                continue
            }
            
            // Handle special characters
            if char == "'" {
                if !current.isEmpty {
                    tokens.append(tokenFromString(current, at: position))
                    current = ""
                }
                tokens.append(Token(type: .quote, position: position))
            } else if char == "(" {
                if !current.isEmpty {
                    tokens.append(tokenFromString(current, at: position))
                    current = ""
                }
                tokens.append(Token(type: .leftParen, position: position))
            } else if char == ")" {
                if !current.isEmpty {
                    tokens.append(tokenFromString(current, at: position))
                    current = ""
                }
                tokens.append(Token(type: .rightParen, position: position))
            } else if char.isWhitespace {
                if !current.isEmpty {
                    tokens.append(tokenFromString(current, at: position))
                    current = ""
                }
            } else {
                current += String(char)
            }
            
            i = input.index(after: i)
        }
        
        // Add final token if any
        if !current.isEmpty {
            let position = SourcePosition(line: line, column: column)
            tokens.append(tokenFromString(current, at: position))
        }
        
        return tokens
    }
    
    private static func tokenFromString(_ string: String, at position: SourcePosition) -> Token {
        // Try to parse as number
        if let number = Double(string) {
            return Token(type: .number(number), position: position)
        }
        
        // Check for boolean literals
        switch string {
        case "#t", "#true":
            return Token(type: .boolean(true), position: position)
        case "#f", "#false":
            return Token(type: .boolean(false), position: position)
        default:
            return Token(type: .symbol(string), position: position)
        }
    }
}

/// Represents a token in Scheme source code
public struct Token {
    public let type: TokenType
    public let position: SourcePosition
    
    public init(type: TokenType, position: SourcePosition) {
        self.type = type
        self.position = position
    }
}

/// Types of tokens in Scheme
public enum TokenType: Equatable {
    case leftParen
    case rightParen
    case quote
    case symbol(String)
    case number(Double)
    case boolean(Bool)
    case string(String)
}

/// Position in source code for error reporting
public struct SourcePosition {
    public let line: Int
    public let column: Int
    
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
}

// MARK: - CustomStringConvertible
extension Token: CustomStringConvertible {
    public var description: String {
        return "\(type) at \(position.line):\(position.column)"
    }
}

extension TokenType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .leftParen: return "("
        case .rightParen: return ")"
        case .quote: return "'"
        case .symbol(let s): return s
        case .number(let n): return String(n)
        case .boolean(let b): return b ? "#t" : "#f"
        case .string(let s): return "\"\(s)\""
        }
    }
}