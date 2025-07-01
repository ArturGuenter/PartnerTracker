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
    
    
    init(){
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
        try? Auth.auth().signOut()
    }
    var body: some Scene {
        
            WindowGroup {
                if loginRegisterViewModel.isLoggedIn {
                    ContentView(loginRegisterViewModel: loginRegisterViewModel)
                } else {
                    LoginView(loginRegisterViewModel: loginRegisterViewModel)
                }

                    }
          
    }
}
user bleibt eingeloggt obwohl app gelöscht, nun hat es gekalppt mit beim app satrt alle ausloggen was nicht gut ist 
