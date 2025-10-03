import SwiftUI

/// Platform-specific UI utilities and adaptations
struct PlatformAdaptive {
    
    /// Returns the appropriate split view for the current platform
    @ViewBuilder
    static func splitView<Primary: View, Secondary: View>(
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) -> some View {
        #if os(macOS)
        HSplitView {
            primary()
            secondary()
        }
        #else
        NavigationSplitView {
            primary()
        } detail: {
            secondary()
        }
        #endif
    }
    
    /// Returns the appropriate vertical split view for the current platform
    @ViewBuilder
    static func verticalSplitView<Top: View, Bottom: View>(
        @ViewBuilder top: () -> Top,
        @ViewBuilder bottom: () -> Bottom
    ) -> some View {
        #if os(macOS)
        VSplitView {
            top()
            bottom()
        }
        #else
        VStack(spacing: 0) {
            top()
            Divider()
            bottom()
        }
        #endif
    }
    
    /// Platform-appropriate toolbar styling
    static var toolbarBackgroundColor: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }
    
    /// Platform-appropriate sidebar background
    static var sidebarBackgroundColor: Color {
        #if os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }
    
    /// Platform-appropriate background color
    static var backgroundColor: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }
    
    /// Adaptive font for the platform
    static var editorFont: Font {
        #if os(macOS)
        .system(.body, design: .monospaced)
        #else
        .system(.callout, design: .monospaced)
        #endif
    }
    
    /// Platform-appropriate button style
    @ViewBuilder
    static func adaptiveButton<Content: View>(
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Content
    ) -> some View {
        #if os(macOS)
        Button(action: action, label: label)
            .buttonStyle(PlainButtonStyle())
        #else
        Button(action: action, label: label)
            .buttonStyle(BorderlessButtonStyle())
        #endif
    }
    
    /// Minimum sidebar width for the platform
    static var minSidebarWidth: CGFloat {
        #if os(macOS)
        200
        #else
        280
        #endif
    }
    
    /// Maximum sidebar width for the platform
    static var maxSidebarWidth: CGFloat {
        #if os(macOS)
        300
        #else
        350
        #endif
    }
    
    /// Default editor minimum height
    static var minEditorHeight: CGFloat {
        #if os(macOS)
        200
        #else
        150
        #endif
    }
}