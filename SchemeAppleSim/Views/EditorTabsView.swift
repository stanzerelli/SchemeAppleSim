import SwiftUI
import CodeEditorView
import LanguageSupport

struct EditorTabsView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            if !editorViewModel.openFiles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(editorViewModel.openFiles, id: \.id) { file in
                            EditorTabView(
                                file: file,
                                isActive: editorViewModel.activeFileId == file.id,
                                editorViewModel: editorViewModel
                            )
                        }
                        
                        Spacer()
                    }
                }
                .frame(height: 36)
                .background(editorViewModel.currentTheme.tabBarColor)
                
                Divider()
                    .background(editorViewModel.currentTheme.borderColor)
            }
            
            // Editor content
            if let activeFile = editorViewModel.activeFile {
                CodeEditorAreaView(file: activeFile, editorViewModel: editorViewModel)
            } else {
                WelcomeView(editorViewModel: editorViewModel)
            }
        }
    }
}

struct EditorTabView: View {
    let file: SchemeFile
    let isActive: Bool
    @ObservedObject var editorViewModel: EditorViewModel
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 6) {
            // File icon
            Image(systemName: getFileIcon(for: file.name))
                .font(.system(size: 12))
                .foregroundColor(getFileIconColor(for: file.name))
            
            // File name
            Text(file.name)
                .font(.system(size: 13))
                .foregroundColor(isActive ? 
                               editorViewModel.currentTheme.textColor : 
                               editorViewModel.currentTheme.secondaryTextColor)
                .lineLimit(1)
            
            // Close button
            if isHovering || isActive {
                Button(action: {
                    editorViewModel.closeFile(file)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 16, height: 16)
                .background(isHovering ? Color.red.opacity(0.8) : Color.clear)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? 
                   editorViewModel.currentTheme.backgroundColor : 
                   editorViewModel.currentTheme.tabBarColor)
        .border(width: 0, edges: [.bottom], color: isActive ? 
               editorViewModel.currentTheme.accentColor : 
               Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            editorViewModel.activeFileId = file.id
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
    
    private func getFileIcon(for fileName: String) -> String {
        if fileName.hasSuffix(".scm") || fileName.hasSuffix(".ss") || fileName.hasSuffix(".scheme") {
            return "scroll"
        } else if fileName.hasSuffix(".txt") {
            return "doc.text"
        } else if fileName.hasSuffix(".md") {
            return "doc.richtext"
        } else {
            return "doc"
        }
    }
    
    private func getFileIconColor(for fileName: String) -> Color {
        if fileName.hasSuffix(".scm") || fileName.hasSuffix(".ss") || fileName.hasSuffix(".scheme") {
            return .orange
        } else if fileName.hasSuffix(".txt") {
            return .blue
        } else if fileName.hasSuffix(".md") {
            return .green
        } else {
            return .gray
        }
    }
}

struct CodeEditorAreaView: View {
    let file: SchemeFile
    @ObservedObject var editorViewModel: EditorViewModel
    @State private var content: String = ""
    @State private var showingAutoComplete = false
    @State private var autoCompletePosition: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main editor
                ZStack(alignment: .topLeading) {
                    CodeEditor(
                        text: $content,
                        position: .constant(CodeEditor.Position()),
                        messages: .constant(Set()),
                        language: .swift()
                    )
                    .environment(\.codeEditorTheme, getCodeEditorTheme())
                    .onChange(of: content) { newValue in
                        editorViewModel.updateFileContent(file, content: newValue)
                    }
                    .overlay(
                        // Auto-complete overlay
                        AutoCompleteOverlay(
                            items: editorViewModel.editorState.autoCompleteItems,
                            isVisible: $showingAutoComplete,
                            position: autoCompletePosition,
                            theme: editorViewModel.currentTheme,
                            onSelect: { item in
                                insertAutoCompleteItem(item)
                            }
                        )
                    )
                    
                    // Line numbers (if minimap is disabled)
                    if !editorViewModel.showMinimap {
                        LineNumbersView(
                            content: content,
                            fontSize: editorViewModel.fontSize,
                            theme: editorViewModel.currentTheme
                        )
                    }
                }
                
                // Minimap
                if editorViewModel.showMinimap {
                    MinimapView(
                        content: content,
                        theme: editorViewModel.currentTheme
                    )
                    .frame(width: 80)
                }
            }
        }
        .onAppear {
            content = file.content
        }
        .onChange(of: file.id) { _ in
            content = file.content
        }
        .background(editorViewModel.currentTheme.backgroundColor)
    }
    
    private func getCodeEditorTheme() -> Theme {
        switch editorViewModel.currentTheme.name {
        case "VS Code Dark":
            return .defaultDark
        case "VS Code Light":
            return .defaultLight
        case "Default Dark":
            return .defaultDark
        default:
            return .defaultLight
        }
    }
    
    private func insertAutoCompleteItem(_ item: AutoCompleteItem) {
        // Insert the selected auto-complete item
        showingAutoComplete = false
        // Implementation would insert the item at cursor position
    }
}

