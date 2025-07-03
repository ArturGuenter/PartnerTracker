//
//  TaskViewModel.swift
//  PartnerTracker
//
//  Created by Artur Günter on 24.06.25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class TaskViewModel: ObservableObject {
    @Published var personalTasks: [TaskItem] = []
    @Published var groupedTasks: [String: [TaskItem]] = [:]
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    var currentUserId: String {
        auth.currentUser?.uid ?? ""
    }

    func fetchTasks(groups: [Group]) async throws {
     
        let personalSnapshot = try await db.collection("tasks")
            .whereField("ownerId", isEqualTo: currentUserId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        self.personalTasks = try personalSnapshot.documents.compactMap {
            try $0.data(as: TaskItem.self)
        }

      
        var newGroupedTasks: [String: [TaskItem]] = [:]
        
        for group in groups {
            let groupSnapshot = try await db.collection("tasks")
                .whereField("groupId", isEqualTo: group.id)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let groupTasks = try groupSnapshot.documents.compactMap {
                try $0.data(as: TaskItem.self)
            }
            
            if !groupTasks.isEmpty {
                newGroupedTasks[group.name] = groupTasks
            }
        }

       
        self.groupedTasks = newGroupedTasks
    }
}


