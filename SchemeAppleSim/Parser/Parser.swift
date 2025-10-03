import Foundation

/// Parses tokens into Scheme expressions (AST)
public struct Parser {
    private var tokens: [Token]
    private var current: Int
    
    public init() {
        self.tokens = []
        self.current = 0
    }
    
    /// Parse a string of Scheme code into an expression
    public static func parse(_ input: String) throws -> SExpression {
        let tokens = Tokenizer.tokenize(input)
        var parser = Parser()
        parser.tokens = tokens
        parser.current = 0
        
        guard !tokens.isEmpty else {
            return .null
        }
        
        return try parser.parseExpression()
    }
    
    /// Parse multiple expressions from a string
    public static func parseAll(_ input: String) throws -> [SExpression] {
        let tokens = Tokenizer.tokenize(input)
        var parser = Parser()
        parser.tokens = tokens
        parser.current = 0
        
        var expressions: [SExpression] = []
        
        while !parser.isAtEnd() {
            expressions.append(try parser.parseExpression())
        }
        
        return expressions
    }
    
    /// Instance method to parse multiple expressions from a string
    public func parseMultiple(_ input: String) throws -> [SExpression] {
        return try Parser.parseAll(input)
    }
    
    // MARK: - Private Parsing Methods
    
    private mutating func parseExpression() throws -> SExpression {
        guard !isAtEnd() else {
            throw SchemeError.syntaxError("Unexpected end of input")
        }
        
        let token = currentToken()
        
        switch token.type {
        case .leftParen:
            return try parseList()
        case .quote:
            return try parseQuoted()
        case .symbol(let symbol):
            advance()
            return .symbol(symbol)
        case .number(let number):
            advance()
            return .number(number)
        case .boolean(let bool):
            advance()
            return .boolean(bool)
        case .string(let string):
            advance()
            return .string(string)
        case .rightParen:
            throw SchemeError.syntaxError("Unexpected ')' at \(token.position.line):\(token.position.column)")
        }
    }
    
    private mutating func parseList() throws -> SExpression {
        guard currentToken().type == .leftParen else {
            throw SchemeError.syntaxError("Expected '('")
        }
        advance() // consume '('
        
        // Handle empty list
        if !isAtEnd() && currentToken().type == .rightParen {
            advance() // consume ')'
            return .null
        }
        
        var elements: [SExpression] = []
        
        while !isAtEnd() && currentToken().type != .rightParen {
            elements.append(try parseExpression())
        }
        
        guard !isAtEnd() && currentToken().type == .rightParen else {
            throw SchemeError.syntaxError("Missing closing ')'")
        }
        advance() // consume ')'
        
        return SExpression.fromArray(elements)
    }
    
    private mutating func parseQuoted() throws -> SExpression {
        guard currentToken().type == .quote else {
            throw SchemeError.syntaxError("Expected quote")
        }
        advance() // consume quote
        
        let quotedExpr = try parseExpression()
        return cons(.symbol("quote"), cons(quotedExpr, .null))
    }
    
    // MARK: - Helper Methods
    
    private func isAtEnd() -> Bool {
        return current >= tokens.count
    }
    
    private func currentToken() -> Token {
        return tokens[current]
    }
    
    private mutating func advance() {
        if !isAtEnd() {
            current += 1
        }
    }
    
    private func peek() -> Token? {
        if current + 1 < tokens.count {
            return tokens[current + 1]
        }
        return nil
    }
}

// MARK: - Parser Extensions for Enhanced Error Reporting
public extension Parser {
    /// Parse with enhanced error context
    static func parseWithContext(_ input: String, filename: String? = nil) throws -> SExpression {
        do {
            return try parse(input)
        } catch let error as SchemeError {
            // Add context information to error
            switch error {
            case .syntaxError(let message):
                let contextMessage = filename.map { "In file \($0): \(message)" } ?? message
                throw SchemeError.syntaxError(contextMessage)
            default:
                throw error
            }
        }
    }
}