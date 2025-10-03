# 🖥️ SchemeAppleSim

[![Swift Version](https://img.shields.io/badge/Swift-5.9+-brightgreen.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2015.7+-blue.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v0.1.0-red.svg)](https://github.com/stanzerelli/SchemeInterpretator4Apple/releases)

A modern, native **Scheme interpreter and IDE** for macOS, built with SwiftUI. SchemeAppleSim provides a clean, VS Code-inspired interface for writing, editing, and executing Scheme code with full R5RS compliance.

## ✨ Features

### 🎯 Core Functionality
- **Complete R5RS Scheme Interpreter** - Full implementation of the Scheme standard
- **Native SwiftUI Interface** - Clean, modern macOS-native design
- **Real-time REPL** - Interactive Scheme evaluation with immediate feedback
- **Syntax Highlighting** - Visual code clarity for better development experience

### 📝 Advanced Editor Features
- **Auto-indentation** - Smart indentation based on Scheme syntax
- **Bracket Pairing** - Automatic bracket completion and matching
- **Code Formatting** - Pretty-print your Scheme code with proper indentation
- **File Management** - Create, rename, delete, and organize Scheme files
- **Auto-save** - Automatic file saving with configurable intervals

### 🔧 Developer Experience
- **Sidebar File Explorer** - VS Code-style file navigation
- **Split View Layout** - Code editor with integrated REPL output
- **Customizable Interface** - Toggle editor features and layout options
- **Error Highlighting** - Clear error messages and debugging information

### ☁️ iCloud Integration (Planned)
- **Document Sync** - Seamless file synchronization across devices
- **Backup & Restore** - Automatic backup of your Scheme projects

## 🚀 Getting Started

### Prerequisites
- macOS 15.7 or later
- Xcode 17.0 or later
- Swift 5.9 or later

### Installation

#### Option 1: Build from Source
```bash
git clone https://github.com/stanzerelli/SchemeInterpretator4Apple.git
cd SchemeInterpretator4Apple
open SchemeAppleSim.xcodeproj
```

#### Option 2: Download Release
Download the latest release from the [Releases page](https://github.com/stanzerelli/SchemeInterpretator4Apple/releases).

### First Run
1. Launch SchemeAppleSim
2. Create a new file or edit the example file
3. Write your Scheme code in the editor
4. Click "Run" to execute your code
5. View results in the REPL output panel

## 📖 Usage Examples

### Basic Scheme Operations
```scheme
;; Arithmetic operations
(+ 1 2 3)          ; => 6
(* 4 5)            ; => 20
(/ 10 2)           ; => 5

;; List operations
(list 1 2 3 4)     ; => (1 2 3 4)
(car '(a b c))     ; => a
(cdr '(a b c))     ; => (b c)

;; Function definition
(define factorial
  (lambda (n)
    (if (<= n 1)
        1
        (* n (factorial (- n 1))))))

(factorial 5)      ; => 120
```

### Advanced Features
```scheme
;; Higher-order functions
(define map
  (lambda (f lst)
    (if (null? lst)
        '()
        (cons (f (car lst))
              (map f (cdr lst))))))

(map (lambda (x) (* x x)) '(1 2 3 4))  ; => (1 4 9 16)

;; Closures and lexical scoping
(define make-counter
  (lambda (initial)
    (let ((count initial))
      (lambda ()
        (set! count (+ count 1))
        count))))

(define counter (make-counter 0))
(counter)          ; => 1
(counter)          ; => 2
```

## 🏗️ Architecture

### Project Structure
```
SchemeAppleSim/
├── Models/
│   ├── SExpression.swift      # Core Scheme data types
│   ├── Procedure.swift        # Function representations
│   └── SchemeError.swift      # Error handling
├── Parser/
│   ├── Parser.swift           # Scheme syntax parser
│   └── Tokenizer.swift        # Lexical analysis
├── Runtime/
│   ├── Environment.swift      # Variable bindings
│   ├── StandardLibrary.swift  # Built-in functions
│   └── *Primitives.swift      # Primitive operations
├── Evaluator/
│   └── Evaluator.swift        # Core interpreter logic
├── ViewModels/
│   └── SchemeInterpreterViewModel.swift
└── Views/
    ├── ContentView.swift      # Main interface
    └── AdvancedTextEditor.swift
```

### Key Components
- **Parser**: Converts Scheme source code into internal AST representation
- **Evaluator**: Executes parsed Scheme expressions with proper semantics
- **Environment**: Manages variable and function bindings with lexical scoping
- **Standard Library**: Implements R5RS built-in procedures and special forms

## 🛠️ Development

### Building
```bash
xcodebuild -project SchemeAppleSim.xcodeproj -scheme SchemeAppleSim build
```

### Running Tests
```bash
xcodebuild test -project SchemeAppleSim.xcodeproj -scheme SchemeAppleSim
```

### Code Style
- Swift 5.9+ features preferred
- SwiftUI for all UI components
- MVVM architecture pattern
- Comprehensive documentation for public APIs

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Start for Contributors
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📋 Roadmap

### v0.2.0 (Next Release)
- [ ] iCloud document synchronization
- [ ] Syntax highlighting with themes
- [ ] Code completion and IntelliSense
- [ ] Debugging capabilities
- [ ] Package/module system

### v0.3.0 (Future)
- [ ] iOS and iPadOS versions
- [ ] Plugin system for extensions
- [ ] Performance profiling tools
- [ ] Git integration
- [ ] Collaborative editing

## 🐛 Known Issues

- Auto-indentation may need fine-tuning for complex nested expressions
- Bracket pairing doesn't yet support cursor positioning
- iCloud sync is planned but not yet implemented

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Tibo Stans** - [@stanzerelli](https://github.com/stanzerelli)

## 🙏 Acknowledgments

- Built with ❤️ using SwiftUI and modern macOS development practices
- Inspired by classic Scheme implementations and modern code editors
- Special thanks to the Scheme community for the R5RS specification

## 📞 Support

- 🐛 [Report Issues](https://github.com/stanzerelli/SchemeInterpretator4Apple/issues)
- 💬 [Discussions](https://github.com/stanzerelli/SchemeInterpretator4Apple/discussions)
- 📧 [Contact](mailto:your-email@example.com)

---

**Made with 🚀 for the Scheme and macOS communities**