import Foundation

/// Represents an entry in the output history
public struct OutputEntry {
    public let input: String
    public let output: String
    public let isError: Bool
    public let timestamp: Date
    
    public init(input: String, output: String, isError: Bool = false) {
        self.input = input
        self.output = output
        self.isError = isError
        self.timestamp = Date()
    }
}

/// Represents an environment binding for display
public struct EnvironmentBinding {
    public let name: String
    public let value: String
    public let type: String
    
    public init(name: String, value: String, type: String) {
        self.name = name
        self.value = value
        self.type = type
    }
}

/// Example Scheme programs
public enum SchemeExamples: String, CaseIterable {
    case factorial = "Factorial"
    case fibonacci = "Fibonacci"
    case quicksort = "Quicksort"
    case mapExample = "Map Example"
    case closures = "Closures"
    
    public var title: String {
        return rawValue
    }
    
    public var code: String {
        switch self {
        case .factorial:
            return """
            ;; Factorial function
            (define (factorial n)
              (if (= n 0)
                  1
                  (* n (factorial (- n 1)))))
            
            (factorial 5)
            """
        case .fibonacci:
            return """
            ;; Fibonacci sequence
            (define (fibonacci n)
              (if (<= n 1)
                  n
                  (+ (fibonacci (- n 1))
                     (fibonacci (- n 2)))))
            
            (fibonacci 10)
            """
        case .quicksort:
            return """
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
            
            (define (filter predicate lst)
              (if (null? lst)
                  '()
                  (if (predicate (car lst))
                      (cons (car lst) (filter predicate (cdr lst)))
                      (filter predicate (cdr lst)))))
            
            (quicksort '(3 1 4 1 5 9 2 6 5 3 5))
            """
        case .mapExample:
            return """
            ;; Higher-order functions with map
            (define (square x) (* x x))
            (define (double x) (* x 2))
            
            (map square '(1 2 3 4 5))
            (map double '(1 2 3 4 5))
            (map (lambda (x) (+ x 10)) '(1 2 3 4 5))
            """
        case .closures:
            return """
            ;; Closures and lexical scoping
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
            """
        }
    }
}