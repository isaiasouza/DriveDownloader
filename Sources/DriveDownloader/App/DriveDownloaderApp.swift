import SwiftUI

@main
struct DriveDownloaderApp: App {
    @StateObject private var downloadManager = DownloadManager()
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView {
                        withAnimation {
                            showOnboarding = false
                        }
                    }
                    .environmentObject(downloadManager)
                } else {
                    ContentView()
                        .environmentObject(downloadManager)
                        .frame(minWidth: 700, minHeight: 450)
                }
            }
            .onAppear {
                showOnboarding = !downloadManager.settings.hasCompletedOnboarding
                downloadManager.checkForUpdatesIfNeeded()
                downloadManager.requestNotificationPermission()
            }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)

        // Menu bar icon
        MenuBarExtra {
            MenuBarView()
                .environmentObject(downloadManager)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: downloadManager.isDownloading ? "arrow.down.circle.fill" : "arrow.down.circle")
                .symbolRenderingMode(.hierarchical)

            if downloadManager.isDownloading {
                Text("\(Int(downloadManager.totalProgress * 100))%")
                    .font(.system(size: 10, design: .monospaced))

                if !downloadManager.activeSpeed.isEmpty {
                    Text(downloadManager.activeSpeed)
                        .font(.system(size: 9, design: .monospaced))
                }
            }
        }
    }
}
