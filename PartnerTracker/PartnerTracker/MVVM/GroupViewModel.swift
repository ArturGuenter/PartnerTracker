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
        private var userID: String {
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
                "membersIds": [userID],
                
            ]

            try await newGroupRef.setData(groupData)
        }
}
