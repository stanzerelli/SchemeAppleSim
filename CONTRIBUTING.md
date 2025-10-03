# Contributing to SchemeAppleSim 🤝

Thank you for your interest in contributing to SchemeAppleSim! This guide will help you get started with contributing to our Scheme interpreter and IDE for macOS.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Issue Reporting](#issue-reporting)
- [Development Workflow](#development-workflow)

## 🤝 Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow:

- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome developers of all skill levels and backgrounds
- **Be constructive**: Provide helpful feedback and suggestions
- **Be patient**: Remember that everyone is learning and improving

## 🚀 Getting Started

### Prerequisites

- **macOS**: 15.7 or later
- **Xcode**: 17.0 or later
- **Swift**: 5.9 or later
- **Git**: Latest version recommended

### Development Setup

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/SchemeInterpretator4Apple.git
   cd SchemeInterpretator4Apple
   ```

2. **Set up upstream remote**
   ```bash
   git remote add upstream https://github.com/stanzerelli/SchemeInterpretator4Apple.git
   ```

3. **Open in Xcode**
   ```bash
   open SchemeAppleSim.xcodeproj
   ```

4. **Build and test**
   ```bash
   xcodebuild -project SchemeAppleSim.xcodeproj -scheme SchemeAppleSim build
   xcodebuild test -project SchemeAppleSim.xcodeproj -scheme SchemeAppleSim
   ```

## 💡 How to Contribute

### Types of Contributions

We welcome various types of contributions:

- 🐛 **Bug fixes**: Fix issues and improve stability
- ✨ **New features**: Add new functionality to the interpreter or UI
- 📚 **Documentation**: Improve docs, add examples, write tutorials
- 🎨 **UI/UX improvements**: Enhance the user interface and experience
- ⚡ **Performance**: Optimize code for better performance
- 🧪 **Tests**: Add or improve test coverage
- 🔧 **Tooling**: Improve development tools and processes

### Good First Issues

Look for issues labeled with:
- `good first issue`: Perfect for newcomers
- `help wanted`: Issues where we'd appreciate help
- `documentation`: Documentation improvements needed

## 🔄 Pull Request Process

### 1. Create a Feature Branch

```bash
# Update your main branch
git checkout main
git pull upstream main

# Create a new feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b bugfix/issue-description
```

### 2. Make Your Changes

- Write clean, well-commented code
- Follow our code style guidelines
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Build the project
xcodebuild -project SchemeAppleSim.xcodeproj -scheme SchemeAppleSim build

# Run tests
xcodebuild test -project SchemeAppleSim.xcodeproj -scheme SchemeAppleSim

# Test manually in Xcode
# - Run the app
# - Test your specific changes
# - Verify no regressions
```

### 4. Commit Your Changes

```bash
# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "Add: implement auto-indentation for Scheme code

- Add smart indentation based on bracket nesting
- Handle special forms with custom indentation rules
- Update text editor to support auto-indent toggle
- Add unit tests for indentation logic

Closes #123"
```

### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create pull request on GitHub
# Use the PR template and provide detailed description
```

## 📝 Code Style Guidelines

### Swift Style

We follow Apple's Swift conventions with some additional guidelines:

```swift
// ✅ Good
struct SchemeInterpreter {
    private let environment: Environment
    private var outputHistory: [REPLEntry] = []
    
    func evaluate(_ expression: SExpression) throws -> SExpression {
        // Implementation
    }
}

// ❌ Avoid
struct schemeInterpreter {
    var env: Environment
    var output: [REPLEntry] = []
    
    func eval(_ expr: SExpression) throws -> SExpression {
        // Implementation
    }
}
```

### Naming Conventions

- **Types**: PascalCase (`SExpression`, `SchemeError`)
- **Functions/Variables**: camelCase (`evaluateExpression`, `currentEnvironment`)
- **Constants**: camelCase (`maxRecursionDepth`)
- **Enums**: PascalCase with lowercase cases (`case atom`, `case list`)

### Documentation

All public APIs should have documentation comments:

```swift
/// Evaluates a Scheme expression in the given environment.
/// 
/// - Parameters:
///   - expression: The S-expression to evaluate
///   - environment: The environment containing variable bindings
/// - Returns: The result of evaluation
/// - Throws: `SchemeError` if evaluation fails
func evaluate(_ expression: SExpression, in environment: Environment) throws -> SExpression {
    // Implementation
}
```

### File Organization

```swift
// MARK: - Imports
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Type
struct ContentView: View {
    // MARK: - Properties
    @StateObject private var interpreter = SchemeInterpreterViewModel()
    
    // MARK: - Body
    var body: some View {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func handleAction() {
        // Implementation
    }
}

// MARK: - Supporting Types
struct HelperView: View {
    // Implementation
}

// MARK: - Extensions
extension ContentView {
    // Additional functionality
}
```

## 🧪 Testing Guidelines

### Test Structure

```swift
import XCTest
@testable import SchemeAppleSim

final class SchemeInterpreterTests: XCTestCase {
    private var interpreter: SchemeInterpreter!
    
    override func setUp() {
        super.setUp()
        interpreter = SchemeInterpreter()
    }
    
    override func tearDown() {
        interpreter = nil
        super.tearDown()
    }
    
    func testBasicArithmetic() {
        // Given
        let expression = try! Parser.parse("(+ 1 2 3)")
        
        // When
        let result = try! interpreter.evaluate(expression)
        
        // Then
        XCTAssertEqual(result, .atom(.number(6)))
    }
}
```

### Test Coverage

- **Unit tests**: Test individual functions and methods
- **Integration tests**: Test component interactions
- **UI tests**: Test user interface functionality
- **Performance tests**: Test performance-critical code

### Test Naming

```swift
func testFeature_Condition_ExpectedBehavior() {
    // Example: testEvaluate_ValidExpression_ReturnsCorrectResult
}
```

## 📚 Documentation Standards

### Code Comments

```swift
// Single-line comments for brief explanations
let result = try evaluate(expression) // Evaluate the parsed expression

/* Multi-line comments for complex explanations
   This function implements the core evaluation logic
   following the R5RS specification for Scheme semantics.
*/
```

### README Updates

When adding new features, update the README:
- Add to feature list
- Include usage examples
- Update screenshots if UI changes

## 🐛 Issue Reporting

### Bug Reports

Use this template for bug reports:

```markdown
**Bug Description**
A clear description of the bug.

**Steps to Reproduce**
1. Step one
2. Step two
3. Step three

**Expected Behavior**
What should happen.

**Actual Behavior**
What actually happens.

**Environment**
- macOS version:
- Xcode version:
- App version:

**Screenshots**
If applicable, add screenshots.

**Additional Context**
Any other relevant information.
```

### Feature Requests

```markdown
**Feature Description**
A clear description of the feature.

**Use Case**
Why this feature would be useful.

**Proposed Solution**
Your idea for implementing this feature.

**Alternatives Considered**
Other approaches you've considered.
```

## 🔄 Development Workflow

### Branch Strategy

- `main`: Stable, production-ready code
- `develop`: Integration branch for next release
- `feature/*`: New features
- `bugfix/*`: Bug fixes
- `hotfix/*`: Critical fixes for production

### Release Process

1. **Development**: Work in `feature/*` branches
2. **Integration**: Merge to `develop` for testing
3. **Release Preparation**: Create `release/*` branch
4. **Testing**: Comprehensive testing of release branch
5. **Release**: Merge to `main` and tag version
6. **Hotfixes**: Use `hotfix/*` branches for critical issues

### Commit Message Format

```
Type: Short description

Optional longer description explaining the change in more detail.
Include motivation for the change and contrast with previous behavior.

- List specific changes
- Include any breaking changes
- Reference related issues

Closes #123
```

**Types:**
- `Add`: New features
- `Fix`: Bug fixes
- `Update`: Modifications to existing features
- `Remove`: Deleted features
- `Docs`: Documentation changes
- `Style`: Code style changes
- `Refactor`: Code refactoring
- `Test`: Test additions or modifications
- `Chore`: Maintenance tasks

## 🏆 Recognition

Contributors will be recognized in:
- GitHub contributors list
- Release notes for significant contributions
- README acknowledgments for major features

## 📞 Getting Help

- **GitHub Discussions**: For questions and general discussion
- **GitHub Issues**: For bug reports and feature requests
- **Code Review**: We provide constructive feedback on pull requests

Thank you for contributing to SchemeAppleSim! 🚀