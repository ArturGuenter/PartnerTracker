//
//  FamilyView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 19.06.25.
//

import SwiftUI

struct GroupView: View {
    @ObservedObject var groupViewModel: GroupViewModel

    @State private var showCreateGroupSheet = false
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showAddGroupSheet = false
    @State private var showCopyConfirmation = false
    @State private var groupToDelete: Group? = nil
    @State private var showDeleteAlert = false
    @State private var showSuccessToast = false

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Lade Gruppen …").padding()
                } else if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundColor(.red).padding()
                } else if groupViewModel.groups.isEmpty {
                    Text("Du bist noch keiner Gruppe beigetreten.")
                        .foregroundColor(.secondary).padding()
                } else {
                    List {
                        if !groupViewModel.ownedGroups.isEmpty {
                            Section(header: Text("Eigene Gruppen")) {
                                ForEach(groupViewModel.ownedGroups, id: \.id) { group in
                                    NavigationLink(
                                        destination: GroupDetailView(
                                            groupId: group.id,
                                            groupViewModel: groupViewModel
                                        )
                                    ) {
                                        GroupRowView(
                                            group: group,
                                            showCopyButton: true,
                                            onCopy: {
                                                UIPasteboard.general.string = group.id
                                                withAnimation { showCopyConfirmation = true }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                    withAnimation { showCopyConfirmation = false }
                                                }
                                            }
                                        )
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
                        }

                        if !groupViewModel.joinedGroups.isEmpty {
                            Section(header: Text("Beigetretene Gruppen")) {
                                ForEach(groupViewModel.joinedGroups, id: \.id) { group in
                                    NavigationLink(
                                        destination: GroupDetailView(
                                            groupId: group.id,
                                            groupViewModel: groupViewModel
                                        )
                                    ) {
                                        GroupRowView(group: group, showCopyButton: false, onCopy: nil)
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            groupToDelete = group
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Verlassen", systemImage: "rectangle.portrait.and.arrow.right")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if showCopyConfirmation {
                    Text("Gruppen-ID kopiert!")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1).padding(.top, 8)
                }

                if showSuccessToast {
                    Text("Gruppe erfolgreich erstellt!")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.green.opacity(0.85))
                        .cornerRadius(12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1).padding(.top, 8)
                }
            }
            .navigationTitle("Meine Gruppen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddGroupSheet = true } label: {
                        Image(systemName: "person.3.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreateGroupSheet = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateGroupSheet) {
                GroupCreateView(groupViewModel: groupViewModel, onSuccess: {
                    withAnimation { showSuccessToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showSuccessToast = false }
                    }
                })
            }
            .sheet(isPresented: $showAddGroupSheet) {
                GroupAddView(groupViewModel: groupViewModel)
            }
            .task {
                
                await loadGroups()
                groupViewModel.observeGroupsForCurrentUser()
            }
        }
        .alert(
            groupToDelete?.ownerId == groupViewModel.currentUserId
                ? "Gruppe löschen?"
                : "Gruppe verlassen?",
            isPresented: $showDeleteAlert
        ) {
            Button("Abbrechen", role: .cancel) {}
            if let group = groupToDelete {
                if group.ownerId == groupViewModel.currentUserId {
                    Button("Löschen", role: .destructive) {
                        Task { try? await groupViewModel.deleteGroup(group) }
                    }
                } else {
                    Button("Verlassen", role: .destructive) {
                        Task { try? await groupViewModel.leaveGroup(group) }
                    }
                }
            }
        } message: {
            if let group = groupToDelete {
                if group.ownerId == groupViewModel.currentUserId {
                    Text("""
                    Du bist der Admin dieser Gruppe.
                    Wenn du die Gruppe löschst, wird sie für alle Mitglieder unwiderruflich entfernt.
                    Falls die Gruppe bestehen bleiben soll, übertrage vorher die Adminrechte.
                    """)
                } else {
                    Text("Möchtest du die Gruppe „\(group.name)“ wirklich verlassen? Deine Aufgaben in dieser Gruppe gehen dabei verloren.")
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
    GroupView(groupViewModel: GroupViewModel())
}
