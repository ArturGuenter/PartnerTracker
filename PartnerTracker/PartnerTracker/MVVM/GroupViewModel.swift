//
//  GroupViewModel.swift
//  PartnerTracker
//
//  Created by Artur Günter on 24.06.25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class GroupViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var userCache: [String: AppUser] = [:]

    private let db = Firestore.firestore()

    var currentUserId: String {
        guard let uid = Auth.auth().currentUser?.uid else {
            fatalError("Kein eingeloggter Benutzer")
        }
        return uid
    }

    // Gruppe erstellen
    func createGroup(name: String, password: String) async throws {
        let newGroupRef = db.collection("groups").document()

        let group = Group(
            id: newGroupRef.documentID,
            name: name,
            memberIds: [currentUserId],
            createdAt: nil,
            password: password
        )

        var groupData = try Firestore.Encoder().encode(group)
        groupData["createdAt"] = FieldValue.serverTimestamp()

        try await newGroupRef.setData(groupData)

        try await fetchGroupsForCurrentUser()
    }

    // Gruppen + Userdaten laden
    func fetchGroupsForCurrentUser() async throws {
        let snapshot = try await db.collection("groups")
            .whereField("memberIds", arrayContains: currentUserId)
            .getDocuments()

        var fetchedGroups: [Group] = try snapshot.documents.compactMap { doc in
            try doc.data(as: Group.self)
        }

        fetchedGroups.sort { (group1, group2) in
            let date1 = group1.createdAt ?? Date.distantPast
            let date2 = group2.createdAt ?? Date.distantPast
            return date1 > date2 // Neueste zuerst
        }

        self.groups = fetchedGroups

        
        try await preloadGroupUsers(groups: fetchedGroups)
    }

    // In Gruppe beitreten
    func joinGroup(groupId: String, password: String) async throws {
        let groupRef = db.collection("groups").document(groupId)
        let snapshot = try await groupRef.getDocument()

        guard let data = snapshot.data(),
              let storedPassword = data["password"] as? String else {
            throw NSError(domain: "Group", code: 404, userInfo: [NSLocalizedDescriptionKey: "Gruppe nicht gefunden."])
        }

        guard storedPassword == password else {
            throw NSError(domain: "Group", code: 403, userInfo: [NSLocalizedDescriptionKey: "Falsches Passwort."])
        }

        try await groupRef.updateData([
            "memberIds": FieldValue.arrayUnion([currentUserId])
        ])

        try await fetchGroupsForCurrentUser()
    }

    // MARK: - User Cache Handling

    private func preloadGroupUsers(groups: [Group]) async throws {
        for group in groups {
            for memberId in group.memberIds {
                if userCache[memberId] == nil {
                    let user = try await fetchUser(with: memberId)
                    userCache[memberId] = user
                }
            }
        }
    }

    private func fetchUser(with id: String) async throws -> AppUser {
        let doc = try await db.collection("users").document(id).getDocument()
        guard let user = try? doc.data(as: AppUser.self) else {
            throw NSError(domain: "User", code: 404, userInfo: [NSLocalizedDescriptionKey: "User nicht gefunden."])
        }
        return user
    }
}

