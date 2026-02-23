import Foundation

struct AppSettings: Codable {
    var defaultDestination: String
    var maxConcurrentDownloads: Int
    var rclonePath: String
    var rcloneRemoteName: String
    var showNotifications: Bool
    var bandwidthLimit: String  // e.g. "0" (unlimited), "10M", "50M"
    var hasCompletedOnboarding: Bool
    var availableRemotes: [String]
    var lastUpdateCheck: Date?
    var autoRetryEnabled: Bool
    var maxRetries: Int

    static let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2"

    init(
        defaultDestination: String,
        maxConcurrentDownloads: Int,
        rclonePath: String,
        rcloneRemoteName: String,
        showNotifications: Bool,
        bandwidthLimit: String,
        hasCompletedOnboarding: Bool,
        availableRemotes: [String],
        lastUpdateCheck: Date? = nil,
        autoRetryEnabled: Bool = true,
        maxRetries: Int = 3
    ) {
        self.defaultDestination = defaultDestination
        self.maxConcurrentDownloads = maxConcurrentDownloads
        self.rclonePath = rclonePath
        self.rcloneRemoteName = rcloneRemoteName
        self.showNotifications = showNotifications
        self.bandwidthLimit = bandwidthLimit
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.availableRemotes = availableRemotes
        self.lastUpdateCheck = lastUpdateCheck
        self.autoRetryEnabled = autoRetryEnabled
        self.maxRetries = maxRetries
    }

    // Custom decoding for backward compatibility with v1.1 settings
    enum CodingKeys: String, CodingKey {
        case defaultDestination, maxConcurrentDownloads, rclonePath, rcloneRemoteName
        case showNotifications, bandwidthLimit, hasCompletedOnboarding, availableRemotes
        case lastUpdateCheck, autoRetryEnabled, maxRetries
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        defaultDestination = try c.decode(String.self, forKey: .defaultDestination)
        maxConcurrentDownloads = try c.decode(Int.self, forKey: .maxConcurrentDownloads)
        rclonePath = try c.decode(String.self, forKey: .rclonePath)
        rcloneRemoteName = try c.decode(String.self, forKey: .rcloneRemoteName)
        showNotifications = try c.decode(Bool.self, forKey: .showNotifications)
        bandwidthLimit = try c.decode(String.self, forKey: .bandwidthLimit)
        hasCompletedOnboarding = try c.decode(Bool.self, forKey: .hasCompletedOnboarding)
        availableRemotes = try c.decode([String].self, forKey: .availableRemotes)
        lastUpdateCheck = try c.decodeIfPresent(Date.self, forKey: .lastUpdateCheck)
        autoRetryEnabled = try c.decodeIfPresent(Bool.self, forKey: .autoRetryEnabled) ?? true
        maxRetries = try c.decodeIfPresent(Int.self, forKey: .maxRetries) ?? 3
    }

    static let `default` = AppSettings(
        defaultDestination: NSHomeDirectory() + "/Downloads",
        maxConcurrentDownloads: 2,
        rclonePath: "/opt/homebrew/bin/rclone",
        rcloneRemoteName: "gdrive",
        showNotifications: true,
        bandwidthLimit: "0",
        hasCompletedOnboarding: false,
        availableRemotes: [],
        lastUpdateCheck: nil,
        autoRetryEnabled: true,
        maxRetries: 3
    )
}
