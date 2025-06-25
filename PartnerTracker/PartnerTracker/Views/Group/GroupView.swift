//
//  FamilyView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 19.06.25.
//

import SwiftUI

struct GroupView: View {
    @StateObject var groupViewModel = GroupViewModel()
        @State private var showCreateGroupSheet = false
        @State private var isLoading = true
        @State private var errorMessage = ""

        var body: some View {
            NavigationView {
                VStack {
                    if isLoading {
                        ProgressView("Lade Gruppen …")
                            .padding()
                    } else if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else if groupViewModel.groups.isEmpty {
                        Text("Du bist noch keiner Gruppe beigetreten.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        List(groupViewModel.groups) { group in
                            VStack(alignment: .leading) {
                                Text(group.name)
                                    .font(.headline)
                                if group.createdBy == groupViewModel.currentUserId {
                                    Text("Erstellt von dir")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Meine Gruppen")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCreateGroupSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showCreateGroupSheet) {
                    GroupAdd(groupViewModel: groupViewModel)
                }
                .onAppear {
                    Task {
                        await loadGroups()
                    }
                }
            }
        }

        private func loadGroups() async {
            do {
                try await groupViewModel.fetchGroupsForCurrentUser()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

#Preview {
    GroupView()
}
