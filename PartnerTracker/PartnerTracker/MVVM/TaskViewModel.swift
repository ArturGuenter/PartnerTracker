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
        let total = totalTaskCount
        if total == 0 { return 0 }

        return Double(doneTaskCount) / Double(total)
    }


    var personalCompletionRate: Double {
        guard !personalTasks.isEmpty else { return 0.0 }
        return Double(personalTasks.filter { $0.isDone }.count) / Double(personalTasks.count)
    }
    
    var groupCompletionRate: Double {
        let total = groupedTasks.values.flatMap { $0 }.count
        if total == 0 { return 0 }
        return Double(doneGroupTaskCount) / Double(total)
    }

    
    var doneTaskCount: Int {
        donePersonalTaskCount + doneGroupTaskCount
    }


    var totalTaskCount: Int {
        personalTasks.count + groupedTasks.flatMap { $0.value }.count
    }

    var donePersonalTaskCount: Int {
        personalTasks.filter { $0.isDone }.count
    }

    var doneGroupTaskCount: Int {
        guard let userId = currentUserId else { return 0 }

        return groupedTasks.values
            .flatMap { $0 }
            .filter { task in
                task.completedBy.contains(userId)
            }
            .count
    }

    
    var activitySummaryLast30Days: [Date: Int] {
            var summary: [Date: Int] = [:]
            let allTasks = personalTasks + groupedTasks.flatMap { $0.value }
            let calendar = Calendar.current

            for task in allTasks {
                for date in task.completionDates {
                    let day = calendar.startOfDay(for: date)
                    summary[day, default: 0] += 1
                }
            }
            return summary
        }
    
    @Published var completionHistory: [Date: Int] = [:]

    

    
    func personalTasks(for interval: TaskResetInterval) -> [TaskItem] {
           personalTasks.filter { $0.resetInterval == interval }
       }

       
       func groupTasks(for groupName: String, interval: TaskResetInterval) -> [TaskItem] {
           (groupedTasks[groupName] ?? []).filter { $0.resetInterval == interval }
       }
    

    func fetchTasks(groups: [Group]) async throws {
        guard let uid = currentUserId else {
            print("⚠️ Kein eingeloggter Benutzer – fetchTasks abgebrochen.")
            return
        }

        

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
                lastResetAt: Date(),
                completedBy: [],
                completionDates: []
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
                "lastResetAt": Timestamp(date: newTask.lastResetAt),
                "completedBy": [],
                "completionDates": []
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
            lastResetAt: Date(),
            completedBy: [],
            completionDates: []
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
                "lastResetAt": Timestamp(date: newTask.lastResetAt),
                "completedBy": [],
                "completionDates": []
            ])

            
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
    
   

    func toggleTaskStatus(_ task: TaskItem, group: Group?) async {
        guard let uid = currentUserId else { return }

        let taskRef = db.collection("tasks").document(task.id)
        let today = Calendar.current.startOfDay(for: Date())

        if let group = group {
            // Gruppenaufgabe
            var updatedCompletedBy = task.completedBy
            var updatedCompletionDates = task.completionDates

            if updatedCompletedBy.contains(uid) {
                updatedCompletedBy.removeAll { $0 == uid }
                updatedCompletionDates.removeAll { Calendar.current.isDate($0, inSameDayAs: today) }
            } else {
                updatedCompletedBy.append(uid)
                updatedCompletionDates.append(today)
                await incrementCompletionCount(for: today) // Historie hochzählen
            }

            do {
                try await taskRef.updateData([
                    "completedBy": updatedCompletedBy,
                    "completionDates": updatedCompletionDates.map { Timestamp(date: $0) }
                ])
                if var tasks = groupedTasks[group.name],
                   let index = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[index].completedBy = updatedCompletedBy
                    tasks[index].completionDates = updatedCompletionDates
                    groupedTasks[group.name] = tasks
                }
            } catch {
                print("Fehler beim Aktualisieren der Gruppenaufgabe: \(error)")
            }

        } else {
            // Persönliche Aufgabe
            let newStatus = !task.isDone
            var updatedCompletionDates = task.completionDates
            if newStatus {
                updatedCompletionDates.append(today)
                await incrementCompletionCount(for: today) // Historie hochzählen
            } else {
                updatedCompletionDates.removeAll { Calendar.current.isDate($0, inSameDayAs: today) }
            }

            do {
                try await taskRef.updateData([
                    "isDone": newStatus,
                    "completionDates": updatedCompletionDates.map { Timestamp(date: $0) }
                ])
                if let index = personalTasks.firstIndex(where: { $0.id == task.id }) {
                    personalTasks[index].isDone = newStatus
                    personalTasks[index].completionDates = updatedCompletionDates
                }
            } catch {
                print("Fehler beim Aktualisieren der persönlichen Aufgabe: \(error)")
            }
        }
    }



    
    func incrementCompletionCount(for date: Date) async {
        guard let uid = currentUserId else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)

        let historyRef = db.collection("users")
            .document(uid)
            .collection("completionHistory")
            .document(dateKey)

        do {
            try await historyRef.setData(
                ["count": FieldValue.increment(Int64(1))],
                merge: true
            )
        } catch {
            print("Fehler beim Hochzählen der Historie: \(error)")
        }
    }


    func fetchCompletionHistory() async {
            guard let uid = currentUserId else { return }
            let ref = db.collection("completionHistory").document(uid)

            do {
                let snapshot = try await ref.getDocument()
                if let data = snapshot.data()?["history"] as? [String: Int] {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    completionHistory = data.reduce(into: [:]) { dict, element in
                        if let date = formatter.date(from: element.key) {
                            dict[date] = element.value
                        }
                    }
                }
            } catch {
                print("Fehler beim Laden der Historie: \(error)")
            }
        }

    
    
}



