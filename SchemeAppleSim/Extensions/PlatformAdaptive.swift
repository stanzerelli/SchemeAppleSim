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
    
    // MARK: - Additional Color Adaptations
    
    /// Accent color for highlights
    static var accentColor: Color {
        Color.accentColor
    }
    
    /// Success/positive color
    static var successColor: Color {
        Color.green
    }
    
    /// Error/warning color  
    static var errorColor: Color {
        Color.red
    }
    
    /// Warning color
    static var warningColor: Color {
        Color.orange
    }
    
    /// Info color
    static var infoColor: Color {
        Color.blue
    }
    
    // MARK: - Additional Typography
    
    /// Title font for headers
    static var titleFont: Font {
        #if os(macOS)
        Font.system(.title, design: .default, weight: .semibold)
        #else
        Font.system(.title2, design: .default, weight: .semibold)
        #endif
    }
    
    /// Caption font for status and metadata
    static var captionFont: Font {
        Font.system(.caption, design: .default)
    }
    
    // MARK: - Additional Interactive Elements
    
    /// Platform-appropriate toggle style
    static func adaptiveToggleStyle() -> some ToggleStyle {
        #if os(macOS)
        CheckboxToggleStyle()
        #else
        SwitchToggleStyle()
        #endif
    }
    
    // MARK: - Additional Spacing and Sizing
    
    /// Standard content padding
    static var contentPadding: EdgeInsets {
        #if os(macOS)
        EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        #else
        EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        #endif
    }
    
    /// Compact padding for dense UI
    static var compactPadding: EdgeInsets {
        #if os(macOS)
        EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        #else
        EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        #endif
    }
    
    /// Standard corner radius
    static var cornerRadius: CGFloat {
        #if os(macOS)
        6
        #else
        8
        #endif
    }
    
    /// Large corner radius for prominent elements
    static var largeCornerRadius: CGFloat {
        #if os(macOS)
        8
        #else
        12
        #endif
    }
    
    // MARK: - Animation
    
    /// Standard animation for UI transitions
    static var standardAnimation: Animation {
        .easeInOut(duration: 0.2)
    }
    
    /// Quick animation for immediate feedback
    static var quickAnimation: Animation {
        .easeInOut(duration: 0.1)
    }
    
    /// Smooth animation for complex transitions
    static var smoothAnimation: Animation {
        .easeInOut(duration: 0.3)
    }
    
    // MARK: - Platform Detection
    
    /// True if running on macOS
    static var isMacOS: Bool {
        #if os(macOS)
        true
        #else
        false
        #endif
    }
    
    /// True if running on iOS/iPadOS
    static var isiOS: Bool {
        #if os(iOS)
        true
        #else
        false
        #endif
    }
    
    /// True if running on iPad specifically
    static var isiPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
    
    /// True if running on iPhone specifically
    static var isiPhone: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }
    
    // MARK: - Device Capabilities
    
    /// True if the device supports keyboard shortcuts
    static var supportsKeyboardShortcuts: Bool {
        #if os(macOS)
        true
        #else
        UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
    
    /// True if the device has a physical keyboard likely attached
    static var hasPhysicalKeyboard: Bool {
        #if os(macOS)
        true
        #else
        // On iOS, assume iPad might have external keyboard
        UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
    
    /// True if the device supports multiple windows
    static var supportsMultipleWindows: Bool {
        #if os(macOS)
        true
        #else
        if #available(iOS 13.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad
        } else {
            return false
        }
        #endif
    }
}