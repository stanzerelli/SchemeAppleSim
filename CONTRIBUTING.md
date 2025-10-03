# Contributing to SchemeAppleSim

First off, thank you for considering contributing to SchemeAppleSim!  
This project aims to provide a robust, R5RS-compliant Scheme interpreter and IDE native to macOS.

Whether you're fixing a bug, adding a new R5RS primitive, or improving the SwiftUI interface, your help is appreciated.

---

## Development Setup

### 1. Prerequisites

- macOS 15.7+
- Xcode 17.0+
- Swift 5.9+

### 2. Clone the Repository

```bash
git clone https://github.com/stanzerelli/SchemeInterpretator4Apple.git
cd SchemeInterpretator4Apple
```

### 3. Open the Project

Open `SchemeAppleSim.xcodeproj` in Xcode.  
The project uses standard Swift Package Manager dependencies (if any), which resolve automatically.

---

## How to Contribute

### 1. Identify an Issue

Check the issue tracker for open bugs or feature requests.  
If you plan to work on a significant new feature or architectural change, please open an issue first to discuss it before writing code.

### 2. Branching

Create a new branch for your work directly from `main`:

```bash
git checkout -b feature/your-feature-name
```

We keep it simple: no complex GitFlow, just feature branches off `main`.

### 3. Making Changes

When modifying the codebase, please adhere to the following guidelines:

- **Swift Style**  
  Follow standard Apple Swift conventions. Keep your code clean, type-safe, and leverage Swift’s modern features.

- **Architecture**  
  Respect the MVVM pattern for UI changes and keep the core interpreter logic (`Parser`, `Evaluator`, `Environment`) strictly separated from SwiftUI views.

- **Documentation**  
  Use standard `///` SwiftDoc comments for new public structs, classes, and complex interpreter functions.

### 4. Testing

SchemeAppleSim relies heavily on accurate evaluation.

If you add a new Scheme primitive or fix an evaluation bug, you must include an `XCTest` verifying correct R5RS behavior.

Run the test suite before submitting:

```bash
xcodebuild test -project SchemeAppleSim.xcodeproj -scheme SchemeAppleSim
```

### 5. Pull Requests

Once your changes are ready and all tests pass:

1. Push your branch to your fork.
2. Open a Pull Request against the `main` branch.
3. In the PR description, clearly explain what you changed and why.
4. If it fixes an open issue, reference the issue number (e.g., `Fixes #12`).

---

## Architectural Guidelines for the Interpreter

If you are contributing to the core Scheme engine, please note:

- **AST (Abstract Syntax Tree)**  
  All parsed code relies on the `SExpression` enum.

- **Immutability**  
  Keep evaluation functions as pure as possible, isolating state mutations to the `Environment` class.

- **Tail Call Optimization (TCO)**  
  If modifying the `Evaluator`, ensure that proper tail calls do not inadvertently increase the call stack.

---

## License

By contributing to SchemeAppleSim, you agree that your contributions will be licensed under its MIT License.