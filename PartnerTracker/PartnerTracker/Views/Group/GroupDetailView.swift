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
    let group: Group
    @State private var members: [AppUser] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    @State private var memberToRemove: AppUser? = nil
    @State private var showRemoveAlert = false
    
    @EnvironmentObject var groupViewModel: GroupViewModel
    
    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Lade Mitglieder …")
                    .padding()
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if members.isEmpty {
                Text("Keine Mitglieder gefunden.")
                    .foregroundColor(.gray)
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
                            Button {
                                memberToRemove = member
                                showRemoveAlert = true
                            } label: {
                                Image(systemName: "person.fill.xmark")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .onAppear {
            loadMembers()
        }
        .alert("Mitglied entfernen?", isPresented: $showRemoveAlert) {
            Button("Abbrechen", role: .cancel) {}
            
            if let member = memberToRemove {
                Button("Entfernen", role: .destructive) {
                    Task {
                        do {
                            try await groupViewModel.removeMember(from: group, userId: member.id)
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
                Text("Möchtest du „\(member.name) \(member.surname)“ wirklich aus der Gruppe entfernen?")
            }
        }
    }
    
    private func loadMembers() {
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
    GroupDetailView(group: Group(
        id: "123",
        name: "Testgruppe",
        memberIds: ["uid1", "uid2"],
        createdAt: Date(),
        password: "pw",
        ownerId: "uid1"
    ))
    .environmentObject(GroupViewModel())
}

