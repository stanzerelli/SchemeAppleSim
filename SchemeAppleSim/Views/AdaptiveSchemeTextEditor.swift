import SwiftUI

/// Platform-adaptive Scheme text editor with stable, performant editing experience
struct AdaptiveSchemeTextEditor: View {
    @Binding var text: String
    let autoIndentEnabled: Bool
    let bracketPairingEnabled: Bool
    
    @FocusState private var isEditorFocused: Bool
    @State private var showingCompletions = false
    @State private var completionSuggestions: [String] = []
    @State private var completionPrefix = ""
    @State private var completionPosition: CGPoint = .zero
    @State private var lastTextLength = 0
    @State private var isUpdatingText = false
    @State private var cursorLineNumber = 1
    @State private var cursorColumnPosition = 0
    
    var body: some View {
        #if os(macOS)
        macOSEditor
        #else
        iOSEditor
        #endif
    }
    
    #if os(macOS)
    private var macOSEditor: some View {
        VStack(spacing: 0) {
            // Main editor area
            HStack(alignment: .top, spacing: 0) {
                // Line numbers
                StableLineNumberView(text: text)
                    .frame(width: 50)
                    .background(PlatformAdaptive.sidebarBackgroundColor)
                
                // Text editor with stable updates
                ZStack(alignment: .topLeading) {
                    StableTextEditor(
                        text: $text,
                        isUpdating: $isUpdatingText,
                        onTextChange: handleTextChangeDebounced,
                        autoIndentEnabled: autoIndentEnabled,
                        bracketPairingEnabled: bracketPairingEnabled
                    )
                    .font(PlatformAdaptive.editorFont)
                    .background(PlatformAdaptive.backgroundColor)
                    
                    // Placeholder
                    if text.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(";; Enter your Scheme code here...")
                                .foregroundColor(.secondary.opacity(0.7))
                            Text(";; Try: (define factorial (lambda (n) ...))")
                                .foregroundColor(.secondary.opacity(0.5))
                                .font(.caption)
                        }
                        .font(PlatformAdaptive.editorFont)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                    }
                    
                    // Dynamic completion popup following cursor
                    if showingCompletions && !completionSuggestions.isEmpty {
                        CompletionPopup(
                            suggestions: completionSuggestions,
                            prefix: completionPrefix,
                            onSelect: insertCompletion
                        )
                        .offset(x: calculateCompletionXOffset(), y: calculateCompletionYOffset())
                        .zIndex(1000)
                    }
                }
            }
            
