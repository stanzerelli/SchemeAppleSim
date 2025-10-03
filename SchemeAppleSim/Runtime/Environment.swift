import Foundation

/// Represents a Scheme environment for variable bindings
public class Environment {
    private var bindings: [String: SExpression] = [:]
    private let parent: Environment?
    
    /// Initialize a new environment with optional parent
    public init(parent: Environment? = nil) {
        self.parent = parent
    }
    
    /// Define a new binding in this environment
    public func define(symbol: String, value: SExpression) {
        bindings[symbol] = value
    }
    
    /// Set an existing binding (searches up the environment chain)
    public func set(symbol: String, value: SExpression) throws {
        if bindings.keys.contains(symbol) {
            bindings[symbol] = value
            return
        }
        
        if let parent = parent {
            try parent.set(symbol: symbol, value: value)
            return
        }
        
        throw SchemeError.unboundSymbol(symbol)
    }
    
    /// Find a binding in this environment or its parents
    public func lookup(symbol: String) -> SExpression? {
        if let value = bindings[symbol] {
            return value
        }
        return parent?.lookup(symbol: symbol)
    }
    
    /// Check if a symbol is bound in this environment or its parents
    public func contains(symbol: String) -> Bool {
        return lookup(symbol: symbol) != nil
    }
    
    /// Get all defined symbols in this environment (not including parents)
    public var localSymbols: Set<String> {
        return Set(bindings.keys)
    }
    
    /// Get all defined symbols in this environment and its parents
    public var allSymbols: Set<String> {
        var symbols = localSymbols
        if let parent = parent {
            symbols.formUnion(parent.allSymbols)
        }
        return symbols
    }
    
    /// Get all defined symbols in this environment and its parents (method version)
    public func getAllSymbols() -> Set<String> {
        return allSymbols
    }
    
    /// Create a new child environment
    public func createChild() -> Environment {
        return Environment(parent: self)
    }
    
    /// Clear all local bindings
    public func clear() {
        bindings.removeAll()
    }
}

// MARK: - Environment Factory
public extension Environment {
    /// Create the global environment with built-in procedures
    static func createGlobal() -> Environment {
        let env = Environment()
        StandardLibrary.populateEnvironment(env)
        return env
    }
}

// MARK: - CustomStringConvertible
extension Environment: CustomStringConvertible {
    public var description: String {
        let localBindings = bindings.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        if let parent = parent {
            return "Environment(local: [\(localBindings)], parent: \(parent))"
        } else {
            return "Environment(local: [\(localBindings)])"
        }
    }
}