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
    
    
    func addDefaultTaskIfNeeded() async {
        let snapshot = try? await db.collection("tasks")
            .whereField("ownerId", isEqualTo: currentUserId)
            .getDocuments()

        if let count = snapshot?.count, count == 0 {
            let defaultTask = TaskItem(
                id: UUID().uuidString,
                title: "App öffnen",
                isDone: false,
                ownerId: currentUserId,
                groupId: nil,
                createdAt: Date()
            )

            try? db.collection("tasks").document(defaultTask.id).setData([
                "id": defaultTask.id,
                "title": defaultTask.title,
                "isDone": defaultTask.isDone,
                "ownerId": defaultTask.ownerId,
                "groupId": NSNull(), 
                "createdAt": Timestamp(date: defaultTask.createdAt)
            ])
        }
    }

}


