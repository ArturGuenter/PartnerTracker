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
    
    private let db = Firestore.firestore()

    var currentUserId: String {
        guard let uid = Auth.auth().currentUser?.uid else {
            fatalError("Kein eingeloggter Benutzer")
        }
        return uid
    }

    func createGroup(name: String, password: String) async throws {
        let newGroupRef = db.collection("groups").document()
        
        let group = Group(
            id: newGroupRef.documentID,
            name: name,
            memberIds: [currentUserId],
            createdAt: nil,
            password: password // neu
        )
        
        var groupData = try Firestore.Encoder().encode(group)
        groupData["createdAt"] = FieldValue.serverTimestamp()

        try await newGroupRef.setData(groupData)
    }


    func fetchGroupsForCurrentUser() async throws {
        let snapshot = try await db.collection("groups")
            .whereField("memberIds", arrayContains: currentUserId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        let fetchedGroups: [Group] = try snapshot.documents.compactMap { doc in
            try doc.data(as: Group.self)
        }

        self.groups = fetchedGroups
    }
}
