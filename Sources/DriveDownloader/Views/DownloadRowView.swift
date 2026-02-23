import SwiftUI

struct DownloadRowView: View {
    @ObservedObject var item: DownloadItem
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void
    let onOpenFinder: () -> Void

    @State private var isHovering = false
    @State private var linkCopied = false
    @State private var showCancelConfirm = false
    @State private var showTransferLog = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 10) {
                // Icon with pulse animation when downloading
                ZStack {
                    Circle()
                        .fill(AppTheme.statusColor(for: item.status).opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: item.transferType == .upload
                        ? "arrow.up.doc.fill"
                        : (item.isFolder ? "folder.fill" : "doc.fill"))
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.statusColor(for: item.status))
                }
                .scaleEffect(item.status == .downloading ? (isHovering ? 1.05 : 1.0) : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: item.status == .downloading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.driveName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)

                    if !item.remoteName.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 9))
                            Text(item.remoteName)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(AppTheme.textMuted)
                    }

                    if !item.currentFileName.isEmpty && item.status == .downloading {
                        Text(item.currentFileName)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                            .lineLimit(1)
                            .transition(.opacity)
                    }

                    if item.retryCount > 0 && !item.status.isFinished {
                        Text("Tentativa \(item.retryCount + 1)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.warning)
                    }
                }

                Spacer()

                statusBadge
            }

            // Progress section
            if item.status == .downloading || item.status == .paused {
                VStack(spacing: 6) {
                    ProgressView(value: item.progress)
                        .progressViewStyle(IrisProgressStyle())

                    HStack(spacing: 0) {
                        Text("\(item.transferredBytesFormatted) / \(item.totalBytesFormatted)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(AppTheme.textSecondary)

                        if !item.speed.isEmpty && item.status == .downloading {
                            Text("  ·  ")
                                .foregroundColor(AppTheme.textMuted)
                            Text(item.speed)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(AppTheme.accent)
                        }

                        if !item.eta.isEmpty && item.status == .downloading {
                            Text("  ·  ")
                                .foregroundColor(AppTheme.textMuted)
                            Text(item.eta)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        if item.totalFiles > 0 {
                            Text("\(item.filesTransferred)/\(item.totalFiles)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(AppTheme.textMuted)
                            Image(systemName: "doc")
                                .font(.system(size: 9))
                                .foregroundColor(AppTheme.textMuted)
                                .padding(.leading, 2)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if item.status == .fetchingInfo {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(AppTheme.accent)
                    Text("Obtendo informações...")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textMuted)
                }
            }

            if let error = item.errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.error)
                    .lineLimit(2)
            }

            // Action buttons
            if !item.status.isFinished {
                HStack(spacing: 12) {
                    if !item.transferLog.isEmpty {
                        actionButton("Log", icon: "doc.text", color: AppTheme.info) {
                            showTransferLog = true
                        }
                    }

                    Spacer()

                    if item.status == .downloading {
                        actionButton("Pausar", icon: "pause.fill", color: AppTheme.warning) {
                            onPause()
                        }
                    }

                    if item.status == .paused {
                        actionButton("Retomar", icon: "play.fill", color: AppTheme.success) {
                            onResume()
                        }
                    }

                    if item.status == .completed {
                        actionButton("Abrir", icon: "folder", color: AppTheme.info) {
                            onOpenFinder()
                        }
                    }

                    if item.status == .downloading || item.status == .paused || item.status == .queued {
                        actionButton("Cancelar", icon: "xmark", color: AppTheme.error) {
                            if item.status == .queued {
                                onCancel()
                            } else {
                                showCancelConfirm = true
                            }
                        }
                    }
                }
            }

            // Share link button for completed uploads
            if item.status == .completed && item.transferType == .upload && item.shareLink != nil {
                HStack(spacing: 12) {
                    Spacer()
                    copyLinkButton
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering ? AppTheme.bgTertiary : AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.cardBorder, lineWidth: 0.5)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .animation(.easeInOut(duration: 0.3), value: item.status)
        .sheet(isPresented: $showTransferLog) {
            TransferLogView(item: item)
        }
        .alert("Cancelar transferência?", isPresented: $showCancelConfirm) {
            Button("Cancelar transferência", role: .destructive) {
                onCancel()
            }
            Button("Voltar", role: .cancel) {}
        } message: {
            Text("O progresso de \"\(item.driveName)\" será perdido.")
        }
    }

    private var copyLinkButton: some View {
        Button {
            if let link = item.shareLink {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(link, forType: .string)
                linkCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    linkCopied = false
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: linkCopied ? "checkmark" : "link")
                    .font(.system(size: 10))
                Text(linkCopied ? "Copiado!" : "Copiar Link")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(linkCopied ? AppTheme.success.opacity(0.12) : AppTheme.accent.opacity(0.12))
            )
            .foregroundColor(linkCopied ? AppTheme.success : AppTheme.accent)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: linkCopied)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: item.status.systemImage(for: item.transferType))
                .font(.system(size: 10))
            Text(item.status.displayName(for: item.transferType))
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(AppTheme.statusColor(for: item.status).opacity(0.15))
        )
        .foregroundColor(AppTheme.statusColor(for: item.status))
    }

    private func actionButton(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
            .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }
}
