import Foundation

// MARK: - List Primitives
struct ListPrimitives {
    static func register(in env: Environment) {
        env.define(symbol: "cons", value: .procedure(.primitive(cons)))
        env.define(symbol: "car", value: .procedure(.primitive(car)))
        env.define(symbol: "cdr", value: .procedure(.primitive(cdr)))
        env.define(symbol: "list", value: .procedure(.primitive(list)))
        env.define(symbol: "length", value: .procedure(.primitive(length)))
        env.define(symbol: "append", value: .procedure(.primitive(append)))
        env.define(symbol: "reverse", value: .procedure(.primitive(reverse)))
        env.define(symbol: "list-ref", value: .procedure(.primitive(listRef)))
        env.define(symbol: "list-tail", value: .procedure(.primitive(listTail)))
        env.define(symbol: "member", value: .procedure(.primitive(member)))
        env.define(symbol: "memq", value: .procedure(.primitive(memq)))
        env.define(symbol: "memv", value: .procedure(.primitive(memv)))
        env.define(symbol: "assoc", value: .procedure(.primitive(assoc)))
        env.define(symbol: "assq", value: .procedure(.primitive(assq)))
        env.define(symbol: "assv", value: .procedure(.primitive(assv)))
    }
    
    static func cons(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        return .pair(args[0], args[1])
    }
    
    static func car(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return try args[0].car()
    }
    
    static func cdr(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        return try args[0].cdr()
    }
    
    static func list(args: [SExpression]) throws -> SExpression {
        return SExpression.fromArray(args)
    }
    
    static func length(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        let list = args[0]
        
        if list.isNull {
            return .number(0)
        }
        
        guard list.isList else {
            throw SchemeError.typeMismatch("length: Expected proper list")
        }
        
        let array = try list.toArray()
        return .number(Double(array.count))
    }
    
    static func append(args: [SExpression]) throws -> SExpression {
        guard !args.isEmpty else {
            return .null
        }
        
        if args.count == 1 {
            return args[0]
        }
        
        var result = args.last!
        
        // Process from right to left, excluding the last element
        for list in args.dropLast().reversed() {
            if list.isNull {
                continue
            }
            
            guard list.isList else {
                throw SchemeError.typeMismatch("append: Expected proper list")
            }
            
            let elements = try list.toArray()
            for element in elements.reversed() {
                result = .pair(element, result)
            }
        }
        
        return result
    }
    
    static func reverse(args: [SExpression]) throws -> SExpression {
        guard args.count == 1 else { 
            throw SchemeError.incorrectArity(expected: 1, actual: args.count)
        }
        let list = args[0]
        
        if list.isNull {
            return .null
        }
        
        guard list.isList else {
            throw SchemeError.typeMismatch("reverse: Expected proper list")
        }
        
        let elements = try list.toArray()
        return SExpression.fromArray(elements.reversed())
    }
    
    static func listRef(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let list = args[0]
        let index = Int(try unpackNumber(args[1]))
        
        guard index >= 0 else {
            throw SchemeError.indexOutOfBounds(index)
        }
        
        guard list.isList else {
            throw SchemeError.typeMismatch("list-ref: Expected proper list")
        }
        
        let elements = try list.toArray()
        guard index < elements.count else {
            throw SchemeError.indexOutOfBounds(index)
        }
        
        return elements[index]
    }
    
    static func listTail(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        var list = args[0]
        let k = Int(try unpackNumber(args[1]))
        
        guard k >= 0 else {
            throw SchemeError.indexOutOfBounds(k)
        }
        
        for _ in 0..<k {
            guard list.isPair else {
                throw SchemeError.typeMismatch("list-tail: List too short")
            }
            list = try list.cdr()
        }
        
        return list
    }
    
    static func member(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let obj = args[0]
        var list = args[1]
        
        while !list.isNull {
            guard list.isPair else {
                throw SchemeError.typeMismatch("member: Expected proper list")
            }
            
            let element = try list.car()
            if ComparisonPrimitives.isEqual(obj, element) {
                return list
            }
            list = try list.cdr()
        }
        
        return .boolean(false)
    }
    
    static func memq(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let obj = args[0]
        var list = args[1]
        
        while !list.isNull {
            guard list.isPair else {
                throw SchemeError.typeMismatch("memq: Expected proper list")
            }
            
            let element = try list.car()
            if ComparisonPrimitives.isEq(obj, element) {
                return list
            }
            list = try list.cdr()
        }
        
        return .boolean(false)
    }
    
    static func memv(args: [SExpression]) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let obj = args[0]
        var list = args[1]
        
        while !list.isNull {
            guard list.isPair else {
                throw SchemeError.typeMismatch("memv: Expected proper list")
            }
            
            let element = try list.car()
            if ComparisonPrimitives.isEqv(obj, element) {
                return list
            }
            list = try list.cdr()
        }
        
        return .boolean(false)
    }
    
    static func assoc(args: [SExpression]) throws -> SExpression {
        return try assocHelper(args, ComparisonPrimitives.isEqual)
    }
    
    static func assq(args: [SExpression]) throws -> SExpression {
        return try assocHelper(args, ComparisonPrimitives.isEq)
    }
    
    static func assv(args: [SExpression]) throws -> SExpression {
        return try assocHelper(args, ComparisonPrimitives.isEqv)
    }
    
    private static func assocHelper(
        _ args: [SExpression], 
        _ equalityTest: (SExpression, SExpression) -> Bool
    ) throws -> SExpression {
        guard args.count == 2 else { 
            throw SchemeError.incorrectArity(expected: 2, actual: args.count)
        }
        let obj = args[0]
        var alist = args[1]
        
        while !alist.isNull {
            guard alist.isPair else {
                throw SchemeError.typeMismatch("assoc: Expected association list")
            }
            
            let pair = try alist.car()
            guard pair.isPair else {
                throw SchemeError.typeMismatch("assoc: Expected pair in association list")
            }
            
            let key = try pair.car()
            if equalityTest(obj, key) {
                return pair
            }
            
            alist = try alist.cdr()
        }
        
        return .boolean(false)
    }
}

// MARK: - Extensions for ComparisonPrimitives access
extension ComparisonPrimitives {
    static func isEq(_ a: SExpression, _ b: SExpression) -> Bool {
        switch (a, b) {
        case (.symbol(let s1), .symbol(let s2)):
            return s1 == s2
        case (.boolean(let b1), .boolean(let b2)):
            return b1 == b2
        case (.null, .null):
            return true
        default:
            return false
        }
    }
    
    static func isEqv(_ a: SExpression, _ b: SExpression) -> Bool {
        if isEq(a, b) { return true }
        
        switch (a, b) {
        case (.number(let n1), .number(let n2)):
            return n1 == n2
        case (.string(let s1), .string(let s2)):
            return s1 == s2
        default:
            return false
        }
    }
    
    static func isEqual(_ a: SExpression, _ b: SExpression) -> Bool {
        if isEqv(a, b) { return true }
        
        switch (a, b) {
        case (.pair(let a1, let b1), .pair(let a2, let b2)):
            return isEqual(a1, a2) && isEqual(b1, b2)
        default:
            return false
        }
    }
}