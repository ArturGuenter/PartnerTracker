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
    @ObservedObject var taskViewModel: TaskViewModel
   
    
    var body: some View {
        NavigationStack {
            
                    VStack {
                        
                        VStack {
                            ProgressView(value: taskViewModel.overallCompletionRate)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(2.0)
                            Text("Gesamter Fortschritt: \(Int(taskViewModel.overallCompletionRate * 100))%")
                                .font(.headline)
                        }
                        

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
    HomeView(selection: .constant(1), loginRegisterViewModel: LoginRegisterViewModel(), taskViewModel: TaskViewModel())
}
