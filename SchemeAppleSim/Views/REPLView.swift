import SwiftUI

struct REPLView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    @State private var inputText: String = ""
    @State private var isExpanded: Bool = true
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // REPL header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .font(.system(size: 12))
                        .foregroundColor(editorViewModel.currentTheme.accentColor)
                    
                    Text("Scheme REPL")
                        .font(.headline)
                        .foregroundColor(editorViewModel.currentTheme.textColor)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { editorViewModel.runCurrentFile() }) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 14))
                    }
                    .help("Run Current File")
                    
                    Button(action: { editorViewModel.clearConsole() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                    }
                    .help("Clear Console")
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .font(.system(size: 12))
                    }
                    .help(isExpanded ? "Collapse" : "Expand")
                }
                .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(editorViewModel.currentTheme.backgroundColor)
            
            if isExpanded {
                Divider()
                    .background(editorViewModel.currentTheme.borderColor)
                
                // Console output
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(editorViewModel.consoleOutput) { entry in
                                ConsoleEntryView(entry: entry, theme: editorViewModel.currentTheme)
                                    .id(entry.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: editorViewModel.consoleOutput.count) { _ in
                        if let lastEntry = editorViewModel.consoleOutput.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastEntry.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(minHeight: 100, maxHeight: 200)
                .background(editorViewModel.currentTheme.consoleBackgroundColor)
                
                Divider()
                    .background(editorViewModel.currentTheme.borderColor)
                
                // Input area
                HStack(spacing: 8) {
                    Text(">>")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(editorViewModel.currentTheme.accentColor)
                    
                    TextField("Enter Scheme expression...", text: $inputText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(editorViewModel.currentTheme.textColor)
                        .focused($isInputFocused)
                        .onSubmit {
                            evaluateInput()
                        }
                    
                    Button(action: evaluateInput) {
                        Image(systemName: "return")
                            .font(.system(size: 12))
                            .foregroundColor(editorViewModel.currentTheme.accentColor)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(editorViewModel.currentTheme.backgroundColor)
            }
        }
        .background(editorViewModel.currentTheme.backgroundColor)
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func evaluateInput() {
        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        // Add input to console
        editorViewModel.consoleOutput.append(
            ConsoleEntry(message: ">> \(input)", type: .info, timestamp: Date())
        )
        
        // Evaluate the expression
        editorViewModel.runSelectedCode(input)
        
        // Clear input
        inputText = ""
    }
}

struct ConsoleEntryView: View {
    let entry: ConsoleEntry
    let theme: EditorTheme
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Icon
            Image(systemName: entry.type.icon)
                .font(.system(size: 10))
                .foregroundColor(entry.type.color)
                .frame(width: 16)
            
            // Message
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.message)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(getMessageColor())
                    .textSelection(.enabled)
                
                Text(timeFormatter.string(from: entry.timestamp))
                    .font(.system(size: 9))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    private func getMessageColor() -> Color {
        switch entry.type {
        case .info:
            return theme.textColor
        case .output:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        }
    }
}

struct StatusBarView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    
    var body: some View {
        HStack {
            // Left side - file info
            HStack(spacing: 12) {
                if let activeFile = editorViewModel.activeFile {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 10))
                        Text(activeFile.name)
                            .font(.system(size: 11))
                    }
                    
                    Text("Scheme")
                        .font(.system(size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(editorViewModel.currentTheme.accentColor.opacity(0.2))
                        .cornerRadius(3)
                    
                    let lineCount = activeFile.content.components(separatedBy: .newlines).count
                    Text("\(lineCount) lines")
                        .font(.system(size: 11))
                }
            }
            
            Spacer()
            
            // Right side - editor settings
            HStack(spacing: 12) {
                Text("Spaces: \(editorViewModel.tabSize)")
                    .font(.system(size: 11))
                
                Text("UTF-8")
                    .font(.system(size: 11))
                
                Button(action: { editorViewModel.toggleDarkMode() }) {
                    Image(systemName: editorViewModel.currentTheme.name.contains("Dark") ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 11))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(editorViewModel.currentTheme.statusBarColor)
        .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
    }
}

// Extensions for theme colors
extension EditorTheme {
    var consoleBackgroundColor: Color {
        switch name {
        case "Default Dark", "VS Code Dark":
            return Color(.sRGB, red: 0.1, green: 0.1, blue: 0.1, opacity: 1.0)
        default:
            return Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1.0)
        }
    }
    
    var tabBarColor: Color {
        switch name {
        case "Default Dark", "VS Code Dark":
            return Color(.sRGB, red: 0.15, green: 0.15, blue: 0.15, opacity: 1.0)
        default:
            return Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1.0)
        }
    }
    
    var statusBarColor: Color {
        switch name {
        case "Default Dark", "VS Code Dark":
            return Color(.sRGB, red: 0.0, green: 0.47, blue: 0.84, opacity: 1.0)
        default:
            return Color(.sRGB, red: 0.0, green: 0.47, blue: 0.84, opacity: 1.0)
        }
    }
}

#Preview {
    VStack {
        REPLView(editorViewModel: EditorViewModel())
            .frame(height: 300)
        
        StatusBarView(editorViewModel: EditorViewModel())
    }
    .frame(width: 600)
}