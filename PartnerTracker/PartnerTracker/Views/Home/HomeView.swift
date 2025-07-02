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
        VStack(spacing: 24) {
            Text("Willkommen, \(loginRegisterViewModel.user?.name ?? "Benutzer")!")
                .font(.title2)
            
            Button(role: .destructive) {
                loginRegisterViewModel.signOut()
            } label: {
                Text("Abmelden")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
    }
}


#Preview {
    HomeView(selection: .constant(1), loginRegisterViewModel: LoginRegisterViewModel())
}
