//
//  PartnerTrackerApp.swift
//  PartnerTracker
//
//  Created by Artur Günter on 13.06.25.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct PartnerTrackerApp: App {
    @StateObject private var loginRegisterViewModel = LoginRegisterViewModel()
    
    init() {
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
    }

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            if loginRegisterViewModel.isLoading {
                ProgressView("Lade Benutzerdaten…")
            } else if loginRegisterViewModel.isLoggedIn {
                ContentView(loginRegisterViewModel: loginRegisterViewModel)
            } else {
                LoginView(loginRegisterViewModel: loginRegisterViewModel)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        return true
    }

    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

