//
//  PartnerTrackerApp.swift
//  PartnerTracker
//
//  Created by Artur Günter on 13.06.25.
//

import SwiftUI
import Firebase

@main
struct PartnerTrackerApp: App {
    @StateObject private var loginRegisterViewModel = LoginRegisterViewModel()
    @State private var selection = 1
    
    init(){
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()
    }
    var body: some Scene {
        
            WindowGroup {
                        if loginRegisterViewModel.isLoggedIn {
                            HomeView(selection: $selection)
                                
                        } else {
                            LoginView(loginRegisterViewModel: loginRegisterViewModel)
                                
                        }
                    }
          
    }
}
