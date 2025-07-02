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
        HStack{
                        Spacer()
            Button{
                loginRegisterViewModel.signOut()
            } label: {
                            Image(systemName: "door.left.hand.open")
                                .padding(.trailing, 20)
                        }
                        
                    }
        VStack(spacing: 24) {
            Text("Willkommen, \(loginRegisterViewModel.user?.name ?? "Benutzer")!")
                .font(.title2)
            
            
        }
        .padding()
    }
}


#Preview {
    HomeView(selection: .constant(1), loginRegisterViewModel: LoginRegisterViewModel())
}
