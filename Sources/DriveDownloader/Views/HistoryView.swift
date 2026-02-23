import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var manager: DownloadManager
    @State private var copiedItemId: UUID? = nil
    @State private var searchText: String = ""
    @State private var statusFilter: HistoryFilter = .all
    @State private var logItem: DownloadItem? = nil

    enum HistoryFilter: String, CaseIterable {
        case all = "Todos"
        case completed = "Concluídos"
        case failed = "Falhos"
        case downloads = "Downloads"
        case uploads = "Uploads"
    }

    private var filteredHistory: [DownloadItem] {
        manager.history.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.driveName.localizedCaseInsensitiveContains(searchText) ||
                item.remoteName.localizedCaseInsensitiveContains(searchText)

            let matchesFilter: Bool
            switch statusFilter {
            case .all: matchesFilter = true
            case .completed: matchesFilter = item.status == .completed
            case .failed: matchesFilter = item.status == .failed || item.status == .cancelled
            case .downloads: matchesFilter = item.transferType == .download
            case .uploads: matchesFilter = item.transferType == .upload
            }

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        Group {
            if manager.history.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    // Toolbar
                    VStack(spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textMuted)
                                TextField("Buscar...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12))
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.bgTertiary)
                            )

                            Button(action: { manager.clearHistory() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                    Text("Limpar")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(AppTheme.error)
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 6) {
                            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        statusFilter = filter
                                    }
                                } label: {
                                    Text(filter.rawValue)
                                        .font(.system(size: 10, weight: statusFilter == filter ? .bold : .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule().fill(statusFilter == filter ? AppTheme.accent.opacity(0.15) : AppTheme.bgTertiary)
                                        )
                                        .foregroundColor(statusFilter == filter ? AppTheme.accent : AppTheme.textMuted)
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            Text("\(filteredHistory.count) de \(manager.history.count)")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider()
                        .background(AppTheme.cardBorder)

                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(filteredHistory) { item in
                                historyRow(item)
                                    .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                        }
                        .padding(16)
                    }
                    .animation(.spring(response: 0.3), value: filteredHistory.count)
                }
            }
        }
        .background(AppTheme.bgPrimary)
        .sheet(item: $logItem) { item in
            TransferLogView(item: item)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.textMuted.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "clock")
                    .font(.system(size: 36))
                    .foregroundColor(AppTheme.textMuted)
            }
            Text("Sem histórico")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Text("Downloads concluídos aparecerão aqui")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.bgPrimary)
    }

    private func historyRow(_ item: DownloadItem) -> some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(AppTheme.statusColor(for: item.status).opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: item.status.systemImage(for: item.transferType))
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.statusColor(for: item.status))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.driveName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if item.transferType == .upload {
                        Text("Upload")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.success)
                    }

                    if !item.remoteName.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 9))
                            Text(item.remoteName)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(AppTheme.textMuted)
                    }

                    Text(item.totalBytesFormatted)
                        .font(.system(size: 11, design: .monospaced))

                    if let date = item.dateCompleted {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11))
                    }
                }
                .foregroundColor(AppTheme.textMuted)

                if let error = item.errorMessage {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.error)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                if !item.transferLog.isEmpty {
                    Button {
                        logItem = item
                    } label: {
                        Image(systemName: "doc.text")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.info)
                    }
                    .buttonStyle(.plain)
                    .help("Ver log")
                }

                if item.status == .completed && item.transferType == .upload,
                   let link = item.shareLink {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(link, forType: .string)
                        copiedItemId = item.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if copiedItemId == item.id {
                                copiedItemId = nil
                            }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: copiedItemId == item.id ? "checkmark" : "link")
                                .font(.system(size: 11))
                            Text(copiedItemId == item.id ? "Copiado!" : "Copiar Link")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(copiedItemId == item.id ? AppTheme.success : AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .help("Copiar link de compartilhamento")
                }

                if item.status == .completed {
                    Button {
                        manager.openInFinder(item)
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .help("Abrir no Finder")
                }

                if item.status == .failed || item.status == .cancelled {
                    Button {
                        manager.retryDownload(item)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.warning)
                    }
                    .buttonStyle(.plain)
                    .help("Tentar novamente")
                }

                Button {
                    manager.removeFromHistory(item)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted)
                }
                .buttonStyle(.plain)
                .help("Remover")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 0.5)
                )
        )
    }
}
