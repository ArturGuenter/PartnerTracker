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
    
    var overallCompletionRate: Double {
        let allTasks = personalTasks + groupedTasks.flatMap { $0.value }
        guard !allTasks.isEmpty else { return 0.0 }
        return Double(allTasks.filter { $0.isDone }.count) / Double(allTasks.count)
    }

    var personalCompletionRate: Double {
        guard !personalTasks.isEmpty else { return 0.0 }
        return Double(personalTasks.filter { $0.isDone }.count) / Double(personalTasks.count)
    }
    
    var groupCompletionRate: Double {
        let groupTasks = groupedTasks.flatMap { $0.value }
        guard !groupTasks.isEmpty else { return 0.0 }
        return Double(groupTasks.filter { $0.isDone }.count) / Double(groupTasks.count)
    }
    
    var doneTaskCount: Int {
        (personalTasks + groupedTasks.flatMap { $0.value }).filter { $0.isDone }.count
    }

    var totalTaskCount: Int {
        personalTasks.count + groupedTasks.flatMap { $0.value }.count
    }

    var donePersonalTaskCount: Int {
        personalTasks.filter { $0.isDone }.count
    }

    var doneGroupTaskCount: Int {
        groupedTasks.flatMap { $0.value }.filter { $0.isDone }.count
    }

    
    
    

    func fetchTasks(groups: [Group]) async throws {
        guard let uid = currentUserId else {
            print("⚠️ Kein eingeloggter Benutzer – fetchTasks abgebrochen.")
            return
        }

        await addDefaultTaskIfNeeded()

        
        let personalSnapshot = try await db.collection("tasks")
            .whereField("ownerId", isEqualTo: uid)
            .whereField("groupId", isEqualTo: NSNull())
            .getDocuments()

        self.personalTasks = try personalSnapshot.documents.compactMap {
            try $0.data(as: TaskItem.self)
        }.sorted(by: { $0.createdAt > $1.createdAt })

        var newGroupedTasks: [String: [TaskItem]] = [:]

        for group in groups {
            let groupSnapshot = try await db.collection("tasks")
                .whereField("groupId", isEqualTo: group.id)
                .getDocuments()

            let groupTasks = try groupSnapshot.documents.compactMap {
                try $0.data(as: TaskItem.self)
            }.sorted(by: { $0.createdAt > $1.createdAt })

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

    func addPersonalTask(title: String, interval:  TaskResetInterval) async {
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
                createdAt: Date(),
                resetInterval: interval,
                lastResetAt: Date()
            )

        do {
            try await db.collection("tasks").document(newTask.id).setData([
                "id": newTask.id,
                "title": newTask.title,
                "isDone": newTask.isDone,
                "ownerId": uid,
                "groupId": NSNull(),
                "createdAt": Timestamp(date: newTask.createdAt),
                "resetInterval": newTask.resetInterval.rawValue,
                "lastResetAt": Timestamp(date: newTask.lastResetAt)
            ])
            try await fetchTasks(groups: [])
        } catch {
            print("Fehler beim Hinzufügen eigener Aufgabe: \(error)")
        }
    }

    func addGroupTask(title: String, group: Group, interval: TaskResetInterval) async {
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
            createdAt: Date(),
            resetInterval: interval,
            lastResetAt: Date()
        )

        do {
            try await db.collection("tasks").document(newTask.id).setData([
                "id": newTask.id,
                "title": newTask.title,
                "isDone": newTask.isDone,
                "ownerId": uid,
                "groupId": group.id,
                "createdAt": Timestamp(date: newTask.createdAt),
                "resetInterval": newTask.resetInterval.rawValue,
                "lastResetAt": Timestamp(date: newTask.lastResetAt)
            ])

            // ✅ Nur diese Gruppe neu laden
            let groupSnapshot = try await db.collection("tasks")
                .whereField("groupId", isEqualTo: group.id)
                .getDocuments()

            let groupTasks = try groupSnapshot.documents.compactMap {
                try $0.data(as: TaskItem.self)
            }.sorted(by: { $0.createdAt > $1.createdAt })

            self.groupedTasks[group.name] = groupTasks

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
    
    
    func deleteTask(_ task: TaskItem) async {
        do {
            try await db.collection("tasks").document(task.id).delete()

            if task.groupId == nil {
                // Persönliche Aufgabe entfernen
                self.personalTasks.removeAll { $0.id == task.id }
            } else {
                // Gruppenaufgabe entfernen
                for (groupName, tasks) in groupedTasks {
                    if tasks.contains(where: { $0.id == task.id }) {
                        groupedTasks[groupName] = tasks.filter { $0.id != task.id }
                        break
                    }
                }
            }

        } catch {
            print("Fehler beim Löschen der Aufgabe: \(error.localizedDescription)")
        }
    }

    
    func updateTaskTitle(task: TaskItem, newTitle: String) async {
        let taskId = task.id

        do {
            try await db.collection("tasks").document(taskId).updateData([
                "title": newTitle
            ])
            
            // Lokale Daten aktualisieren
            if let groupId = task.groupId {
                // Gruppenaufgabe aktualisieren
                if var tasks = groupedTasks[groupId] {
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        tasks[index].title = newTitle
                        groupedTasks[groupId] = tasks
                    }
                }
            } else {
                // Persönliche Aufgabe aktualisieren
                if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
                    personalTasks[index].title = newTitle
                }
            }
        } catch {
            print("Fehler beim Aktualisieren der Aufgabe: \(error.localizedDescription)")
        }
    }


    
}



