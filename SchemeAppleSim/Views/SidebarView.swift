import SwiftUI

struct SidebarView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    @State private var selectedTab: SidebarTab = .files
    @State private var isExpanded: Bool = true
    
    enum SidebarTab: String, CaseIterable {
        case files = "Files"
        case search = "Search"
        case extensions = "Extensions"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .files: return "folder"
            case .search: return "magnifyingglass"
            case .extensions: return "puzzlepiece"
            case .settings: return "gearshape"
            }
        }
    }
    
    var body: some View {
        #if os(macOS)
        HSplitView {
            // Sidebar tabs
            VStack(spacing: 0) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                            .foregroundColor(selectedTab == tab ? 
                                           editorViewModel.currentTheme.accentColor : 
                                           editorViewModel.currentTheme.secondaryTextColor)
                            .frame(width: 40, height: 40)
                            .background(selectedTab == tab ? 
                                      editorViewModel.currentTheme.selectionColor.opacity(0.3) : 
                                      Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(tab.rawValue)
                }
                
                Spacer()
            }
            .frame(width: 40)
            .background(editorViewModel.currentTheme.sidebarColor)
            
            // Content area
            if isExpanded {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(selectedTab.rawValue)
                            .font(.headline)
                            .foregroundColor(editorViewModel.currentTheme.textColor)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 12))
                                .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(editorViewModel.currentTheme.backgroundColor)
                    
                    Divider()
                        .background(editorViewModel.currentTheme.borderColor)
                    
                    // Content
                    switch selectedTab {
                    case .files:
                        FilesTabView(editorViewModel: editorViewModel)
                    case .search:
                        SearchTabView(editorViewModel: editorViewModel)
                    case .extensions:
                        ExtensionsTabView(editorViewModel: editorViewModel)
                    case .settings:
                        SettingsTabView(editorViewModel: editorViewModel)
                    }
                }
                .frame(width: 250)
                .background(editorViewModel.currentTheme.sidebarColor)
            }
        }
        #else
        // iOS version using HStack instead of HSplitView
        HStack(spacing: 0) {
            // Sidebar tabs
            VStack(spacing: 0) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                            .foregroundColor(selectedTab == tab ? 
                                           editorViewModel.currentTheme.accentColor : 
                                           editorViewModel.currentTheme.secondaryTextColor)
                            .frame(width: 40, height: 40)
                            .background(selectedTab == tab ? 
                                      editorViewModel.currentTheme.selectionColor.opacity(0.3) : 
                                      Color.clear)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .frame(width: 40)
            .background(editorViewModel.currentTheme.sidebarColor)
            
            // Content area
            if isExpanded {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(selectedTab.rawValue)
                            .font(.headline)
                            .foregroundColor(editorViewModel.currentTheme.textColor)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 12))
                                .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(editorViewModel.currentTheme.backgroundColor)
                    
                    Divider()
                        .background(editorViewModel.currentTheme.borderColor)
                    
                    // Content
                    switch selectedTab {
                    case .files:
                        FilesTabView(editorViewModel: editorViewModel)
                    case .search:
                        SearchTabView(editorViewModel: editorViewModel)
                    case .extensions:
                        ExtensionsTabView(editorViewModel: editorViewModel)
                    case .settings:
                        SettingsTabView(editorViewModel: editorViewModel)
                    }
                }
                .frame(width: 250)
                .background(editorViewModel.currentTheme.sidebarColor)
            }
        }
        #endif
    }
}

