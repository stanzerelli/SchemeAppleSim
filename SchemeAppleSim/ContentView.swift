import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var interpreter = SchemeInterpreterViewModel()
    @State private var currentCode = ""
    @State private var showingSidebar = true
    @State private var selectedFile: String? = nil
    @State private var files: [String] = ["example.scm"]
    @State private var fileContents: [String: String] = ["example.scm": ";; Welcome to Scheme Editor\n(define factorial\n  (lambda (n)\n    (if (<= n 1)\n        1\n        (* n (factorial (- n 1))))))\n\n(factorial 5)"]
    @State private var renamingFile: String? = nil
    @State private var autoIndentEnabled = true
    @State private var bracketPairingEnabled = true
    @State private var autoSaveEnabled = true
    @State private var hasUnsavedChanges = false
    
    var body: some View {
        HSplitView {
            // Sidebar
            if showingSidebar {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("Files")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: createNewFile) {
                            Image(systemName: "plus")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // File list
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(files, id: \.self) { file in
                                SimpleFileRowView(
                                    fileName: file, 
                                    isSelected: selectedFile == file,
                                    isRenaming: renamingFile == file,
                                    onSelect: {
                                        saveCurrentFile()
                                        selectedFile = file
                                        currentCode = fileContents[file] ?? ""
                                        hasUnsavedChanges = false
                                    },
                                    onRename: { newName in
                                        renameFile(from: file, to: newName)
                                    },
                                    onDelete: {
                                        deleteFile(file)
                                    }
                                )
                                .onTapGesture(count: 2) {
                                    renamingFile = file
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                }
                .frame(minWidth: 200, maxWidth: 300)
                .background(Color(NSColor.controlBackgroundColor))
            }
            
            // Main editor area
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Button(action: { showingSidebar.toggle() }) {
                        Image(systemName: "sidebar.left")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if let fileName = selectedFile {
                        HStack(spacing: 4) {
                            Text(fileName)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                            if hasUnsavedChanges {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Editor options
                    Menu {
                        Toggle("Auto Indent", isOn: $autoIndentEnabled)
                        Toggle("Bracket Pairing", isOn: $bracketPairingEnabled)
                        Toggle("Auto Save", isOn: $autoSaveEnabled)
                        Divider()
                        Button("Format Code") { formatCurrentCode() }
                        Button("Save File") { saveCurrentFile() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button("Run", action: runCode)
                        .buttonStyle(.borderedProminent)
                        .disabled(currentCode.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Editor
                VSplitView {
                    // Text editor
                    VStack(spacing: 0) {
                        AdvancedSchemeTextEditor(
                            text: $currentCode,
                            autoIndentEnabled: autoIndentEnabled,
                            bracketPairingEnabled: bracketPairingEnabled
                        )
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: currentCode) { newValue in
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
                    }
                    .frame(minHeight: 200)
                    
                    // REPL Output
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("REPL Output")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("Clear") {
                                interpreter.outputHistory.removeAll()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.controlBackgroundColor))
                        
                        Divider()
                        
                        ScrollView {
                            ScrollViewReader { proxy in
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(interpreter.outputHistory.indices, id: \.self) { index in
                                        let entry = interpreter.outputHistory[index]
                                        HStack(alignment: .top, spacing: 8) {
                                            Text(entry.isError ? "❌" : "➤")
                                                .foregroundColor(entry.isError ? .red : .blue)
                                            Text(entry.output)
                                                .font(.system(.body, design: .monospaced))
                                                .foregroundColor(entry.isError ? .red : .primary)
                                                .textSelection(.enabled)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .id(index)
                                    }
                                }
                                .onChange(of: interpreter.outputHistory.count) { _ in
                                    if let lastIndex = interpreter.outputHistory.indices.last {
                                        proxy.scrollTo(lastIndex, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .background(Color(NSColor.textBackgroundColor))
                    }
                    .frame(minHeight: 150, maxHeight: 400)
                }
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Text("Scheme Editor")
                    .font(.title2)
                    .fontWeight(.medium)
            }
        }
    }
    
    private func createNewFile() {
        saveCurrentFile()
        let fileName = "untitled\(files.count + 1).scm"
        files.append(fileName)
        fileContents[fileName] = ";; New file\n"
        selectedFile = fileName
        currentCode = fileContents[fileName] ?? ""
        hasUnsavedChanges = false
    }
    
    private func renameFile(from oldName: String, to newName: String) {
        guard !newName.isEmpty && !files.contains(newName) else { return }
        
        if let index = files.firstIndex(of: oldName) {
            files[index] = newName
            if let content = fileContents[oldName] {
                fileContents[newName] = content
                fileContents.removeValue(forKey: oldName)
            }
            if selectedFile == oldName {
                selectedFile = newName
            }
        }
        renamingFile = nil
    }
    
    private func deleteFile(_ fileName: String) {
        files.removeAll { $0 == fileName }
        fileContents.removeValue(forKey: fileName)
        if selectedFile == fileName {
            selectedFile = files.first
            currentCode = selectedFile.map { fileContents[$0] ?? "" } ?? ""
        }
    }
    
    private func saveCurrentFile() {
        guard let fileName = selectedFile else { return }
        fileContents[fileName] = currentCode
        hasUnsavedChanges = false
        // TODO: Implement actual file system saving with iCloud sync
    }
    
    private func formatCurrentCode() {
        currentCode = SchemeFormatter.format(currentCode)
        hasUnsavedChanges = true
    }
    
    private func runCode() {
        guard !currentCode.isEmpty else { return }
        saveCurrentFile()
        interpreter.currentInput = currentCode
        interpreter.evaluateInput()
    }
}

struct SimpleFileRowView: View {
    let fileName: String
    let isSelected: Bool
    let isRenaming: Bool
    let onSelect: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void
    
    @State private var editingName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            if isRenaming {
                TextField("File name", text: $editingName, onCommit: {
                    if !editingName.isEmpty {
                        onRename(editingName)
                    }
                })
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isTextFieldFocused)
                .onAppear {
                    editingName = fileName
                    isTextFieldFocused = true
                }
            } else {
                Text(fileName)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor : Color.clear)
        .cornerRadius(4)
        .onTapGesture {
            if !isRenaming {
                onSelect()
            }
        }
        .contextMenu {
            Button("Rename") {
                editingName = fileName
            }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
        .contentShape(Rectangle())
    }
}

struct AdvancedSchemeTextEditor: View {
    @Binding var text: String
    let autoIndentEnabled: Bool
    let bracketPairingEnabled: Bool
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .focused($isFocused)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(";; Enter your Scheme code here...\\n;; Features: Auto-format, pretty-print, bracket awareness")
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}

// MARK: - Scheme Code Formatter
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
            
            // Adjust indent level for closing brackets
            let closingBrackets = trimmedLine.prefix { $0 == ")" || $0 == "]" || $0 == "}" }
            indentLevel = max(0, indentLevel - closingBrackets.count)
            
            // Apply current indentation
            let indentedLine = String(repeating: " ", count: indentLevel * 2) + trimmedLine
            formattedLines.append(indentedLine)
            
            // Adjust indent level for opening brackets
            let openingBrackets = trimmedLine.filter { $0 == "(" || $0 == "[" || $0 == "{" }.count
            let closingInLine = trimmedLine.filter { $0 == ")" || $0 == "]" || $0 == "}" }.count
            indentLevel += (openingBrackets - closingInLine)
        }
        
        return formattedLines.joined(separator: "\n")
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
