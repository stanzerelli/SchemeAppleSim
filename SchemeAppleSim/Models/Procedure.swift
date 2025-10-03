import Foundation

/// Represents a Scheme procedure (function)
public indirect enum Procedure {
    case primitive(PrimitiveFunction)
    case compound([String], [SExpression], Environment, Bool) // params, body, closure, isVariadic
}

/// Type alias for primitive function implementations
public typealias PrimitiveFunction = ([SExpression]) throws -> SExpression