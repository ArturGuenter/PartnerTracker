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
     
        await addDefaultTaskIfNeeded()
        
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

        guard let snapshot = snapshot, snapshot.isEmpty else {
            return 
        }

        let defaultTask = TaskItem(
            id: UUID().uuidString,
            title: "App öffnen",
            isDone: false,
            ownerId: currentUserId,
            groupId: nil,
            createdAt: Date()
        )

        try? await db.collection("tasks").document(defaultTask.id).setData([
            "id": defaultTask.id,
            "title": defaultTask.title,
            "isDone": defaultTask.isDone,
            "ownerId": defaultTask.ownerId,
            "groupId": NSNull(),
            "createdAt": Timestamp(date: defaultTask.createdAt)
        ])
    }

    func addPersonalTask(title: String) async {
        let newTask = TaskItem(
            id: UUID().uuidString,
            title: title,
            isDone: false,
            ownerId: currentUserId,
            groupId: nil,
            createdAt: Date()
        )

        do {
            try await db.collection("tasks").document(newTask.id).setData([
                "id": newTask.id,
                "title": newTask.title,
                "isDone": newTask.isDone,
                "ownerId": newTask.ownerId,
                "groupId": NSNull(),
                "createdAt": Timestamp(date: newTask.createdAt)
            ])
            try await fetchTasks(groups: [])
        } catch {
            print("Fehler beim Hinzufügen eigener Aufgabe: \(error)")
        }
    }
}


