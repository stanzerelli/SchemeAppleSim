import SwiftUI
import UniformTypeIdentifiers

struct AdaptiveContentView: View {
    @StateObject private var interpreter = SchemeInterpreterViewModel()
    @State private var currentCode = ""
    @State private var showingSidebar = true
    @State private var selectedFile: String? = nil
    @State private var files: [String] = ["example.scm"]
    @State private var fileContents: [String: String] = [
        "example.scm": """
;; Welcome to Scheme Editor
(define factorial
  (lambda (n)
    (if (<= n 1)
        1
        (* n (factorial (- n 1))))))

(factorial 5)
"""
    ]
    @State private var renamingFile: String? = nil
    @State private var autoIndentEnabled = true
    @State private var bracketPairingEnabled = true
    @State private var autoSaveEnabled = true
    @State private var hasUnsavedChanges = false
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                #if os(macOS)
                macOSLayout
                #else
                iOSLayout(geometry: geometry)
                #endif
            }
        }
        .onAppear {
            // Load first file on startup
            if selectedFile == nil && !files.isEmpty {
                selectFile(files[0])
            }
        }
    }
    
    #if os(macOS)
    private var macOSLayout: some View {
        PlatformAdaptive.splitView {
            // Sidebar
            if showingSidebar {
                AdaptiveSidebar(
                    files: $files,
                    selectedFile: $selectedFile,
                    renamingFile: $renamingFile,
                    onSelectFile: selectFile,
                    onCreateFile: createNewFile,
                    onRenameFile: renameFile,
                    onDeleteFile: deleteFile
                )
            }
        } secondary: {
            mainEditorArea
        }
    }
    #endif
    
    #if os(iOS)
    private func iOSLayout(geometry: GeometryProxy) -> some View {
        NavigationSplitView {
            AdaptiveSidebar(
                files: $files,
                selectedFile: $selectedFile,
                renamingFile: $renamingFile,
                onSelectFile: selectFile,
                onCreateFile: createNewFile,
                onRenameFile: renameFile,
                onDeleteFile: deleteFile
            )
            .navigationTitle("Files")
            .navigationBarTitleDisplayMode(.inline)
        } detail: {
            if selectedFile != nil {
                mainEditorArea
                    .navigationBarHidden(true)
            } else {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a file to start editing")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
    #endif
    
    private var mainEditorArea: some View {
        VStack(spacing: 0) {
            // Adaptive toolbar
            AdaptiveToolbar(
                showingSidebar: $showingSidebar,
                autoIndentEnabled: $autoIndentEnabled,
                bracketPairingEnabled: $bracketPairingEnabled,
                autoSaveEnabled: $autoSaveEnabled,
                hasUnsavedChanges: $hasUnsavedChanges,
                selectedFile: selectedFile,
                onRunCode: runCode,
                onFormatCode: formatCurrentCode,
                onSaveFile: saveCurrentFile,
                isCodeEmpty: currentCode.isEmpty
            )
            
            Divider()
            
            // Editor and output
            PlatformAdaptive.verticalSplitView {
                // Text editor
                AdaptiveSchemeTextEditor(
                    text: $currentCode,
                    autoIndentEnabled: autoIndentEnabled,
                    bracketPairingEnabled: bracketPairingEnabled
                )
                .onChange(of: currentCode) { _, newValue in
                    handleCodeChange(newValue)
                }
                .frame(minHeight: PlatformAdaptive.minEditorHeight)
            } bottom: {
                // REPL Output
                replOutputView
            }
        }
    }
    
    private var replOutputView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("REPL Output")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                PlatformAdaptive.adaptiveButton(action: clearOutput) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(PlatformAdaptive.toolbarBackgroundColor)
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(interpreter.outputHistory.indices, id: \.self) { index in
                        let entry = interpreter.outputHistory[index]
                        REPLEntryView(entry: entry)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(PlatformAdaptive.backgroundColor)
        }
        .frame(minHeight: 120)
    }
    
    // MARK: - Actions
    
    private func selectFile(_ file: String) {
        saveCurrentFile()
        selectedFile = file
        currentCode = fileContents[file] ?? ""
        hasUnsavedChanges = false
        
        #if os(iOS)
        // On iOS, hide sidebar after selection
        showingSidebar = false
        #endif
    }
    
    private func createNewFile() {
        let newFileName = "untitled\(files.count + 1).scm"
        files.append(newFileName)
        fileContents[newFileName] = ";; New Scheme file\n"
        selectFile(newFileName)
    }
    
    private func renameFile(from oldName: String, to newName: String) {
        guard !newName.isEmpty, newName != oldName else { return }
        
        let finalName = newName.hasSuffix(".scm") ? newName : "\(newName).scm"
        
        if let index = files.firstIndex(of: oldName) {
            files[index] = finalName
            if let content = fileContents[oldName] {
                fileContents[finalName] = content
                fileContents.removeValue(forKey: oldName)
            }
            if selectedFile == oldName {
                selectedFile = finalName
            }
        }
        renamingFile = nil
    }
    
    private func deleteFile(_ fileName: String) {
        files.removeAll { $0 == fileName }
        fileContents.removeValue(forKey: fileName)
        
        if selectedFile == fileName {
            selectedFile = files.first
            currentCode = selectedFile != nil ? (fileContents[selectedFile!] ?? "") : ""
        }
    }
    
    private func handleCodeChange(_ newValue: String) {
        if let file = selectedFile {
            fileContents[file] = newValue
            hasUnsavedChanges = true
            
            if autoSaveEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    saveCurrentFile()
                }
            }
        }
    }
    
    private func saveCurrentFile() {
        if let file = selectedFile {
            fileContents[file] = currentCode
            hasUnsavedChanges = false
            // Here you would implement actual file saving
        }
    }
    
    private func formatCurrentCode() {
        if !currentCode.isEmpty {
            currentCode = SchemeFormatter.format(currentCode)
        }
    }
    
    private func runCode() {
        guard !currentCode.isEmpty else { return }
        interpreter.currentInput = currentCode
        interpreter.evaluateInput()
    }
    
    private func clearOutput() {
        interpreter.clearOutput()
    }
}

// MARK: - Supporting Views

struct REPLEntryView: View {
    let entry: OutputEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("→")
                    .foregroundColor(.accentColor)
                    .font(.system(.body, design: .monospaced))
                Text(entry.input)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("  ")
                if entry.isError {
                    Text(entry.output)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.red)
                } else {
                    Text(entry.output)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Scheme Formatter

struct SchemeFormatter {
    static func format(_ code: String) -> String {
        let lines = code.components(separatedBy: .newlines)
        var formattedLines: [String] = []
        var indentLevel = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            guard !trimmedLine.isEmpty else {
                formattedLines.append("")
                continue
            }
            
            // Calculate indent level changes
            let openBrackets = trimmedLine.filter { "([{".contains($0) }.count
            let closeBrackets = trimmedLine.filter { ")]}".contains($0) }.count
            
            // Adjust indent for closing brackets at the start
            if trimmedLine.hasPrefix(")") || trimmedLine.hasPrefix("]") || trimmedLine.hasPrefix("}") {
                indentLevel = max(0, indentLevel - 1)
            }
            
            // Apply current indentation
            let indent = String(repeating: "  ", count: indentLevel)
            formattedLines.append(indent + trimmedLine)
            
            // Adjust indent level for next line
            indentLevel += openBrackets - closeBrackets
            indentLevel = max(0, indentLevel)
        }
        
        return formattedLines.joined(separator: "\n")
    }
}

#Preview {
    AdaptiveContentView()
}