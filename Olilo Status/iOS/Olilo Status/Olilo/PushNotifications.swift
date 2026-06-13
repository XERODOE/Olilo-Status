import Foundation
import UIKit
import UserNotifications

struct PushNotificationPreferences: Codable, Equatable {
    var isEnabled = false
    var selectedComponentIDs: Set<String> = []

    static let storageKey = "pushNotificationPreferences"

    static func load() -> PushNotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return PushNotificationPreferences()
        }
        return (try? JSONDecoder().decode(PushNotificationPreferences.self, from: data)) ?? PushNotificationPreferences()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    func isComponentSelected(_ component: StatusComponent) -> Bool {
        selectedComponentIDs.contains(component.id)
    }

    mutating func setComponent(_ component: StatusComponent, isSelected: Bool) {
        if isSelected {
            selectedComponentIDs.insert(component.id)
        } else {
            selectedComponentIDs.remove(component.id)
        }
    }

    mutating func selectAllComponents(_ components: [StatusComponent]) {
        selectedComponentIDs = Set(components.map(\.id))
    }
}

struct PushNotificationSubscription: Encodable {
    let deviceToken: String
    let bundleIdentifier: String
    let environment: String
    let isEnabled: Bool
    let componentIDs: [String]
}

//    WIP: DO NOT MERGE!
//    We need to point to a real backend service, register Olilo Status APNS with ASC
//    and update the configuration here.

struct PushNotificationAPI {
    private let subscriptionURL = URL(string: "https://status.olilo.co.uk")!

    func syncSubscription(token: String, preferences: PushNotificationPreferences) async throws {
        let payload = PushNotificationSubscription(
            deviceToken: token,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
            environment: Self.apnsEnvironment,
            isEnabled: preferences.isEnabled,
            componentIDs: preferences.isEnabled ? preferences.selectedComponentIDs.sorted() : []
        )

        var request = URLRequest(url: subscriptionURL)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private static var apnsEnvironment: String {
        #if DEBUG
        "sandbox"
        #else
        "production"
        #endif
    }
}

@MainActor
final class PushNotificationManager {
    static let shared = PushNotificationManager()

    private let api = PushNotificationAPI()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let tokenStorageKey = "pushNotificationDeviceToken"

    private init() {}

    var deviceToken: String? {
        UserDefaults.standard.string(forKey: tokenStorageKey)
    }

    func configure(delegate: UNUserNotificationCenterDelegate) {
        notificationCenter.delegate = delegate
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationCenter.notificationSettings().authorizationStatus
    }

    func enableNotifications(with preferences: PushNotificationPreferences) async throws {
        let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
        guard granted else { throw PushNotificationError.permissionDenied }
        UIApplication.shared.registerForRemoteNotifications()
        try await syncSubscription(preferences: preferences)
    }

    func disableNotifications(with preferences: PushNotificationPreferences) async {
        UIApplication.shared.unregisterForRemoteNotifications()
        guard let token = deviceToken else { return }
        try? await api.syncSubscription(token: token, preferences: preferences)
    }

    func storeDeviceToken(_ tokenData: Data) async {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: tokenStorageKey)
        let preferences = PushNotificationPreferences.load()
        guard preferences.isEnabled else { return }
        try? await api.syncSubscription(token: token, preferences: preferences)
    }

    func syncSubscription(preferences: PushNotificationPreferences) async throws {
        guard preferences.isEnabled else {
            await disableNotifications(with: preferences)
            return
        }

        if let token = deviceToken {
            try await api.syncSubscription(token: token, preferences: preferences)
        } else {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

enum PushNotificationError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission was not granted."
        }
    }
}

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        PushNotificationManager.shared.configure(delegate: self)
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { await PushNotificationManager.shared.storeDeviceToken(deviceToken) }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