            // Clean status bar
            StatusBar(
                lineCount: text.split(separator: "\n").count,
                charCount: text.count,
                autoIndentEnabled: autoIndentEnabled,
                bracketPairingEnabled: bracketPairingEnabled
            )
        }
    }
    #endif
    
    #if os(iOS)
    private var iOSEditor: some View {
        VStack(spacing: 0) {
            // Clean symbol toolbar
            CleanSymbolToolbar(onInsertText: insertTextStable)
            
            // Main text editor
            ZStack(alignment: .topLeading) {
                StableTextEditor(
                    text: $text,
                    isUpdating: $isUpdatingText,
                    onTextChange: handleTextChangeDebounced,
                    autoIndentEnabled: autoIndentEnabled,
                    bracketPairingEnabled: bracketPairingEnabled
                )
                .font(PlatformAdaptive.editorFont)
                .focused($isEditorFocused)
                .background(PlatformAdaptive.backgroundColor)
                
                // Line numbers overlay (non-interfering)
                HStack {
                    StableLineNumberView(text: text)
                        .padding(.leading, 4)
                    Spacer()
                }
                .allowsHitTesting(false)
                
                // Completion suggestions (bottom bar style)
                if showingCompletions && !completionSuggestions.isEmpty {
                    VStack {
                        Spacer()
                        CompletionBar(
                            suggestions: completionSuggestions,
                            onSelect: insertCompletion
                        )
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Format") { formatCodeStable() }
                    Button("Complete") { triggerCompletion() }
                    Spacer()
                    Button("Done") { hideKeyboard() }
                }
            }
        }
    }
    #endif
    
    // MARK: - Stable Helper Functions
    
    private func insertTextStable(_ symbol: String) {
        guard !isUpdatingText else { return }
        
        isUpdatingText = true
        defer { 
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isUpdatingText = false
            }
        }
        
        // Enhanced bracket pairing
        if bracketPairingEnabled && ["(", ")", "[", "]", "\""].contains(symbol) {
            let result = SchemeLanguageSupport.processBracketInput(
                symbol,
                cursorPosition: text.count,
                in: text
            )
            
            if result.skipExisting {
                // Just move cursor forward without adding character
                return
            } else {
                text = result.text
            }
        } else {
            text += symbol
        }
        
        isEditorFocused = true
    }
    
    private func handleTextChangeDebounced(_ newValue: String) {
        // Prevent recursive updates
        guard !isUpdatingText else { return }
        
        // Update cursor tracking
        updateCursorPosition(newValue)
        
        // Debounce completion updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            updateCompletionsStable(newValue)
        }
        
        // Handle auto-indent only on newlines
        if newValue.count > lastTextLength && newValue.hasSuffix("\n") {
            handleAutoIndentStable(newValue)
        }
        
        lastTextLength = newValue.count
    }
    
    private func handleAutoIndentStable(_ newText: String) {
        guard autoIndentEnabled && !isUpdatingText else { return }
        
        let lines = newText.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count >= 2 else { return }
        
        let previousLine = String(lines[lines.count - 2])
        let currentLine = String(lines.last ?? "")
        
        // Only indent if current line is empty
        guard currentLine.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let indent = calculateSmartIndent(previousLine: previousLine)
        
        if indent > 0 {
            isUpdatingText = true
            text = newText + String(repeating: " ", count: indent)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isUpdatingText = false
            }
        }
    }
    
    private func calculateSmartIndent(previousLine: String) -> Int {
        let trimmed = previousLine.trimmingCharacters(in: .whitespaces)
        
        // Get existing indentation
        let existingIndent = previousLine.prefix { $0.isWhitespace }.count
        
        // Special Scheme forms get extra indentation
        let specialForms = ["define", "lambda", "let", "let*", "letrec", "cond", "case", "if", "when", "unless"]
        for form in specialForms {
            if trimmed.hasPrefix("(\(form)") {
                return existingIndent + 2
            }
        }
        
        // Count unclosed parentheses
        var openCount = 0
        var inString = false
        
        for char in trimmed {
            switch char {
            case "\"": inString.toggle()
            case "(" where !inString: openCount += 1
            case ")" where !inString: openCount -= 1
            default: break
            }
        }
        
        return existingIndent + (openCount > 0 ? 2 : 0)
    }
    
    private func updateCompletionsStable(_ newValue: String) {
        // Extract word at cursor position
        let lines = newValue.split(separator: "\n", omittingEmptySubsequences: false)
        let currentLine = String(lines.last ?? "")
        
        // Find current word
        let words = currentLine.split(whereSeparator: { !$0.isLetter && $0 != "-" && $0 != "?" && $0 != "!" })
        
        if let lastWord = words.last?.lowercased(), lastWord.count >= 2 {
            let suggestions = SchemeLanguageSupport.completionSuggestions(for: String(lastWord))
            
            DispatchQueue.main.async {
                self.completionPrefix = String(lastWord)
                self.completionSuggestions = Array(suggestions.prefix(6))
                self.showingCompletions = !suggestions.isEmpty
            }
        } else {
            DispatchQueue.main.async {
                self.showingCompletions = false
                self.completionSuggestions = []
                self.completionPrefix = ""
            }
        }
    }
    
    private func insertCompletion(_ completion: String) {
        guard !isUpdatingText else { return }
        
        isUpdatingText = true
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isUpdatingText = false
                showingCompletions = false
                completionSuggestions = []
            }
        }
        
        // Replace the prefix with completion
        if !completionPrefix.isEmpty {
            if let range = text.range(of: completionPrefix, options: .backwards) {
                text.replaceSubrange(range, with: completion)
            }
        } else {
            text += completion
        }
    }
    
    private func formatCodeStable() {
        guard !isUpdatingText else { return }
        
        isUpdatingText = true
        text = SchemeLanguageSupport.formatSchemeCode(text)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isUpdatingText = false
        }
    }
    
    private func triggerCompletion() {
        updateCompletionsStable(text)
    }
    
    // MARK: - Cursor Position Tracking
    
    private func updateCursorPosition(_ newText: String) {
        let lines = newText.split(separator: "\n", omittingEmptySubsequences: false)
        cursorLineNumber = lines.count
        
        if let currentLine = lines.last {
            cursorColumnPosition = currentLine.count
        } else {
            cursorColumnPosition = 0
        }
    }
    
    private func calculateCompletionXOffset() -> CGFloat {
        // Base position from line number area (50pt) plus estimated character width
        let lineNumberWidth: CGFloat = 50
        let characterWidth: CGFloat = 8 // Approximate monospace character width
        return lineNumberWidth + (CGFloat(cursorColumnPosition) * characterWidth) - 100 // Center popup around cursor
    }
    
    private func calculateCompletionYOffset() -> CGFloat {
        // Position below current line with line height estimation
        let lineHeight: CGFloat = 17 // Approximate line height
        let headerOffset: CGFloat = 8 // Account for padding
        return headerOffset + (CGFloat(cursorLineNumber - 1) * lineHeight) + lineHeight
    }
    
    #if os(iOS)
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif
}

