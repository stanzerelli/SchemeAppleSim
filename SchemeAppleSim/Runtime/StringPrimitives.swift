import Foundation

// MARK: - String Primitives
struct StringPrimitives {
    static func register(in env: Environment) {
        env.define(symbol: "string?", value: .procedure(.primitive(isString)))
        env.define(symbol: "make-string", value: .procedure(.primitive(makeString)))
        env.define(symbol: "string", value: .procedure(.primitive(string)))
        env.define(symbol: "string-length", value: .procedure(.primitive(stringLength)))
        env.define(symbol: "string-ref", value: .procedure(.primitive(stringRef)))
        env.define(symbol: "string-set!", value: .procedure(.primitive(stringSet)))
        env.define(symbol: "string=?", value: .procedure(.primitive(stringEqual)))
        env.define(symbol: "string<?", value: .procedure(.primitive(stringLess)))
        env.define(symbol: "string>?", value: .procedure(.primitive(stringGreater)))
        env.define(symbol: "string<=?", value: .procedure(.primitive(stringLessEqual)))
        env.define(symbol: "string>=?", value: .procedure(.primitive(stringGreaterEqual)))
        env.define(symbol: "string-ci=?", value: .procedure(.primitive(stringCiEqual)))
        env.define(symbol: "string-ci<?", value: .procedure(.primitive(stringCiLess)))
        env.define(symbol: "string-ci>?", value: .procedure(.primitive(stringCiGreater)))
        env.define(symbol: "string-ci<=?", value: .procedure(.primitive(stringCiLessEqual)))
        env.define(symbol: "string-ci>=?", value: .procedure(.primitive(stringCiGreaterEqual)))
        env.define(symbol: "substring", value: .procedure(.primitive(substring)))
        env.define(symbol: "string-append", value: .procedure(.primitive(stringAppend)))
        env.define(symbol: "string->list", value: .procedure(.primitive(stringToList)))
        env.define(symbol: "list->string", value: .procedure(.primitive(listToString)))
        env.define(symbol: "string-copy", value: .procedure(.primitive(stringCopy)))
        env.define(symbol: "string-fill!", value: .procedure(.primitive(stringFill)))
    }
    
    static func isString(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return .boolean(args[0].isString)
    }
    
    static func makeString(args: [SExpression]) throws -> SExpression {
        guard args.count >= 1 && args.count <= 2 else { 
            throw SchemeError.incorrectArity(expected: "1 or 2", actual: args.count)
        }
        
        let k = Int(try unpackNumber(args[0]))
        guard k >= 0 else {
            throw SchemeError.indexOutOfBounds(k)
        }
        
        let char: Character
        if args.count == 2 {
            guard case .string(let charStr) = args[1], charStr.count == 1 else {
                throw SchemeError.typeMismatch("make-string: Second argument must be a character")
            }
            char = charStr.first!
        } else {
            char = " "
        }
        
        return .string(String(repeating: char, count: k))
    }
    
    static func string(args: [SExpression]) throws -> SExpression {
        var result = ""
        for arg in args {
            guard case .string(let charStr) = arg, charStr.count == 1 else {
                throw SchemeError.typeMismatch("string: Arguments must be characters")
            }
            result.append(charStr)
        }
        return .string(result)
    }
    
    static func stringLength(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        guard case .string(let str) = args[0] else {
            throw SchemeError.typeMismatch("string-length: Expected string")
        }
        return .number(Double(str.count))
    }
    
    static func stringRef(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        guard case .string(let str) = args[0] else {
            throw SchemeError.typeMismatch("string-ref: Expected string")
        }
        let k = Int(try unpackNumber(args[1]))
        
        guard k >= 0 && k < str.count else {
            throw SchemeError.indexOutOfBounds(k)
        }
        
        let index = str.index(str.startIndex, offsetBy: k)
        return .string(String(str[index]))
    }
    
    static func stringSet(args: [SExpression]) throws -> SExpression {
        guard args.count == 3 else { 
            throw SchemeError.incorrectArity(expected: 3, actual: args.count)
        }
        throw SchemeError.notImplemented("string-set!: Strings are immutable in this implementation")
    }
    
    static func stringEqual(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0 == $1 }
    }
    
    static func stringLess(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0 < $1 }
    }
    
    static func stringGreater(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0 > $1 }
    }
    
    static func stringLessEqual(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0 <= $1 }
    }
    
    static func stringGreaterEqual(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0 >= $1 }
    }
    
    static func stringCiEqual(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0.lowercased() == $1.lowercased() }
    }
    
    static func stringCiLess(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0.lowercased() < $1.lowercased() }
    }
    
    static func stringCiGreater(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0.lowercased() > $1.lowercased() }
    }
    
    static func stringCiLessEqual(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0.lowercased() <= $1.lowercased() }
    }
    
    static func stringCiGreaterEqual(args: [SExpression]) throws -> SExpression {
        return try stringComparison(args) { $0.lowercased() >= $1.lowercased() }
    }
    
    private static func stringComparison(
        _ args: [SExpression], 
        _ predicate: (String, String) -> Bool
    ) throws -> SExpression {
        guard args.count >= 2 else {
            throw SchemeError.incorrectArity(expected: "at least 2", actual: args.count)
        }
        
        var strings: [String] = []
        for arg in args {
            guard case .string(let str) = arg else {
                throw SchemeError.typeMismatch("Expected string arguments")
            }
            strings.append(str)
        }
        
        for i in 0..<(strings.count - 1) {
            if !predicate(strings[i], strings[i + 1]) {
                return .boolean(false)
            }
        }
        
        return .boolean(true)
    }
    
    static func substring(args: [SExpression]) throws -> SExpression {
        guard args.count == 3 else { 
            throw SchemeError.incorrectArity(expected: 3, actual: args.count)
        }
        guard case .string(let str) = args[0] else {
            throw SchemeError.typeMismatch("substring: Expected string")
        }
        let start = Int(try unpackNumber(args[1]))
        let end = Int(try unpackNumber(args[2]))
        
        guard start >= 0 && end >= start && end <= str.count else {
            throw SchemeError.indexOutOfBounds(start < 0 ? start : end)
        }
        
        let startIndex = str.index(str.startIndex, offsetBy: start)
        let endIndex = str.index(str.startIndex, offsetBy: end)
        
        return .string(String(str[startIndex..<endIndex]))
    }
    
    static func stringAppend(args: [SExpression]) throws -> SExpression {
        var result = ""
        for arg in args {
            guard case .string(let str) = arg else {
                throw SchemeError.typeMismatch("string-append: Expected string arguments")
            }
            result.append(str)
        }
        return .string(result)
    }
    
    static func stringToList(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        guard case .string(let str) = args[0] else {
            throw SchemeError.typeMismatch("string->list: Expected string")
        }
        
        let chars = str.map { SExpression.string(String($0)) }
        return SExpression.fromArray(chars)
    }
    
    static func listToString(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        let list = args[0]
        
        guard list.isList else {
            throw SchemeError.typeMismatch("list->string: Expected proper list")
        }
        
        let elements = try list.toArray()
        var result = ""
        
        for element in elements {
            guard case .string(let charStr) = element, charStr.count == 1 else {
                throw SchemeError.typeMismatch("list->string: List must contain only characters")
            }
            result.append(charStr)
        }
        
        return .string(result)
    }
    
    static func stringCopy(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        guard case .string(let str) = args[0] else {
            throw SchemeError.typeMismatch("string-copy: Expected string")
        }
        return .string(str)
    }
    
    static func stringFill(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        throw SchemeError.notImplemented("string-fill!: Strings are immutable in this implementation")
    }
}