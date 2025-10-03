import SwiftUI

struct AdaptiveSchemeTextEditor: View {
    @Binding var text: String
    let autoIndentEnabled: Bool
    let bracketPairingEnabled: Bool
    
    @FocusState private var isEditorFocused: Bool
    @State private var textEditorHeight: CGFloat = 200
    
    var body: some View {
        #if os(macOS)
        macOSEditor
        #else
        iOSEditor
        #endif
    }
    
    #if os(macOS)
    private var macOSEditor: some View {
        TextEditor(text: $text)
            .font(PlatformAdaptive.editorFont)
            .background(Color.primary.opacity(0.05))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(";; Enter your Scheme code here...\n;; Features: Auto-format, pretty-print, bracket awareness")
                        .foregroundColor(.secondary)
                        .font(PlatformAdaptive.editorFont)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
            }
    }
    #endif
    
    #if os(iOS)
    private var iOSEditor: some View {
        VStack(spacing: 0) {
            // iOS-specific toolbar for common Scheme symbols
            SchemeSymbolToolbar(onInsertText: insertText)
            
            // Main text editor
            TextEditor(text: $text)
                .font(PlatformAdaptive.editorFont)
                .focused($isEditorFocused)
                .background(Color(UIColor.systemBackground))
                .onChange(of: text) { newValue in
                    if autoIndentEnabled {
                        handleAutoIndent(newValue)
                    }
                    if bracketPairingEnabled {
                        handleBracketPairing(newValue)
                    }
                }
                .overlay(
                    // Line numbers (simplified for iOS)
                    HStack {
                        LineNumberView(text: text)
                            .padding(.leading, 8)
                        Spacer()
                    },
                    alignment: .leading
                )
        }
    }
    #endif
    
    private func insertText(_ symbol: String) {
        text += symbol
        isEditorFocused = true
    }
    
    private func handleAutoIndent(_ newText: String) {
        // Simplified auto-indent for mobile
        if newText.hasSuffix("\n") {
            let lines = newText.components(separatedBy: "\n")
            if lines.count > 1 {
                let previousLine = lines[lines.count - 2]
                let indent = getIndentLevel(for: previousLine)
                text = newText + String(repeating: " ", count: indent * 2)
            }
        }
    }
    
    private func handleBracketPairing(_ newText: String) {
        // Simplified bracket pairing for mobile
        if newText.hasSuffix("(") {
            text = newText + ")"
            // Move cursor back one position (simplified)
        }
    }
    
    private func getIndentLevel(for line: String) -> Int {
        var level = 0
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
}

#if os(iOS)
struct SchemeSymbolToolbar: View {
    let onInsertText: (String) -> Void
    
    private let symbols = ["(", ")", "'", "`", ",", "λ", "define", "lambda", "let", "if"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(symbols, id: \.self) { symbol in
                    Button(symbol) {
                        onInsertText(symbol)
                    }
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 44)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

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
                    .frame(width: 30, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
}
#endif

#Preview {
    AdaptiveSchemeTextEditor(
        text: .constant("(define factorial\n  (lambda (n)\n    (if (<= n 1)\n        1\n        (* n (factorial (- n 1))))))"),
        autoIndentEnabled: true,
        bracketPairingEnabled: true
    )
}