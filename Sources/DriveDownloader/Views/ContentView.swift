import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case downloads = "Transferências"
    case history = "Histórico"
    case settings = "Configurações"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .downloads: return "arrow.up.arrow.down.circle"
        case .history: return "clock"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var manager: DownloadManager
    @State private var selection: SidebarItem? = .downloads
    @State private var showAddDownloadSheet = false
    @State private var showAddUploadSheet = false
    @State private var isDragOver = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .sheet(isPresented: $showAddDownloadSheet) {
            AddDownloadView()
                .environmentObject(manager)
        }
        .sheet(isPresented: $showAddUploadSheet) {
            AddUploadView()
                .environmentObject(manager)
        }
        .alert("Espaço em Disco", isPresented: Binding(
            get: { manager.diskSpaceWarning != nil },
            set: { if !$0 { manager.diskSpaceWarning = nil } }
        )) {
            Button("OK", role: .cancel) {
                manager.diskSpaceWarning = nil
            }
        } message: {
            Text(manager.diskSpaceWarning ?? "")
        }
        .preferredColorScheme(.dark)
        .onDrop(of: [.text, .url], isTargeted: $isDragOver) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDragOver {
                dropOverlay
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            ForEach(SidebarItem.allCases) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 14))
                        .foregroundColor(selection == item ? AppTheme.accent : AppTheme.textMuted)
                        .frame(width: 20)

                    Text(item.rawValue)
                        .font(.system(size: 13, weight: selection == item ? .semibold : .regular))
                        .foregroundColor(selection == item ? AppTheme.textPrimary : AppTheme.textSecondary)

                    Spacer()

                    let count = badgeCount(for: item)
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(AppTheme.accent))
                    }
                }
                .tag(item)
                .padding(.vertical, 4)
            }
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
        .background(AppTheme.sidebarBg)
    }

    // MARK: - Detail

    private var detailView: some View {
        VStack(spacing: 0) {
            // Update banner
            if let update = manager.updateAvailable {
                updateBanner(update)
            }

            Group {
                switch selection ?? .downloads {
                case .downloads:
                    DownloadListView()
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .navigationTitle((selection ?? .downloads).rawValue)
        .toolbar {
            if selection == .downloads || selection == nil {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 8) {
                        Button {
                            showAddDownloadSheet = true
                        } label: {
                            Label("Download", systemImage: "arrow.down.circle")
                        }
                        .keyboardShortcut("n", modifiers: .command)
                        .help("Novo download (Cmd+N)")

                        Button {
                            showAddUploadSheet = true
                        } label: {
                            Label("Upload", systemImage: "arrow.up.circle")
                        }
                        .keyboardShortcut("u", modifiers: .command)
                        .help("Novo upload (Cmd+U)")
                    }
                }
            }
        }
    }

    // MARK: - Update Banner

    private func updateBanner(_ update: UpdateInfo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.info)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nova versão disponível: \(update.version)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Versão atual: \(AppSettings.appVersion)")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
            }

            Spacer()

            Button {
                NSWorkspace.shared.open(update.downloadURL)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 11))
                    Text("Atualizar")
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(AppTheme.info))
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation { manager.dismissUpdate() }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.info.opacity(0.1))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Drag & Drop

    private var dropOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)

            VStack(spacing: 16) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.accent)

                Text("Solte o link aqui")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("Link do Google Drive para download")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(AppTheme.accent, style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isDragOver)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: String.self) {
                _ = provider.loadObject(ofClass: String.self) { string, _ in
                    if let text = string, GoogleDriveLinkParser.parse(text) != nil {
                        Task { @MainActor in
                            manager.addDownload(link: text, destinationPath: nil, remoteName: manager.settings.rcloneRemoteName)
                        }
                    }
                }
                return true
            }
        }
        return false
    }

    private func badgeCount(for item: SidebarItem) -> Int {
        switch item {
        case .downloads: return manager.activeDownloads.count
        case .history: return manager.history.count
        case .settings: return 0
        }
    }
}
