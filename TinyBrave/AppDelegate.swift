import FirebaseMessaging
import UIKit
import UserNotifications

/// Starts Firebase before any view asks for circles, and passes the push token on to `CircleService`.
final class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if FirebaseSetup.configure(), !ProcessInfo.processInfo.arguments.contains("-firebaseEmulator") {
            Messaging.messaging().delegate = self
            UNUserNotificationCenter.current().delegate = self
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task { @MainActor in CircleService.shared.setDeviceToken(fcmToken) }
    }

    /// While the app is open the in-app banner already shows a friend's brave, so skip the system one.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.badge]
    }
}

enum PushSetup {
    /// Asks once circles are on, so solo users never see a notification prompt.
    @MainActor
    static func requestPermission() {
        guard FirebaseSetup.isConfigured, !ProcessInfo.processInfo.arguments.contains("-firebaseEmulator") else { return }
        Task {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted { UIApplication.shared.registerForRemoteNotifications() }
        }
    }
}
