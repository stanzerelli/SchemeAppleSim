import SwiftUI

struct AdaptiveSidebar: View {
    @Binding var files: [String]
    @Binding var selectedFile: String?
    @Binding var renamingFile: String?
    
    let onSelectFile: (String) -> Void
    let onCreateFile: () -> Void
    let onRenameFile: (String, String) -> Void
    let onDeleteFile: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Files")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                PlatformAdaptive.adaptiveButton(action: onCreateFile) {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(PlatformAdaptive.sidebarBackgroundColor)
            
            Divider()
            
            // File list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(files, id: \.self) { file in
                        AdaptiveFileRow(
                            fileName: file,
                            isSelected: selectedFile == file,
                            isRenaming: renamingFile == file,
                            onSelect: {
                                onSelectFile(file)
                            },
                            onRename: { newName in
                                onRenameFile(file, newName)
                            },
                            onDelete: {
                                onDeleteFile(file)
                            }
                        )
                        #if os(macOS)
                        .onTapGesture(count: 2) {
                            renamingFile = file
                        }
                        #endif
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .frame(
            minWidth: PlatformAdaptive.minSidebarWidth,
            maxWidth: PlatformAdaptive.maxSidebarWidth
        )
        .background(PlatformAdaptive.sidebarBackgroundColor)
    }
}

struct AdaptiveFileRow: View {
    let fileName: String
    let isSelected: Bool
    let isRenaming: Bool
    let onSelect: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void
    
    @State private var newName = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack {
            if isRenaming {
                TextField("File name", text: $newName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if !newName.isEmpty {
                            onRename(newName)
                        }
                    }
                    .onAppear {
                        newName = fileName
                        isTextFieldFocused = true
                    }
            } else {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(fileName)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    #if os(iOS)
                    // iOS: Show context menu on long press
                    Menu {
                        fileContextMenu
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .opacity(isSelected ? 1 : 0)
                    #endif
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
                }
                #if os(macOS)
                .contextMenu {
                    fileContextMenu
                }
                #endif
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            isSelected ? Color.accentColor.opacity(0.2) : Color.clear
        )
        .cornerRadius(6)
    }
    
    @ViewBuilder
    private var fileContextMenu: some View {
        Button("Rename") {
            newName = fileName
            // Start renaming
            DispatchQueue.main.async {
                // This will be handled by the parent view
            }
        }
        
        Button("Delete", role: .destructive) {
            onDelete()
        }
    }
}

#Preview {
    AdaptiveSidebar(
        files: .constant(["example.scm", "test.scm", "factorial.scm"]),
        selectedFile: .constant("example.scm"),
        renamingFile: .constant(nil),
        onSelectFile: { _ in },
        onCreateFile: {},
        onRenameFile: { _, _ in },
        onDeleteFile: { _ in }
    )
    .frame(width: 300, height: 500)
}