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
    @State private var showAddGroupSheet = false

        var body: some View {
            NavigationStack {
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
                        List(groupViewModel.groups, id: \.id) { group in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.name)
                                    .font(.headline)
                                
                                if let createdAt = group.createdAt {
                                    Text("Erstellt am \(createdAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle("Meine Gruppen")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddGroupSheet = true
                        } label: {
                            Image(systemName: "person.3.fill")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCreateGroupSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }

                .sheet(isPresented: $showCreateGroupSheet) {
                    GroupCreateView(groupViewModel: groupViewModel)
                }
                .sheet(isPresented: $showAddGroupSheet) {
                    GroupAddView(groupViewModel: groupViewModel)
                }
                .onAppear {
                    #if DEBUG
                    // Verhindert Aufruf im Preview
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                        return
                    }
                    #endif

                    Task {
                        await loadGroups()
                    }
                }

            }
        }

        private func loadGroups() async {
            do {
                try await groupViewModel.fetchGroupsForCurrentUser()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

#Preview {
    GroupView()
}
