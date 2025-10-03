import SwiftUI

/// Platform-adaptive Scheme text editor with enhanced language support and smart features
struct AdaptiveSchemeTextEditor: View {
    @Binding var text: String
    let autoIndentEnabled: Bool
    let bracketPairingEnabled: Bool
    
    @FocusState private var isEditorFocused: Bool
    @State private var textEditorHeight: CGFloat = 200
    @State private var showingCompletions = false
    @State private var completionSuggestions: [String] = []
    @State private var currentWordPrefix = ""
    
    var body: some View {
        #if os(macOS)
        macOSEditor
        #else
        iOSEditor
        #endif
    }
    
    #if os(macOS)
    private var macOSEditor: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // Enhanced text editor with line numbers
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    LineNumberView(text: text)
                        .frame(width: 50)
                        .background(PlatformAdaptive.sidebarBackgroundColor)
                    
                    // Main text editor
                    TextEditor(text: $text)
                        .font(PlatformAdaptive.editorFont)
                        .background(Color.primary.opacity(0.05))
                        .onChange(of: text) { _, newValue in
                            handleTextChange(newValue)
                        }
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text(";; Enter your Scheme code here...\n;; Features: Auto-format, syntax highlighting, code completion")
                                    .foregroundColor(.secondary)
                                    .font(PlatformAdaptive.editorFont)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                
                // Status bar with enhanced information
                HStack {
                    Text("Scheme")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if autoIndentEnabled {
                        Text("• Auto-indent")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    if bracketPairingEnabled {
                        Text("• Smart brackets")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("Lines: \(text.split(separator: "\n").count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Chars: \(text.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PlatformAdaptive.sidebarBackgroundColor)
            }
            
            // Completion popup
            if showingCompletions && !completionSuggestions.isEmpty {
                completionPopup
                    .offset(x: 60, y: 30)
            }
        }
    }
    #endif
    
    #if os(iOS)
    private var iOSEditor: some View {
        VStack(spacing: 0) {
            // Enhanced iOS toolbar with more Scheme symbols
            SchemeSymbolToolbar(onInsertText: insertText)
            
            // Main text editor with overlay features
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(PlatformAdaptive.editorFont)
                    .focused($isEditorFocused)
                    .background(Color(UIColor.systemBackground))
                    .onChange(of: text) { _, newValue in
                        handleTextChange(newValue)
                    }
                
                // Line numbers overlay
                HStack {
                    LineNumberView(text: text)
                        .padding(.leading, 8)
                    Spacer()
                }
                .allowsHitTesting(false)
                
                // Completion suggestions
                if showingCompletions && !completionSuggestions.isEmpty {
                    VStack {
                        Spacer()
                        completionBar
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Format") {
                        formatCode()
                    }
                    
                    Button("Validate") {
                        validateScheme()
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
        }
    }
    #endif
    
    // MARK: - Completion Views
    
    private var completionPopup: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Completions")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.top, 4)
            
            ForEach(completionSuggestions.prefix(6), id: \.self) { suggestion in
                Button(action: {
                    insertCompletion(suggestion)
                }) {
                    HStack {
                        Image(systemName: "function")
                            .foregroundColor(.blue)
                            .frame(width: 16)
                        
                        Text(suggestion)
                            .font(.system(.body, design: .monospaced))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.clear)
                .contentShape(Rectangle())
            }
        }
        .background(PlatformAdaptive.backgroundColor)
        .cornerRadius(8)
        .shadow(radius: 4)
        .frame(maxWidth: 200)
    }
    
    #if os(iOS)
    private var completionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(completionSuggestions.prefix(5), id: \.self) { suggestion in
                    Button(suggestion) {
                        insertCompletion(suggestion)
                    }
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 32)
        .background(Color(UIColor.secondarySystemBackground))
    }
    #endif
    
    // MARK: - Helper Functions
    
    private func insertText(_ symbol: String) {
        text += symbol
        isEditorFocused = true
        
        if bracketPairingEnabled && symbol == "(" {
            text += ")"
            // TODO: Move cursor back one position
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        if autoIndentEnabled {
            handleAutoIndent(newValue)
        }
        
        updateCompletions(newValue)
    }
    
    private func handleAutoIndent(_ newText: String) {
        if newText.hasSuffix("\n") {
            let lines = newText.components(separatedBy: "\n")
            if lines.count > 1 {
                let previousLine = lines[lines.count - 2]
                let currentLine = lines.last ?? ""
                
                let indent = SchemeLanguageSupport.calculateIndentation(
                    for: currentLine,
                    previousLine: previousLine
                )
                
                if indent > 0 {
                    text = newText + String(repeating: " ", count: indent)
                }
            }
        }
    }
    
    private func updateCompletions(_ newValue: String) {
        // Extract current word being typed
        let lines = newValue.components(separatedBy: "\n")
        let currentLine = lines.last ?? ""
        let words = currentLine.components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        if let lastWord = words.last, lastWord.count > 1 {
            let suggestions = SchemeLanguageSupport.completionSuggestions(for: lastWord)
            
            DispatchQueue.main.async {
                self.currentWordPrefix = lastWord
                self.completionSuggestions = suggestions
                self.showingCompletions = !suggestions.isEmpty
            }
        } else {
            DispatchQueue.main.async {
                self.showingCompletions = false
                self.completionSuggestions = []
                self.currentWordPrefix = ""
            }
        }
    }
    
    private func insertCompletion(_ completion: String) {
        // Replace the current word prefix with the completion
        if !currentWordPrefix.isEmpty {
            let range = text.range(of: currentWordPrefix, options: .backwards)
            if let range = range {
                text.replaceSubrange(range, with: completion)
            }
        } else {
            text += completion
        }
        
        showingCompletions = false
        completionSuggestions = []
        currentWordPrefix = ""
    }
    
    private func formatCode() {
        text = SchemeLanguageSupport.formatSchemeCode(text)
    }
    
    private func validateScheme() {
        // TODO: Implement Scheme syntax validation
        // This could check for balanced parentheses, valid syntax, etc.
    }
    
    private func getIndentLevel(for line: String) -> Int {
        var openBrackets = 0
        
        for char in line {
            switch char {
            case "(", "[", "{":
                openBrackets += 1
            case ")", "]", "}":
                openBrackets -= 1
            default:
                break
            }
        }
        
        return max(0, openBrackets)
    }
    
    #if os(iOS)
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif
}

#if os(iOS)
struct SchemeSymbolToolbar: View {
    let onInsertText: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Structural symbols
                ForEach(["(", ")", "'", "`", ",", "@"], id: \.self) { symbol in
                    symbolButton(symbol, color: .blue)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Special symbols
                ForEach(SchemeLanguageSupport.commonSymbols.prefix(6), id: \.0) { symbol, _ in
                    symbolButton(symbol.0, color: .purple)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Keywords
                ForEach(["define", "lambda", "let", "if", "cond", "case"], id: \.self) { keyword in
                    keywordButton(keyword)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private func symbolButton(_ symbol: String, color: Color) -> some View {
        Button(symbol) {
            onInsertText(symbol)
        }
        .font(.system(.title3, design: .monospaced))
        .foregroundColor(color)
        .frame(width: 36, height: 36)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func keywordButton(_ keyword: String) -> some View {
        Button(keyword) {
            onInsertText(keyword)
        }
        .font(.system(.caption, design: .monospaced))
        .foregroundColor(.green)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}
#endif

struct LineNumberView: View {
    let text: String
    
    private var lineCount: Int {
        max(1, text.components(separatedBy: "\n").count)
    }
    
    var body: some View {
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
        .background(PlatformAdaptive.sidebarBackgroundColor.opacity(0.3))
    }
}

#Preview {
    AdaptiveSchemeTextEditor(
        text: .constant("(define factorial\n  (lambda (n)\n    (if (<= n 1)\n        1\n        (* n (factorial (- n 1))))))"),
        autoIndentEnabled: true,
        bracketPairingEnabled: true
    )
    .frame(height: 400)
}