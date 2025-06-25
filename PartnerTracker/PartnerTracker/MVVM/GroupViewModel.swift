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

        
        func createGroup(name: String) async throws {
            let newGroupRef = db.collection("groups").document()

            let groupData: [String: Any] = [
                "id": newGroupRef.documentID,
                "name": name,
                "memberIds": [currentUserId],
                "createdAt": FieldValue.serverTimestamp()

            ]

            try await newGroupRef.setData(groupData)
        }

        
        func fetchGroupsForCurrentUser() async throws {
            let snapshot = try await db.collection("groups")
                .whereField("membersIds", arrayContains: currentUserId)
                .getDocuments()

            let fetchedGroups: [Group] = try snapshot.documents.compactMap { doc in
                try doc.data(as: Group.self)
            }

            self.groups = fetchedGroups
        }
    }
