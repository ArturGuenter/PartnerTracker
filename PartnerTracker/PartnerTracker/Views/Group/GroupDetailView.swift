//
//  GroupDetailView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 30.06.25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct GroupDetailView: View {
    let groupId: String
    @ObservedObject var groupViewModel: GroupViewModel
    
    @State private var members: [AppUser] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    @State private var memberToRemove: AppUser? = nil
    @State private var showRemoveAlert = false
    
    @State private var memberToPromote: AppUser? = nil
    @State private var showPromoteAlert = false
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    private var group: Group? {
        groupViewModel.groups.first(where: { $0.id == groupId })
    }
    
    var body: some View {
            VStack {
                if let group = group {
                    if isLoading {
                        ProgressView("Lade Mitglieder …").padding()
                    } else if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(.red)
                    } else if members.isEmpty {
                        Text("Keine Mitglieder gefunden.").foregroundColor(.gray)
                    } else {
                        List(members) { member in
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("\(member.name) \(member.surname)")
                                            .font(.headline)
                                        
                                        if member.id == group.ownerId {
                                            Text("Admin")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.15))
                                                .cornerRadius(6)
                                        }
                                    }
                                    Text(member.email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if currentUserId == group.ownerId && member.id != group.ownerId {
                                    MemberActionButtons(
                                        member: member,
                                        onPromote: {
                                            memberToPromote = member
                                            showPromoteAlert = true
                                        },
                                        onRemove: {
                                            memberToRemove = member
                                            showRemoveAlert = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                } else {
                    Text("Gruppe nicht gefunden")
                }
            }
            .navigationTitle(group?.name ?? "Gruppe")
            .onAppear {
                groupViewModel.observeGroupsForCurrentUser()
                loadMembers()
            }
        
        // Mitglied entfernen
        .alert("Mitglied entfernen?", isPresented: $showRemoveAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Entfernen", role: .destructive) {
                Task {
                    if let member = memberToRemove {
                        do {
                            try await groupViewModel.removeMember(groupId: groupId, userId: member.id)
                            await MainActor.run {
                                members.removeAll { $0.id == member.id }
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        } message: {
            if let member = memberToRemove {
                Text("Möchtest du „\(member.name) \(member.surname)“ wirklich entfernen?")
            }
        }

        
        // Adminrechte übertragen
        .alert("Adminrechte übertragen?", isPresented: $showPromoteAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Übertragen", role: .destructive) {
                Task {
                    if let member = memberToPromote {
                        do {
                            try await groupViewModel.transferAdminRights(groupId: groupId, newOwnerId: member.id)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        } message: {
            if let member = memberToPromote {
                Text("Möchtest du die Adminrechte an „\(member.name) \(member.surname)“ übertragen? Danach bist du kein Admin mehr.")
            }
        }

    }
    
    private func loadMembers() {
        guard let group = group else { return }
        
        let db = Firestore.firestore()
        let memberIds = group.memberIds
        guard !memberIds.isEmpty else {
            self.isLoading = false
            return
        }
        
        var fetchedUsers: [AppUser] = []
        let groupDispatch = DispatchGroup()
        
        for id in memberIds {
            groupDispatch.enter()
            db.collection("users").document(id).getDocument { snapshot, error in
                defer { groupDispatch.leave() }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                if let user = try? snapshot?.data(as: AppUser.self) {
                    fetchedUsers.append(user)
                }
            }
        }
        
        groupDispatch.notify(queue: .main) {
            self.members = fetchedUsers.sorted { $0.name < $1.name }
            self.isLoading = false
        }
    }
}


#Preview {
    GroupDetailView(groupId: "123", groupViewModel: GroupViewModel())
}

