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
                        
                        VStack(spacing: 32) {
                            CircularProgressBar(
                                progress: taskViewModel.overallCompletionRate,
                                title: "Alle Aufgaben",
                                completed: taskViewModel.doneTaskCount,
                                total: taskViewModel.totalTaskCount
                            )

                            HStack(spacing: 20) {
                                CircularProgressBar(
                                    progress: taskViewModel.personalCompletionRate,
                                    title: "Eigene",
                                    completed: taskViewModel.donePersonalTaskCount,
                                    total: taskViewModel.personalTasks.count
                                )

                                CircularProgressBar(
                                    progress: taskViewModel.groupCompletionRate,
                                    title: "Gruppe",
                                    completed: taskViewModel.doneGroupTaskCount,
                                    total: taskViewModel.groupedTasks.flatMap { $0.value }.count
                                )
                            }
                        }
                        .padding()


                        

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
