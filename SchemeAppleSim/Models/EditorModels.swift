import Foundation
import SwiftUI

// MARK: - File System Models

struct SchemeFile: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var content: String
    var path: String
    var isDirectory: Bool
    var children: [SchemeFile]
    var lastModified: Date
    
    init(name: String, content: String = "", path: String = "", isDirectory: Bool = false) {
        self.name = name
        self.content = content
        self.path = path
        self.isDirectory = isDirectory
        self.children = []
        self.lastModified = Date()
    }
    
    var isSchemeFile: Bool {
        name.hasSuffix(".scm") || name.hasSuffix(".ss") || name.hasSuffix(".scheme")
    }
    
    var icon: String {
        if isDirectory {
            return "folder"
        } else if isSchemeFile {
            return "doc.text"
        } else {
            return "doc"
        }
    }
}

// MARK: - Editor State

struct EditorState {
    var cursorPosition: TextPosition = TextPosition(line: 0, column: 0)
    var selection: TextRange?
    var scrollPosition: CGPoint = .zero
    var isAutoCompleteVisible: Bool = false
    var autoCompleteItems: [AutoCompleteItem] = []
}

struct TextPosition: Equatable {
    var line: Int
    var column: Int
}

struct TextRange: Equatable {
    var start: TextPosition
    var end: TextPosition
}

struct AutoCompleteItem: Identifiable {
    let id = UUID()
    let text: String
    let kind: AutoCompleteKind
    let detail: String?
    
    enum AutoCompleteKind {
        case keyword
        case function
        case variable
        case snippet
        case primitive
        
        var icon: String {
            switch self {
            case .keyword: return "k.square"
            case .function: return "f.square"
            case .variable: return "v.square"
            case .snippet: return "s.square"
            case .primitive: return "p.square"
            }
        }
        
        var color: Color {
            switch self {
            case .keyword: return .purple
            case .function: return .blue
            case .variable: return .green
            case .snippet: return .orange
            case .primitive: return .red
            }
        }
    }
}

// MARK: - Theme System

struct EditorTheme: Hashable {
    let name: String
    let background: Color
    let foreground: Color
    let selectionBackground: Color
    let lineNumberForeground: Color
    let currentLineBackground: Color
    let commentColor: Color
    let keywordColor: Color
    let stringColor: Color
    let numberColor: Color
    let symbolColor: Color
    let parenthesesColor: Color
    
    // Additional properties for UI consistency
    var backgroundColor: Color { background }
    var textColor: Color { foreground }
    var secondaryTextColor: Color { lineNumberForeground }
    var selectionColor: Color { selectionBackground }
    var borderColor: Color { Color(red: 0.3, green: 0.3, blue: 0.3) }
    var accentColor: Color { Color.accentColor }
    var sidebarColor: Color { Color(red: 0.95, green: 0.95, blue: 0.95) }
    
    static let defaultLight = EditorTheme(
        name: "Light",
        background: PlatformAdaptive.backgroundColor,
        foreground: Color.primary,
        selectionBackground: Color.accentColor.opacity(0.3),
        lineNumberForeground: Color.secondary,
        currentLineBackground: PlatformAdaptive.sidebarBackgroundColor,
        commentColor: Color.gray,
        keywordColor: Color.purple,
        stringColor: Color.red,
        numberColor: Color.blue,
        symbolColor: Color.green,
        parenthesesColor: Color.orange
    )
    
    static let defaultDark = EditorTheme(
        name: "Dark",
        background: Color(red: 0.12, green: 0.12, blue: 0.12),
        foreground: Color(red: 0.86, green: 0.86, blue: 0.86),
        selectionBackground: Color(red: 0.26, green: 0.35, blue: 0.49),
        lineNumberForeground: Color(red: 0.5, green: 0.5, blue: 0.5),
        currentLineBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
        commentColor: Color(red: 0.45, green: 0.55, blue: 0.45),
        keywordColor: Color(red: 0.8, green: 0.4, blue: 0.8),
        stringColor: Color(red: 0.9, green: 0.4, blue: 0.4),
        numberColor: Color(red: 0.4, green: 0.6, blue: 0.9),
        symbolColor: Color(red: 0.4, green: 0.8, blue: 0.4),
        parenthesesColor: Color(red: 0.9, green: 0.6, blue: 0.4)
    )
    
    static let vscodeLight = EditorTheme(
        name: "VS Code Light",
        background: Color.white,
        foreground: Color(red: 0.13, green: 0.13, blue: 0.13),
        selectionBackground: Color(red: 0.67, green: 0.84, blue: 1.0),
        lineNumberForeground: Color(red: 0.57, green: 0.57, blue: 0.57),
        currentLineBackground: Color(red: 0.98, green: 0.98, blue: 0.98),
        commentColor: Color(red: 0.0, green: 0.5, blue: 0.0),
        keywordColor: Color(red: 0.0, green: 0.0, blue: 1.0),
        stringColor: Color(red: 0.64, green: 0.08, blue: 0.08),
        numberColor: Color(red: 0.0, green: 0.4, blue: 0.8),
        symbolColor: Color(red: 0.4, green: 0.0, blue: 0.8),
        parenthesesColor: Color(red: 0.8, green: 0.4, blue: 0.0)
    )
    
    static let vscodeDark = EditorTheme(
        name: "VS Code Dark",
        background: Color(red: 0.12, green: 0.12, blue: 0.12),
        foreground: Color(red: 0.83, green: 0.83, blue: 0.83),
        selectionBackground: Color(red: 0.26, green: 0.35, blue: 0.49),
        lineNumberForeground: Color(red: 0.55, green: 0.55, blue: 0.55),
        currentLineBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
        commentColor: Color(red: 0.38, green: 0.50, blue: 0.36),
        keywordColor: Color(red: 0.33, green: 0.61, blue: 0.84),
        stringColor: Color(red: 0.81, green: 0.65, blue: 0.45),
        numberColor: Color(red: 0.71, green: 0.84, blue: 0.67),
        symbolColor: Color(red: 0.86, green: 0.67, blue: 0.53),
        parenthesesColor: Color(red: 1.0, green: 0.84, blue: 0.0)
    )
}