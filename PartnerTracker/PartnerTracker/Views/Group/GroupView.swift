//
//  FamilyView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 19.06.25.
//

import SwiftUI

struct GroupView: View {
    @ObservedObject var groupViewModel : GroupViewModel
        @State private var showCreateGroupSheet = false
        @State private var isLoading = true
        @State private var errorMessage = ""
    @State private var showAddGroupSheet = false
    @State private var showCopyConfirmation = false
    @State private var groupToDelete: Group? = nil
    @State private var showDeleteAlert = false

    
    

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
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(group.name)
                                        .font(.headline)
                                    
                                    if let createdAt = group.createdAt {
                                        Text("Erstellt am \(createdAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    HStack {
                                        Text("ID: \(group.id)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            UIPasteboard.general.string = group.id
                                            withAnimation {
                                                showCopyConfirmation = true
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                withAnimation {
                                                    showCopyConfirmation = false
                                                }
                                            }
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundColor(.blue)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .swipeActions {
                                    Button(role: .destructive) {
                                        groupToDelete = group
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                            
                        
                        }
                        
                        

                    }
                    
                    if showCopyConfirmation {
                        Text("Gruppen-ID kopiert!")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                            .padding(.top, 8)
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
            .alert("Gruppe löschen?", isPresented: $showDeleteAlert) {
                Button("Abbrechen", role: .cancel) {}
                if let group = groupToDelete {
                    Button("Löschen", role: .destructive) {
                        Task {
                            try? await groupViewModel.deleteGroup(group)
                        }
                    }
                }
            } message: {
                if let group = groupToDelete {
                    Text("Möchtest du die Gruppe „\(group.name)“ wirklich löschen? Alle Aufgaben in dieser Gruppe werden ebenfalls entfernt.")
                }
            }

            .onAppear {
                
                     groupViewModel.observeGroupsForCurrentUser()
                
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
    GroupView(groupViewModel: GroupViewModel())
}
