import SwiftUI

enum AppTheme {
    // IRIS Media brand colors
    static let accent = Color(red: 0.49, green: 0.23, blue: 0.93)       // Purple
    static let accentLight = Color(red: 0.62, green: 0.40, blue: 0.98)  // Light purple
    static let accentDark = Color(red: 0.30, green: 0.11, blue: 0.58)   // Dark purple

    static let bgPrimary = Color(red: 0.09, green: 0.09, blue: 0.11)    // Near black
    static let bgSecondary = Color(red: 0.13, green: 0.13, blue: 0.16)  // Dark gray
    static let bgTertiary = Color(red: 0.17, green: 0.17, blue: 0.21)   // Medium gray

    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.65)
    static let textMuted = Color(white: 0.45)

    static let success = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let warning = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let error = Color(red: 0.95, green: 0.26, blue: 0.21)
    static let info = Color(red: 0.25, green: 0.56, blue: 0.97)

    static let cardBackground = Color(red: 0.14, green: 0.14, blue: 0.18)
    static let cardBorder = Color(white: 0.2)

    static let sidebarBg = Color(red: 0.11, green: 0.11, blue: 0.14)

    static let progressGradient = LinearGradient(
        colors: [accent, accentLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func statusColor(for status: DownloadStatus) -> Color {
        switch status {
        case .queued, .fetchingInfo: return textMuted
        case .downloading: return accent
        case .paused: return warning
        case .completed: return success
        case .failed: return error
        case .cancelled: return textMuted
        }
    }
}

// Custom progress bar style
struct IrisProgressStyle: ProgressViewStyle {
    var height: CGFloat = 8

    func makeBody(configuration: Configuration) -> some View {
        let fraction = configuration.fractionCompleted ?? 0

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(AppTheme.bgTertiary)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(AppTheme.progressGradient)
                    .frame(width: max(geo.size.width * fraction, 0), height: height)
                    .animation(.easeInOut(duration: 0.3), value: fraction)
            }
        }
        .frame(height: height)
    }
}
