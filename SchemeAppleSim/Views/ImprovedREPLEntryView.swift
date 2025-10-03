import SwiftUI

/// Clean, improved REPL entry view with better styling
struct ImprovedREPLEntryView: View {
    let entry: OutputEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Input section
            if !entry.input.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    // Prompt indicator
                    Text(">")
                        .font(.system(.body, design: .monospaced, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 16, alignment: .leading)
                    
                    // Input code with syntax highlighting
                    SyntaxHighlightedText(
                        text: entry.input,
                        font: PlatformAdaptive.editorFont
                    )
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    // Copy button
                    PlatformAdaptive.adaptiveButton(action: {
                        copyToClipboard(entry.input)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: PlatformAdaptive.cornerRadius)
                        .fill(PlatformAdaptive.sidebarBackgroundColor.opacity(0.3))
                )
            }
            
            // Output section
            if !entry.output.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    // Result indicator
                    Text("⇒")
                        .font(.system(.body, design: .default, weight: .medium))
                        .foregroundColor(entry.isError ? PlatformAdaptive.errorColor : PlatformAdaptive.successColor)
                        .frame(width: 16, alignment: .leading)
                    
                    // Output text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.output)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(entry.isError ? PlatformAdaptive.errorColor : .primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Execution info
                        Text("Executed at \(entry.timestamp, formatter: timeFormatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Copy output button
                    PlatformAdaptive.adaptiveButton(action: {
                        copyToClipboard(entry.output)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: PlatformAdaptive.cornerRadius)
                        .fill(
                            entry.isError 
                                ? PlatformAdaptive.errorColor.opacity(0.05)
                                : PlatformAdaptive.successColor.opacity(0.05)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: PlatformAdaptive.cornerRadius)
                                .stroke(
                                    entry.isError 
                                        ? PlatformAdaptive.errorColor.opacity(0.2)
                                        : PlatformAdaptive.successColor.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
            }
        }
        .animation(PlatformAdaptive.quickAnimation, value: entry.output)
    }
    
    // MARK: - Helper Functions
    
    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }
}

/// Syntax highlighted text view for Scheme code
struct SyntaxHighlightedText: View {
    let text: String
    let font: Font
    
    var body: some View {
        // For now, use a simple Text view
        // In the future, this could be enhanced with actual syntax highlighting
        Text(text)
            .font(font)
            .foregroundColor(.primary)
    }
}

#Preview {
    VStack(spacing: 16) {
        ImprovedREPLEntryView(
            entry: OutputEntry(
                input: "(define factorial (lambda (n) (if (<= n 1) 1 (* n (factorial (- n 1))))))",
                output: "factorial",
                isError: false
            )
        )
        
        ImprovedREPLEntryView(
            entry: OutputEntry(
                input: "(factorial 5)",
                output: "120",
                isError: false
            )
        )
        
        ImprovedREPLEntryView(
            entry: OutputEntry(
                input: "(undefined-function)",
                output: "Error: Undefined function 'undefined-function'",
                isError: true
            )
        )
    }
    .padding()
    .background(PlatformAdaptive.backgroundColor)
}