// MARK: - Stable Supporting Views

struct StableTextEditor: View {
    @Binding var text: String
    @Binding var isUpdating: Bool
    let onTextChange: (String) -> Void
    let autoIndentEnabled: Bool
    let bracketPairingEnabled: Bool
    
    var body: some View {
        TextEditor(text: $text)
            .onChange(of: text) { _, newValue in
                guard !isUpdating else { return }
                onTextChange(newValue)
            }
            .scrollContentBackground(.hidden)
    }
}

struct StableLineNumberView: View {
    let text: String
    
    private var lineCount: Int {
        max(1, text.split(separator: "\n", omittingEmptySubsequences: false).count)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...lineCount, id: \.self) { lineNumber in
                    Text("\(lineNumber)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(minHeight: 17, alignment: .top)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .background(PlatformAdaptive.sidebarBackgroundColor.opacity(0.3))
    }
}

struct CompletionPopup: View {
    let suggestions: [String]
    let prefix: String
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: {
                    onSelect(suggestion)
                }) {
                    HStack {
                        Image(systemName: "function")
                            .foregroundColor(.blue)
                            .frame(width: 16)
                        
                        Text(suggestion)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                )
                .onHover { isHovered in
                    // Add subtle hover effect
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(PlatformAdaptive.backgroundColor)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .frame(width: 200)
    }
}

struct CompletionBar: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) {
                        onSelect(suggestion)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.2))
                    )
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 36)
        .background(PlatformAdaptive.sidebarBackgroundColor)
    }
}

struct StatusBar: View {
    let lineCount: Int
    let charCount: Int
    let autoIndentEnabled: Bool
    let bracketPairingEnabled: Bool
    
    var body: some View {
        HStack {
            Label("Scheme", systemImage: "text.alignleft")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if autoIndentEnabled {
                Label("Auto-indent", systemImage: "increase.indent")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            if bracketPairingEnabled {
                Label("Smart brackets", systemImage: "parentheses")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("Lines: \(lineCount)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Chars: \(charCount)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(PlatformAdaptive.sidebarBackgroundColor)
    }
}

#if os(iOS)
struct CleanSymbolToolbar: View {
    let onInsertText: (String) -> Void
    
    private let symbols = [
        ("(", "Open paren"),
        (")", "Close paren"),
        ("'", "Quote"),
        ("`", "Quasiquote"),
        (",", "Unquote"),
        ("λ", "Lambda")
    ]
    
    private let keywords = ["define", "lambda", "let", "if", "cond"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Symbols section
                ForEach(symbols, id: \.0) { symbol, description in
                    Button(action: {
                        onInsertText(symbol)
                    }) {
                        VStack(spacing: 2) {
                            Text(symbol)
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text(description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 50, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                
                Divider()
                    .frame(height: 30)
                
                // Keywords section
                ForEach(keywords, id: \.self) { keyword in
                    Button(keyword) {
                        onInsertText(keyword)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 50)
        .background(PlatformAdaptive.toolbarBackgroundColor)
    }
}
#endif

#Preview {
    AdaptiveSchemeTextEditor(
        text: .constant("(define factorial\n  (lambda (n)\n    (if (<= n 1)\n        1\n        (* n (factorial (- n 1))))))"),
        autoIndentEnabled: true,
        bracketPairingEnabled: true
    )
    .frame(height: 400)
}