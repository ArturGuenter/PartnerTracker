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
    
    // MARK: - Statistiken

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

    // MARK: - Aufgaben laden

    func fetchTasks(groups: [Group]) async throws {
        guard let uid = currentUserId else { return }

        await addDefaultTaskIfNeeded()

        let personalSnapshot = try await db.collection("tasks")
            .whereField("ownerId", isEqualTo: uid)
            .whereField("groupId", isEqualTo: NSNull())
            .getDocuments()

        self.personalTasks = personalSnapshot.documents.compactMap {
            try? $0.data(as: TaskItem.self)
        }.sorted(by: { $0.createdAt > $1.createdAt })

        var newGroupedTasks: [String: [TaskItem]] = [:]

        for group in groups {
            let groupSnapshot = try await db.collection("tasks")
                .whereField("groupId", isEqualTo: group.id)
                .getDocuments()

            let groupTasks = groupSnapshot.documents.compactMap {
                try? $0.data(as: TaskItem.self)
            }.sorted(by: { $0.createdAt > $1.createdAt })

            if !groupTasks.isEmpty {
                newGroupedTasks[group.name] = groupTasks
            }
        }

        self.groupedTasks = newGroupedTasks
    }

    // MARK: - Standard Aufgabe

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
            createdAt: Date(),
            lastDoneAt: nil,
            resetInterval: .never
        )
        
        try? await db.collection("tasks").document(defaultTask.id).setData([
            "id": defaultTask.id,
            "title": defaultTask.title,
            "isDone": defaultTask.isDone,
            "ownerId": uid,
            "groupId": NSNull(),
            "createdAt": Timestamp(date: defaultTask.createdAt),
            "lastDoneAt": NSNull(),
            "resetInterval": defaultTask.resetInterval.rawValue
        ])
    }

    // MARK: - Aufgaben erstellen

    func addPersonalTask(title: String, resetInterval: TaskResetInterval) async {
        guard let uid = currentUserId else { return }

        let newTask = TaskItem(
            id: UUID().uuidString,
            title: title,
            isDone: false,
            ownerId: uid,
            groupId: nil,
            createdAt: Date(),
            lastDoneAt: nil,
            resetInterval: resetInterval
        )

        do {
            try await db.collection("tasks").document(newTask.id).setData([
                "id": newTask.id,
                "title": newTask.title,
                "isDone": newTask.isDone,
                "ownerId": uid,
                "groupId": NSNull(),
                "createdAt": Timestamp(date: newTask.createdAt),
                "lastDoneAt": NSNull(),
                "resetInterval": resetInterval.rawValue
            ])
            try await fetchTasks(groups: [])
        } catch {
            print("Fehler beim Hinzufügen eigener Aufgabe: \(error)")
        }
    }

    func addGroupTask(title: String, group: Group, resetInterval: TaskResetInterval) async {
        guard let uid = currentUserId else { return }

        let newTask = TaskItem(
            id: UUID().uuidString,
            title: title,
            isDone: false,
            ownerId: uid,
            groupId: group.id,
            createdAt: Date(),
            lastDoneAt: nil,
            resetInterval: resetInterval
        )

        do {
            try await db.collection("tasks").document(newTask.id).setData([
                "id": newTask.id,
                "title": newTask.title,
                "isDone": newTask.isDone,
                "ownerId": uid,
                "groupId": group.id,
                "createdAt": Timestamp(date: newTask.createdAt),
                "lastDoneAt": NSNull(),
                "resetInterval": resetInterval.rawValue
            ])

            // Nur diese Gruppe neu laden
            let groupSnapshot = try await db.collection("tasks")
                .whereField("groupId", isEqualTo: group.id)
                .getDocuments()

            let groupTasks = groupSnapshot.documents.compactMap {
                try? $0.data(as: TaskItem.self)
            }.sorted(by: { $0.createdAt > $1.createdAt })

            self.groupedTasks[group.name] = groupTasks

        } catch {
            print("Fehler beim Hinzufügen Gruppen-Aufgabe: \(error)")
        }
    }

    // MARK: - Aufgabenstatus ändern

    func toggleTaskDone(_ task: TaskItem) async {
        let newStatus = !task.isDone
        let newLastDoneAt = newStatus ? Date() : nil

        do {
            try await db.collection("tasks").document(task.id).updateData([
                "isDone": newStatus,
                "lastDoneAt": newLastDoneAt != nil ? Timestamp(date: newLastDoneAt!) : NSNull()
            ])

            if task.groupId == nil {
                if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
                    var updatedTask = personalTasks[index]
                    updatedTask.isDone = newStatus
                    updatedTask.lastDoneAt = newLastDoneAt
                    personalTasks[index] = updatedTask
                }
            } else {
                for (groupName, tasks) in groupedTasks {
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        var updatedTask = tasks[index]
                        updatedTask.isDone = newStatus
                        updatedTask.lastDoneAt = newLastDoneAt
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

    // MARK: - Aufgaben zurücksetzen

    func checkAndResetTasks() async {
        let now = Date()
        var tasksToUpdate: [(TaskItem, IndexPath)] = []

        for (index, task) in personalTasks.enumerated() {
            if let resetTask = getResetTaskIfNeeded(task: task, now: now) {
                tasksToUpdate.append((resetTask, IndexPath(row: index, section: 0)))
            }
        }

        for (groupName, tasks) in groupedTasks {
            for (index, task) in tasks.enumerated() {
                if let resetTask = getResetTaskIfNeeded(task: task, now: now) {
                    tasksToUpdate.append((resetTask, IndexPath(row: index, section: groupName.hashValue)))
                }
            }
        }

        for (task, indexPath) in tasksToUpdate {
            do {
                try await db.collection("tasks").document(task.id).updateData([
                    "isDone": false,
                    "lastDoneAt": NSNull()
                ])

                if indexPath.section == 0 {
                    personalTasks[indexPath.row] = task
                } else {
                    for (groupName, tasks) in groupedTasks {
                        if groupName.hashValue == indexPath.section {
                            var groupTasks = tasks
                            groupTasks[indexPath.row] = task
                            groupedTasks[groupName] = groupTasks
                        }
                    }
                }

            } catch {
                print("Fehler beim Zurücksetzen der Aufgabe: \(error)")
            }
        }
    }

    private func getResetTaskIfNeeded(task: TaskItem, now: Date) -> TaskItem? {
        guard task.isDone, let lastDone = task.lastDoneAt else { return nil }

        switch task.resetInterval {
        case .daily:
            if !Calendar.current.isDateInToday(lastDone) {
                var resetTask = task
                resetTask.isDone = false
                resetTask.lastDoneAt = nil
                return resetTask
            }
        case .weekly:
            let weekOfLastDone = Calendar.current.component(.weekOfYear, from: lastDone)
            let weekOfNow = Calendar.current.component(.weekOfYear, from: now)
            if weekOfLastDone != weekOfNow {
                var resetTask = task
                resetTask.isDone = false
                resetTask.lastDoneAt = nil
                return resetTask
            }
        case .never:
            return nil
        }
        return nil
    }

    // MARK: - Aufgaben löschen & bearbeiten

    func deleteTask(_ task: TaskItem) async {
        do {
            try await db.collection("tasks").document(task.id).delete()

            if task.groupId == nil {
                self.personalTasks.removeAll { $0.id == task.id }
            } else {
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
        do {
            try await db.collection("tasks").document(task.id).updateData([
                "title": newTitle
            ])

            if let groupId = task.groupId {
                for (groupName, tasks) in groupedTasks {
                    if tasks.contains(where: { $0.id == task.id }) {
                        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                            groupedTasks[groupName]?[index].title = newTitle
                        }
                    }
                }
            } else {
                if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
                    personalTasks[index].title = newTitle
                }
            }
        } catch {
            print("Fehler beim Aktualisieren der Aufgabe: \(error.localizedDescription)")
        }
    }
}
