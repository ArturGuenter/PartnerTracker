//
//  HomeView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 19.06.25.
//

import SwiftUI


struct HomeView: View {
    @Binding var selection: Int
    @ObservedObject var loginRegisterViewModel: LoginRegisterViewModel
   
    
    var body: some View {
        NavigationStack {
                    VStack {
                        Text("Willkommen, \(loginRegisterViewModel.user?.name ?? "Nutzer")!")
                        
                    }
                    .navigationTitle("Home")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                loginRegisterViewModel.signOut()
                            } label: {
                                Image(systemName: "door.left.hand.open")
                                    .imageScale(.large)
                                    .padding(.trailing, 10)
                            }
                            .accessibilityLabel("Abmelden")
                        }
                    }
                }
        
    }
}


#Preview {
    HomeView(selection: .constant(1), loginRegisterViewModel: LoginRegisterViewModel())
}
