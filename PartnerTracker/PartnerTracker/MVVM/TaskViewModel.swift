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

        // Persönliche Aufgaben laden und resetten
        let personalSnapshot = try await db.collection("tasks")
            .whereField("ownerId", isEqualTo: uid)
            .whereField("groupId", isEqualTo: NSNull())
            .getDocuments()

        let loadedPersonalTasks = try personalSnapshot.documents.compactMap {
            try $0.data(as: TaskItem.self)
        }

        var resetPersonalTasks: [TaskItem] = []
        
        try await withThrowingTaskGroup(of: TaskItem.self) { group in
            for task in loadedPersonalTasks {
                group.addTask {
                    await self.checkAndResetTaskIfNeeded(task)
                }
            }

            for try await checkedTask in group {
                resetPersonalTasks.append(checkedTask)
            }
        }

        self.personalTasks = resetPersonalTasks.sorted(by: { $0.createdAt > $1.createdAt })

        // Gruppenaufgaben laden und resetten
        var newGroupedTasks: [String: [TaskItem]] = [:]

        for group in groups {
            let groupSnapshot = try await db.collection("tasks")
                .whereField("groupId", isEqualTo: group.id)
                .getDocuments()

            let loadedGroupTasks = try groupSnapshot.documents.compactMap {
                try $0.data(as: TaskItem.self)
            }

            var resetGroupTasks: [TaskItem] = []

            try await withThrowingTaskGroup(of: TaskItem.self) { groupTaskGroup in
                for task in loadedGroupTasks {
                    groupTaskGroup.addTask {
                        await self.checkAndResetTaskIfNeeded(task)
                    }
                }

                for try await checkedTask in groupTaskGroup {
                    resetGroupTasks.append(checkedTask)
                }
            }

            if !resetGroupTasks.isEmpty {
                newGroupedTasks[group.name] = resetGroupTasks.sorted(by: { $0.createdAt > $1.createdAt })
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
            createdAt: Date(),
            resetInterval: TaskResetInterval.daily,
            lastResetAt: Date()
        )
        
        try? await db.collection("tasks").document(defaultTask.id).setData([
            "id": defaultTask.id,
            "title": defaultTask.title,
            "isDone": defaultTask.isDone,
            "ownerId": uid,
            "groupId": NSNull(),
            "createdAt": Timestamp(date: defaultTask.createdAt),
            "resetInterval": defaultTask.resetInterval.rawValue,
            "lastResetAt": Timestamp(date: defaultTask.lastResetAt)
            
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

    
    func updateTask(task: TaskItem, newTitle: String, newInterval: TaskResetInterval) async {
        do {
            try await db.collection("tasks").document(task.id).updateData([
                "title": newTitle,
                "resetInterval": newInterval.rawValue
            ])

            if let groupId = task.groupId {
                // Gruppenaufgabe aktualisieren
                if var tasks = groupedTasks.first(where: { $0.key == groupId })?.value {
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        tasks[index].title = newTitle
                        tasks[index].resetInterval = newInterval
                        groupedTasks[groupId] = tasks
                    }
                }
            } else {
                // Persönliche Aufgabe aktualisieren
                if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
                    personalTasks[index].title = newTitle
                    personalTasks[index].resetInterval = newInterval
                }
            }

        } catch {
            print("Fehler beim Aktualisieren der Aufgabe: \(error.localizedDescription)")
        }
    }



    func checkAndResetTaskIfNeeded(_ task: TaskItem) async -> TaskItem {
        let now = Date()
        let calendar = Calendar.current
        var needsReset = false

        switch task.resetInterval {
        case .daily:
            if !calendar.isDateInToday(task.lastResetAt) {
                let comparison = calendar.compare(now, to: task.lastResetAt, toGranularity: .day)
                if comparison == .orderedDescending {
                    needsReset = true
                }
            }

        case .weekly:
            if calendar.dateComponents([.weekOfYear], from: task.lastResetAt, to: now).weekOfYear ?? 0 >= 1 {
                needsReset = true
            }
        case .monthly:
            if calendar.dateComponents([.month], from: task.lastResetAt, to: now).month ?? 0 >= 1 {
                needsReset = true
            }
        }

        if needsReset {
            do {
                try await db.collection("tasks").document(task.id).updateData([
                    "isDone": false,
                    "lastResetAt": Timestamp(date: now),
                    "completedBy": []
                ])

                var resetTask = task
                resetTask.isDone = false
                resetTask.lastResetAt = now
                resetTask.completedBy = []
                return resetTask
            } catch {
                print("Fehler beim Zurücksetzen: \(error)")
                return task
            }
        } else {
            return task
        }

    }
    
    
    func toggleGroupTaskDone(_ task: TaskItem, in group: Group) async {
        guard let uid = currentUserId else { return }

        var updatedTask = task

        if task.completedBy.contains(uid) {
            
            updatedTask.completedBy.removeAll { $0 == uid }
        } else {
            updatedTask.completedBy.append(uid)
        }

        do {
            try await db.collection("tasks").document(task.id).updateData([
                "completedBy": updatedTask.completedBy
            ])

            
            for (groupName, tasks) in groupedTasks {
                if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    var tasksCopy = tasks
                    tasksCopy[index].completedBy = updatedTask.completedBy
                    groupedTasks[groupName] = tasksCopy
                    break
                }
            }

        } catch {
            print("Fehler beim Aktualisieren von completedBy: \(error)")
        }
    }


    
}



