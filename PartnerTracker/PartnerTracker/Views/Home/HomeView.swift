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
    @ObservedObject var groupViewModel: GroupViewModel
   
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Gesamtaufgaben
                    CircularProgressBar(
                        progress: taskViewModel.overallCompletionRate,
                        title: "Alle Aufgaben",
                        completed: taskViewModel.doneTaskCount,
                        total: taskViewModel.totalTaskCount,
                        size: 200
                    )

                    // Persönlich / Gruppe
                    HStack(spacing: 20) {
                        CircularProgressBar(
                            progress: taskViewModel.personalCompletionRate,
                            title: "Eigene",
                            completed: taskViewModel.donePersonalTaskCount,
                            total: taskViewModel.personalTasks.count,
                            size: 120
                        )

                        CircularProgressBar(
                            progress: taskViewModel.groupCompletionRate,
                            title: "Gruppe",
                            completed: taskViewModel.doneGroupTaskCount,
                            total: taskViewModel.groupedTasks.flatMap { $0.value }.count,
                            size: 120
                        )
                    }

                    
                    ActivityHeatmapView(data: taskViewModel.completionHistory)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.top, 20)

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
                    }
                    .accessibilityLabel("Abmelden")
                }
            }
        }
        .onAppear {
            Task {
                do {
                    try await groupViewModel.fetchGroupsForCurrentUser()
                    try await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                    await taskViewModel.fetchCompletionHistory()
                } catch {
                    print("Fehler beim Laden der Daten: \(error.localizedDescription)")
                }
            }
        }
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