struct AutoCompleteOverlay: View {
    let items: [AutoCompleteItem]
    @Binding var isVisible: Bool
    let position: CGPoint
    let theme: EditorTheme
    let onSelect: (AutoCompleteItem) -> Void
    @State private var selectedIndex = 0
    
    var body: some View {
        if isVisible && !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    AutoCompleteItemView(
                        item: item,
                        isSelected: index == selectedIndex,
                        theme: theme
                    )
                    .onTapGesture {
                        onSelect(item)
                    }
                }
            }
            .background(theme.backgroundColor)
            .border(theme.borderColor, width: 1)
            .cornerRadius(4)
            .shadow(radius: 4)
            .frame(maxWidth: 300, maxHeight: 200)
            .position(position)
        }
    }
}

struct AutoCompleteItemView: View {
    let item: AutoCompleteItem
    let isSelected: Bool
    let theme: EditorTheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.kind.icon)
                .font(.system(size: 12))
                .foregroundColor(item.kind.color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(item.text)
                                                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(theme.textColor)
                
                if let detail = item.detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? theme.selectionColor.opacity(0.5) : Color.clear)
    }
}

struct LineNumbersView: View {
    let content: String
    let fontSize: CGFloat
    let theme: EditorTheme
    
    private var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(1...lineCount, id: \.self) { lineNumber in
                Text("\(lineNumber)")
                    .font(.system(size: fontSize - 2, design: .monospaced))
                    .foregroundColor(theme.secondaryTextColor.opacity(0.7))
                    .frame(height: fontSize + 4)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .background(theme.sidebarColor.opacity(0.5))
        .frame(width: 50)
    }
}

struct MinimapView: View {
    let content: String
    let theme: EditorTheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 1) {
                let lines = content.components(separatedBy: .newlines)
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    Rectangle()
                        .fill(line.isEmpty ? Color.clear : theme.textColor.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(theme.sidebarColor)
        .border(theme.borderColor, width: 1)
    }
}

struct WelcomeView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "scroll")
                    .font(.system(size: 64))
                    .foregroundColor(editorViewModel.currentTheme.accentColor)
                
                VStack(spacing: 8) {
                    Text("Scheme Editor")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(editorViewModel.currentTheme.textColor)
                    
                    Text("A complete R5RS Scheme implementation with modern IDE features")
                        .font(.title3)
                        .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    editorViewModel.createNewFile()
                }) {
                    Label("New File", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(editorViewModel.currentTheme.accentColor)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                HStack(spacing: 16) {
                    Button(action: {
                        if let welcomeFile = editorViewModel.files.first(where: { $0.name == "welcome.scm" }) {
                            editorViewModel.openFile(welcomeFile)
                        }
                    }) {
                        Label("Open Welcome", systemImage: "book.circle")
                    }
                    
                    Button(action: {
                        if let examplesFile = editorViewModel.files.first(where: { $0.name == "examples.scm" }) {
                            editorViewModel.openFile(examplesFile)
                        }
                    }) {
                        Label("View Examples", systemImage: "lightbulb.circle")
                    }
                }
                .foregroundColor(editorViewModel.currentTheme.accentColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(editorViewModel.currentTheme.backgroundColor)
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: return width
                case .leading, .trailing: return rect.height
                }
            }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}

#Preview {
    EditorTabsView(editorViewModel: EditorViewModel())
        .frame(width: 800, height: 600)
}