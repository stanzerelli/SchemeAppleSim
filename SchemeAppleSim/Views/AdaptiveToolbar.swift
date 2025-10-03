import SwiftUI

struct AdaptiveToolbar: View {
    @Binding var showingSidebar: Bool
    @Binding var autoIndentEnabled: Bool
    @Binding var bracketPairingEnabled: Bool
    @Binding var autoSaveEnabled: Bool
    @Binding var hasUnsavedChanges: Bool
    
    let selectedFile: String?
    let onRunCode: () -> Void
    let onFormatCode: () -> Void
    let onSaveFile: () -> Void
    let isCodeEmpty: Bool
    
    var body: some View {
        HStack {
            // Left side controls
            HStack(spacing: 12) {
                #if os(iOS)
                // iOS uses navigation-style sidebar toggle
                if !showingSidebar {
                    PlatformAdaptive.adaptiveButton(action: { showingSidebar.toggle() }) {
                        Image(systemName: "sidebar.left")
                            .font(.title2)
                    }
                }
                #else
                // macOS uses traditional sidebar toggle
                PlatformAdaptive.adaptiveButton(action: { showingSidebar.toggle() }) {
                    Image(systemName: "sidebar.left")
                }
                #endif
                
                // File indicator
                if let fileName = selectedFile {
                    HStack(spacing: 4) {
                        Text(fileName)
                            .font(PlatformAdaptive.editorFont)
                            .foregroundColor(.secondary)
                        if hasUnsavedChanges {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Right side controls
            HStack(spacing: 8) {
                #if os(iOS)
                // iOS: More compact menu button
                Menu {
                    menuContent
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
                
                // iOS: Prominent run button
                Button("Run", action: onRunCode)
                    .buttonStyle(.borderedProminent)
                    .disabled(isCodeEmpty)
                    .font(.headline)
                #else
                // macOS: Traditional layout
                Menu {
                    menuContent
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .buttonStyle(PlainButtonStyle())
                
                Button("Run", action: onRunCode)
                    .buttonStyle(.borderedProminent)
                    .disabled(isCodeEmpty)
                #endif
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(PlatformAdaptive.toolbarBackgroundColor)
    }
    
    @ViewBuilder
    private var menuContent: some View {
        Toggle("Auto Indent", isOn: $autoIndentEnabled)
        Toggle("Bracket Pairing", isOn: $bracketPairingEnabled)
        Toggle("Auto Save", isOn: $autoSaveEnabled)
        Divider()
        Button("Format Code", action: onFormatCode)
        Button("Save File", action: onSaveFile)
        
        #if os(iOS)
        Divider()
        Button("Toggle Sidebar") {
            showingSidebar.toggle()
        }
        #endif
    }
}

#Preview {
    AdaptiveToolbar(
        showingSidebar: .constant(true),
        autoIndentEnabled: .constant(true),
        bracketPairingEnabled: .constant(true),
        autoSaveEnabled: .constant(true),
        hasUnsavedChanges: .constant(true),
        selectedFile: "example.scm",
        onRunCode: {},
        onFormatCode: {},
        onSaveFile: {},
        isCodeEmpty: false
    )
}