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
                        /*
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                Text("Willkommen zurück, Artur 👋")
                                    .font(.title)
                                
                                ProgressRingView(completed: 20, total: 50)
                                    .frame(height: 180)

                                VStack(alignment: .leading) {
                                    Text("Heute zu erledigen")
                                        .font(.headline)
                                    ForEach(todayTasks.prefix(3)) { task in
                                        TaskRowView(task: task)
                                    }
                                }

                                MotivationQuoteView()
                                HStack {
                                    Button("➕ Neue Aufgabe") { showNewTaskSheet = true }
                                    Spacer()
                                    Button("📅 Übersicht") { navigateToCalendar() }
                                }
                            }
                            .padding()
                        }

                      */
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
