import Foundation

/// Represents a Scheme expression in the Abstract Syntax Tree
public indirect enum SExpression {
    case symbol(String)
    case number(Double)
    case boolean(Bool)
    case string(String)
    case pair(SExpression, SExpression)  // Cons cell for pairs/lists
    case procedure(Procedure)
    case null  // '()
}

// MARK: - Basic Operations
public extension SExpression {
    /// Extract the car (first element) of a pair
    func car() throws -> SExpression {
        guard case .pair(let car, _) = self else {
            throw SchemeError.typeMismatch("car: Expected pair, got \(self)")
        }
        return car
    }
    
    /// Extract the cdr (rest) of a pair
    func cdr() throws -> SExpression {
        guard case .pair(_, let cdr) = self else {
            throw SchemeError.typeMismatch("cdr: Expected pair, got \(self)")
        }
        return cdr
    }
    
    /// Check if this expression is null
    var isNull: Bool {
        if case .null = self { return true }
        return false
    }
    
    /// Check if this expression is a pair
    var isPair: Bool {
        if case .pair = self { return true }
        return false
    }
    
    /// Check if this expression is a number
    var isNumber: Bool {
        if case .number(_) = self { return true }
        return false
    }
    
    /// Check if this expression is a string
    var isString: Bool {
        if case .string(_) = self { return true }
        return false
    }
    
    /// Check if this expression is a symbol
    var isSymbol: Bool {
        if case .symbol(_) = self { return true }
        return false
    }
    
    /// Check if this expression is a boolean
    var isBoolean: Bool {
        if case .boolean(_) = self { return true }
        return false
    }
    
    /// Check if this expression is a procedure
    var isProcedure: Bool {
        if case .procedure(_) = self { return true }
        return false
    }
    
    /// Check if this expression is false (#f)
    var isFalse: Bool {
        if case .boolean(false) = self { return true }
        return false
    }
    
    /// Check if this expression is a proper list
    var isList: Bool {
        var current = self
        while current.isPair {
            do {
                current = try current.cdr()
            } catch {
                return false
            }
        }
        return current.isNull
    }
}

// MARK: - List Conversion
public extension SExpression {
    /// Convert a Scheme list to a Swift array
    func toArray() throws -> [SExpression] {
        var result: [SExpression] = []
        var current = self
        
        while !current.isNull {
            guard current.isPair else {
                throw SchemeError.typeMismatch("toArray: Expected proper list")
            }
            result.append(try current.car())
            current = try current.cdr()
        }
        
        return result
    }
    
    /// Create a Scheme list from a Swift array
    static func fromArray(_ array: [SExpression]) -> SExpression {
        return array.reversed().reduce(.null) { cons($1, $0) }
    }
}

// MARK: - Constructors
public func cons(_ car: SExpression, _ cdr: SExpression) -> SExpression {
    return .pair(car, cdr)
}

public func list(_ elements: SExpression...) -> SExpression {
    return SExpression.fromArray(elements)
}

// MARK: - CustomStringConvertible
extension SExpression: CustomStringConvertible {
    public var description: String {
        switch self {
        case .symbol(let s): 
            return s
        case .number(let n): 
            // Format numbers nicely
            if n.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(n))
            } else {
                return String(n)
            }
        case .boolean(let b): 
            return b ? "#t" : "#f"
        case .string(let s): 
            return "\"\(s)\""
        case .procedure: 
            return "#<procedure>"
        case .null: 
            return "()"
        case .pair(let carExpr, let cdrExpr):
            // Handle proper lists vs improper lists
            if isList {
                do {
                    let elements = try toArray()
                    let descriptions = elements.map { $0.description }
                    return "(" + descriptions.joined(separator: " ") + ")"
                } catch {
                    // Fallback to dotted notation
                    return "(\(carExpr.description) . \(cdrExpr.description))"
                }
            } else {
                return "(\(carExpr.description) . \(cdrExpr.description))"
            }
        }
    }
}

// MARK: - Equatable
extension SExpression: Equatable {
    public static func == (lhs: SExpression, rhs: SExpression) -> Bool {
        switch (lhs, rhs) {
        case (.symbol(let a), .symbol(let b)):
            return a == b
        case (.number(let a), .number(let b)):
            return a == b
        case (.boolean(let a), .boolean(let b)):
            return a == b
        case (.string(let a), .string(let b)):
            return a == b
        case (.null, .null):
            return true
        case (.pair(let a1, let b1), .pair(let a2, let b2)):
            return a1 == a2 && b1 == b2
        case (.procedure(_), .procedure(_)):
            return false // Procedures are not comparable
        default:
            return false
        }
    }
}

// MARK: - Hashable
extension SExpression: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .symbol(let s):
            hasher.combine("symbol")
            hasher.combine(s)
        case .number(let n):
            hasher.combine("number")
            hasher.combine(n)
        case .boolean(let b):
            hasher.combine("boolean")
            hasher.combine(b)
        case .string(let s):
            hasher.combine("string")
            hasher.combine(s)
        case .null:
            hasher.combine("null")
        case .pair(let car, let cdr):
            hasher.combine("pair")
            hasher.combine(car)
            hasher.combine(cdr)
        case .procedure:
            hasher.combine("procedure")
        }
    }
}