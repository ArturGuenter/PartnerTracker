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
    
    var currentUserId: String? {
        auth.currentUser?.uid
    }

    func fetchTasks(groups: [Group]) async throws {
        guard let uid = currentUserId else {
            print("⚠️ Kein eingeloggter Benutzer – fetchTasks abgebrochen.")
            return
        }

        await addDefaultTaskIfNeeded()

        let personalSnapshot = try await db.collection("tasks")
            .whereField("ownerId", isEqualTo: uid)
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
        guard let uid = currentUserId else { return }

        let snapshot = try? await db.collection("tasks")
            .whereField("ownerId", isEqualTo: uid)
            .getDocuments()
        
        guard let snapshot = snapshot, snapshot.isEmpty else {
            return
        }
        
        let defaultTask = TaskItem(
            id: UUID().uuidString,
            title: "App öffnen",
            isDone: false,
            ownerId: uid,
            groupId: nil,
            createdAt: Date()
        )
        
        try? await db.collection("tasks").document(defaultTask.id).setData([
            "id": defaultTask.id,
            "title": defaultTask.title,
            "isDone": defaultTask.isDone,
            "ownerId": uid,
            "groupId": NSNull(),
            "createdAt": Timestamp(date: defaultTask.createdAt)
        ])
    }

    func addPersonalTask(title: String) async {
        guard let uid = currentUserId else {
            print("⚠️ Kein eingeloggter Benutzer – persönliche Aufgabe wird nicht gespeichert.")
            return
        }

        let newTask = TaskItem(
            id: UUID().uuidString,
            title: title,
            isDone: false,
            ownerId: uid,
            groupId: nil,
            createdAt: Date()
        )

        do {
            try await db.collection("tasks").document(newTask.id).setData([
                "id": newTask.id,
                "title": newTask.title,
                "isDone": newTask.isDone,
                "ownerId": uid,
                "groupId": NSNull(),
                "createdAt": Timestamp(date: newTask.createdAt)
            ])
            try await fetchTasks(groups: [])
        } catch {
            print("Fehler beim Hinzufügen eigener Aufgabe: \(error)")
        }
    }

    func addGroupTask(title: String, group: Group) async {
        guard let uid = currentUserId else {
            print("⚠️ Kein eingeloggter Benutzer – Gruppenaufgabe wird nicht gespeichert.")
            return
        }

        let newTask = TaskItem(
            id: UUID().uuidString,
            title: title,
            isDone: false,
            ownerId: uid,
            groupId: group.id,
            createdAt: Date()
        )

        do {
            try await db.collection("tasks").document(newTask.id).setData([
                "id": newTask.id,
                "title": newTask.title,
                "isDone": newTask.isDone,
                "ownerId": uid,
                "groupId": group.id,
                "createdAt": Timestamp(date: newTask.createdAt)
            ])
            try await fetchTasks(groups: [])
        } catch {
            print("Fehler beim Hinzufügen Gruppen-Aufgabe: \(error)")
        }
    }

    func toggleTaskDone(_ task: TaskItem) async {
        let newStatus = !task.isDone

        do {
            try await db.collection("tasks").document(task.id).updateData([
                "isDone": newStatus
            ])

            if task.groupId == nil {
                if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
                    var updatedTask = personalTasks[index]
                    updatedTask.isDone = newStatus
                    personalTasks[index] = updatedTask
                }
            } else {
                for (groupName, tasks) in groupedTasks {
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        var updatedTask = tasks[index]
                        updatedTask.isDone = newStatus
                        var updatedTasks = tasks
                        updatedTasks[index] = updatedTask
                        groupedTasks[groupName] = updatedTasks
                        break
                    }
                }
            }

        } catch {
            print("Fehler beim Umschalten des Aufgabenstatus: \(error)")
        }
    }
}



