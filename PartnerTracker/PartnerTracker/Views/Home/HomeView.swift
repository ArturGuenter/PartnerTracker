//
//  HomeView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 19.06.25.
//

import SwiftUI


import SwiftUI

struct HomeView: View {
    @Binding var selection: Int
    @ObservedObject var loginRegisterViewModel: LoginRegisterViewModel
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var groupViewModel: GroupViewModel
   
    var body: some View {
        NavigationStack {
            ZStack {
                
                LinearGradient(
                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        
                        CircularProgressBar(
                            progress: taskViewModel.overallCompletionRate,
                            title: "Alle Aufgaben",
                            completed: taskViewModel.doneTaskCount,
                            total: taskViewModel.totalTaskCount,
                            size: 200,
                            progressColor: .blue    
                        )

                        .cardStyle()
                        
                        
                        HStack(spacing: 16) {
                            CircularProgressBar(
                                progress: taskViewModel.personalCompletionRate,
                                title: "Eigene",
                                completed: taskViewModel.donePersonalTaskCount,
                                total: taskViewModel.personalTasks.count,
                                size: 120,
                                progressColor: .green
                            )
                            .cardStyle()
                            
                            CircularProgressBar(
                                progress: taskViewModel.groupCompletionRate,
                                title: "Gruppe",
                                completed: taskViewModel.doneGroupTaskCount,
                                total: taskViewModel.groupedTasks.flatMap { $0.value }.count,
                                size: 120,
                                progressColor: .orange
                            )
                            .cardStyle()
                        }
                        
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Aktivität")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ActivityHeatmapView(data: taskViewModel.completionHistory)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .cardStyle()
                    }
                    .padding()
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
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Abmelden")
                }
            }
        }
        .onAppear {
            Task {
                do {
                    try await groupViewModel.fetchGroupsForCurrentUser()
                    taskViewModel.listenToTasks(groups: groupViewModel.groups)
                    await taskViewModel.fetchCompletionHistory()
                } catch {
                    print("Fehler beim Laden der Daten: \(error.localizedDescription)")
                }
            }
        }
    }
}


extension View {
    func cardStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thinMaterial)
            .cornerRadius(16)
            .shadow(radius: 5, x: 0, y: 3)
    }
}

#Preview {
    HomeView(
        selection: .constant(1),
        loginRegisterViewModel: LoginRegisterViewModel(),
        taskViewModel: TaskViewModel(),
        groupViewModel: GroupViewModel()
    )
}

