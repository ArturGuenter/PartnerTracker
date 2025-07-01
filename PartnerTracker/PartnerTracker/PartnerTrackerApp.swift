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