struct FilesTabView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    @State private var expandedFolders: Set<String> = ["/"]
    
    var body: some View {
        VStack(spacing: 0) {
            // File operations toolbar
            HStack {
                Button(action: { editorViewModel.createNewFile() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                }
                .help("New File")
                
                Button(action: { /* New Folder */ }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12))
                }
                .help("New Folder")
                
                Button(action: { /* Refresh */ }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .help("Refresh")
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
            
            Divider()
                .background(editorViewModel.currentTheme.borderColor)
            
            // Files tree
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(editorViewModel.files, id: \.id) { file in
                        FileRowView(
                            file: file,
                            editorViewModel: editorViewModel,
                            isActive: editorViewModel.activeFileId == file.id
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct FileRowView: View {
    let file: SchemeFile
    @ObservedObject var editorViewModel: EditorViewModel
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: file.isDirectory ? "folder" : "doc.text")
                .font(.system(size: 12))
                .foregroundColor(file.isDirectory ? .blue : .gray)
            
            Text(file.name)
                .font(.system(size: 13))
                .foregroundColor(isActive ? 
                               editorViewModel.currentTheme.accentColor : 
                               editorViewModel.currentTheme.textColor)
            
            Spacer()
            
            if file.name.hasSuffix(".scm") || file.name.hasSuffix(".ss") || file.name.hasSuffix(".scheme") {
                Image(systemName: "scroll")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(isActive ? 
                   editorViewModel.currentTheme.selectionColor.opacity(0.5) : 
                   Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if !file.isDirectory {
                editorViewModel.openFile(file)
            }
        }
        .contextMenu {
            Button("Open") {
                editorViewModel.openFile(file)
            }
            
            Button("Rename") {
                // Implement rename
            }
            
            Button("Delete") {
                // Implement delete
            }
            
            Divider()
            
            Button("Copy Path") {
                // Copy file path to clipboard
            }
        }
    }
}

struct SearchTabView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    @State private var searchQuery: String = ""
    @State private var caseSensitive: Bool = false
    @State private var wholeWord: Bool = false
    @State private var useRegex: Bool = false
    @State private var searchResults: [SearchResult] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Search input
            VStack(spacing: 8) {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    Button(action: performSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 12))
                    }
                }
                
                HStack {
                    Toggle("Aa", isOn: $caseSensitive)
                        .help("Match Case")
                    Toggle("Ab", isOn: $wholeWord)
                        .help("Match Whole Word")
                    Toggle(".*", isOn: $useRegex)
                        .help("Use Regular Expression")
                    Spacer()
                }
                .toggleStyle(ButtonToggleStyle())
                .font(.system(size: 10))
            }
            .padding(12)
            
            Divider()
                .background(editorViewModel.currentTheme.borderColor)
            
            // Search results
            if searchResults.isEmpty && !searchQuery.isEmpty {
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
                    Text("No results found")
                        .font(.caption)
                        .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(searchResults, id: \.id) { result in
                            SearchResultRow(result: result, editorViewModel: editorViewModel)
                        }
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        searchResults = []
        
        for file in editorViewModel.files {
            if file.isDirectory { continue }
            
            let lines = file.content.components(separatedBy: .newlines)
            for (lineIndex, line) in lines.enumerated() {
                if lineContainsQuery(line, query: searchQuery) {
                    let result = SearchResult(
                        file: file,
                        lineNumber: lineIndex + 1,
                        lineContent: line,
                        matchRange: findMatchRange(in: line, query: searchQuery)
                    )
                    searchResults.append(result)
                }
            }
        }
    }
    
    private func lineContainsQuery(_ line: String, query: String) -> Bool {
        if useRegex {
            return line.range(of: query, options: [.regularExpression, caseSensitive ? [] : .caseInsensitive]) != nil
        } else if wholeWord {
            let words = line.components(separatedBy: .whitespacesAndNewlines)
            return words.contains { word in
                caseSensitive ? word == query : word.lowercased() == query.lowercased()
            }
        } else {
            return caseSensitive ? line.contains(query) : line.lowercased().contains(query.lowercased())
        }
    }
    
    private func findMatchRange(in line: String, query: String) -> NSRange? {
        var options: String.CompareOptions = []
        if useRegex {
            options.insert(.regularExpression)
        }
        if !caseSensitive {
            options.insert(.caseInsensitive)
        }
        
        if let range = line.range(of: query, options: options) {
            return NSRange(range, in: line)
        }
        return nil
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let file: SchemeFile
    let lineNumber: Int
    let lineContent: String
    let matchRange: NSRange?
}

struct SearchResultRow: View {
    let result: SearchResult
    @ObservedObject var editorViewModel: EditorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                
                Text(result.file.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(editorViewModel.currentTheme.textColor)
                
                Spacer()
                
                Text("\(result.lineNumber)")
                    .font(.system(size: 10))
                    .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
            }
            
            Text(result.lineContent.trimmingCharacters(in: .whitespaces))
                                                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            editorViewModel.openFile(result.file)
            // TODO: Navigate to specific line
        }
    }
}

struct ExtensionsTabView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    
    var body: some View {
        VStack {
            Image(systemName: "puzzlepiece")
                .font(.system(size: 24))
                .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
            
            Text("Extensions")
                .font(.headline)
                .foregroundColor(editorViewModel.currentTheme.textColor)
            
            Text("Future extension support")
                .font(.caption)
                .foregroundColor(editorViewModel.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsTabView: View {
    @ObservedObject var editorViewModel: EditorViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Theme settings
                GroupBox("Appearance") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Theme:")
                            Spacer()
                            Picker("Theme", selection: $editorViewModel.currentTheme) {
                                Text("Light").tag(EditorTheme.defaultLight)
                            Text("Dark").tag(EditorTheme.defaultDark)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        HStack {
                            Text("Font Size:")
                            Spacer()
                            Stepper("\(Int(editorViewModel.fontSize))", 
                                   value: $editorViewModel.fontSize, 
                                   in: 10...24)
                        }
                    }
                }
                
                // Editor settings
                GroupBox("Editor") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Auto Complete", isOn: $editorViewModel.enableAutoComplete)
                        Toggle("Auto Indent", isOn: $editorViewModel.enableAutoIndent)
                        Toggle("Insert Spaces", isOn: $editorViewModel.insertSpaces)
                        
                        HStack {
                            Text("Tab Size:")
                            Spacer()
                            Stepper("\(editorViewModel.tabSize)", 
                                   value: $editorViewModel.tabSize, 
                                   in: 1...8)
                        }
                    }
                }
                
                // View settings
                GroupBox("View") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show Sidebar", isOn: $editorViewModel.showSidebar)
                        Toggle("Show REPL", isOn: $editorViewModel.showREPL)
                        Toggle("Show Minimap", isOn: $editorViewModel.showMinimap)
                    }
                }
            }
            .padding(12)
        }
    }
}

struct ButtonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            configuration.label
                                                .font(.system(size: 10, design: .monospaced))
                .frame(width: 20, height: 20)
                .background(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(configuration.isOn ? .white : .primary)
                .cornerRadius(3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SidebarView(editorViewModel: EditorViewModel())
        .frame(width: 300, height: 600)
}