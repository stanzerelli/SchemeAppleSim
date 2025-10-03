# SchemeAppleSim

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-brightgreen.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2015.7+-blue.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

SchemeAppleSim is a native Scheme interpreter and integrated development environment (IDE) for macOS, built with SwiftUI. It provides an R5RS-compliant environment for writing, editing, and executing Scheme code within a modern, native interface.

## Core Features

* **R5RS Scheme Interpreter:** A robust implementation of the Scheme standard, including support for lexical scoping, proper tail recursion (TCO), and higher-order functions.
* **Native macOS IDE:** Built entirely with SwiftUI, offering a split-view layout with a code editor and an integrated REPL.
* **Advanced Editor Capabilities:** Features syntax highlighting, intelligent auto-indentation, automatic bracket pairing, and code formatting.
* **Interactive REPL:** Real-time evaluation environment for testing and debugging Scheme expressions.

## Architecture

The project follows an MVVM architecture and is divided into several core components:

* **Parser & Tokenizer:** Lexical analysis and conversion of Scheme source code into an Abstract Syntax Tree (AST).
* **Evaluator:** Executes parsed expressions (`SExpression`) handling special forms and procedure applications.
* **Environment:** Manages variable bindings and lexical scoping.
* **Standard Library:** Implements built-in R5RS procedures and primitives.

## Building and Installation

### Prerequisites
* macOS 15.7 or later
* Xcode 17.0 or later
* Swift 5.9 or later

### Build Instructions

1. Clone the repository:

```bash
git clone https://github.com/stanzerelli/SchemeInterpretator4Apple.git
cd SchemeInterpretator4Apple
```

2. Open `SchemeAppleSim.xcodeproj` in Xcode.
3. Build and run the **SchemeAppleSim** scheme.

Alternatively, via command line:

```bash
xcodebuild -project SchemeAppleSim.xcodeproj -scheme SchemeAppleSim build
```

## Usage Example

```scheme
;; Define a recursive factorial function
(define factorial
  (lambda (n)
    (if (<= n 1)
        1
        (* n (factorial (- n 1))))))

;; Execute
(factorial 5) ; => 120
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.