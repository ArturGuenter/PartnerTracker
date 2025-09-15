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
    var notificationViewModel: NotificationViewModel?
    @Published var personalTasks: [TaskItem] = []
    @Published var groupedTasks: [String: [TaskItem]] = [:]
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private var personalListener: ListenerRegistration?
    private var groupListeners: [String: ListenerRegistration] = [:]
    
    
    
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
    
    
    
    
    
    func addPersonalTask(title: String, interval: TaskResetInterval) async {
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
            // ❌ kein fetchTasks(groups: []) mehr
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
        guard let uid = currentUserId else { return }
        
        let taskRef = db.collection("tasks").document(task.id)
        
        do {
            
            try await taskRef.delete()
            
            
            if let groupName = groupedTasks.first(where: { $0.value.contains(where: { $0.id == task.id }) })?.key {
                
                groupedTasks[groupName]?.removeAll { $0.id == task.id }
            } else {
                
                personalTasks.removeAll { $0.id == task.id }
            }
            
            
            
        } catch {
            print("Fehler beim Löschen der Aufgabe: \(error)")
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
        let todayLocal = Calendar.current.startOfDay(for: Date())
        
        if let group = group {
            // Gruppenaufgabe
            var updatedCompletedBy = task.completedBy
            var updatedCompletionDates = task.completionDates
            
            if updatedCompletedBy.contains(uid) {
                // Rücknahme
                updatedCompletedBy.removeAll { $0 == uid }
                updatedCompletionDates.removeAll { Calendar.current.isDate($0, inSameDayAs: todayLocal) }
                await incrementCompletionCount(for: todayLocal, increment: false)
            } else {
                
                updatedCompletedBy.append(uid)
                updatedCompletionDates.append(todayLocal)
                await incrementCompletionCount(for: todayLocal, increment: true)
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
                if let notificationVM = notificationViewModel {
                                notificationVM.handleGroupStatusChange(group: group, tasks: groupedTasks[group.name] ?? [])
                            }
                            
            } catch {
                print("Fehler beim Aktualisieren der Gruppenaufgabe: \(error)")
            }
            
        } else {
            // Persönliche Aufgabe
            let newStatus = !task.isDone
            var updatedCompletionDates = task.completionDates
            
            if newStatus {
                updatedCompletionDates.append(todayLocal)
                await incrementCompletionCount(for: todayLocal, increment: true)
            } else {
                updatedCompletionDates.removeAll { Calendar.current.isDate($0, inSameDayAs: todayLocal) }
                await incrementCompletionCount(for: todayLocal, increment: false)
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
    
    
    
    func incrementCompletionCount(for date: Date, increment: Bool) async {
        guard let uid = currentUserId else { return }
        
        
        let localDay = Calendar.current.startOfDay(for: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        let dateKey = formatter.string(from: localDay)
        
        let historyRef = db.collection("users")
            .document(uid)
            .collection("completionHistory")
            .document(dateKey)
        
        let change: Int64 = increment ? 1 : -1
        
        do {
            try await historyRef.setData(["count": FieldValue.increment(change)], merge: true)
            
            DispatchQueue.main.async {
                self.completionHistory[localDay, default: 0] += Int(change)
                if self.completionHistory[localDay] ?? 0 < 0 {
                    self.completionHistory[localDay] = 0
                }
            }
        } catch {
            print("Fehler beim Anpassen der Historie: \(error)")
        }
    }
    
    
    
    func fetchCompletionHistory(monthsBack: Int = 0) async {
        guard let uid = currentUserId else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        
        guard let targetMonth = calendar.date(byAdding: .month, value: -monthsBack, to: today),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth)),
              let range = calendar.range(of: .day, in: .month, for: targetMonth),
              let monthEnd = calendar.date(byAdding: .day, value: range.count - 1, to: monthStart) else {
            return
        }
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let startKey = formatter.string(from: monthStart)
        let endKey = formatter.string(from: monthEnd)
        
        do {
            
            let snapshot = try await db.collection("users")
                .document(uid)
                .collection("completionHistory")
                .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: startKey)
                .whereField(FieldPath.documentID(), isLessThanOrEqualTo: endKey)
                .getDocuments()
            
            var history: [Date: Int] = [:]
            
            for document in snapshot.documents {
                let dateString = document.documentID
                let parts = dateString.split(separator: "-").compactMap { Int($0) }
                if parts.count == 3 {
                    var comps = DateComponents()
                    comps.year = parts[0]
                    comps.month = parts[1]
                    comps.day = parts[2]
                    
                    if let localDay = calendar.date(from: comps) {
                        let count = document.data()["count"] as? Int ?? 0
                        history[calendar.startOfDay(for: localDay)] = count
                    }
                }
            }
            
            DispatchQueue.main.async {
                
                self.completionHistory.merge(history) { _, new in new }
            }
        } catch {
            print("Fehler beim Laden der Historie: \(error)")
        }
    }
    
    
    func listenToTasks(groups: [Group]) {
        guard let uid = currentUserId else { return }
        
        
        personalListener?.remove()
        personalListener = db.collection("tasks")
            .whereField("ownerId", isEqualTo: uid)
            .whereField("groupId", isEqualTo: NSNull())
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print(" Fehler beim Anhören persönlicher Aufgaben: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                
                let loaded = documents.compactMap { try? $0.data(as: TaskItem.self) }
                Task {
                    var resetTasks: [TaskItem] = []
                    for task in loaded {
                        let checked = await self.checkAndResetTaskIfNeeded(task)
                        resetTasks.append(checked)
                    }
                    DispatchQueue.main.async {
                        self.personalTasks = resetTasks.sorted(by: { $0.createdAt > $1.createdAt })
                    }
                }
            }
        
        
        for listener in groupListeners.values { listener.remove() }
        groupListeners.removeAll()
        
        for group in groups {
            let listener = db.collection("tasks")
                .whereField("groupId", isEqualTo: group.id)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let error = error {
                        print(" Fehler beim Anhören Gruppen-Aufgaben (\(group.name)): \(error)")
                        return
                    }
                    guard let documents = snapshot?.documents else { return }
                    
                    let loaded = documents.compactMap { try? $0.data(as: TaskItem.self) }
                    Task {
                        var resetTasks: [TaskItem] = []
                        for task in loaded {
                            let checked = await self.checkAndResetTaskIfNeeded(task)
                            resetTasks.append(checked)
                        }
                        DispatchQueue.main.async {
                            self.groupedTasks[group.name] = resetTasks.sorted(by: { $0.createdAt > $1.createdAt })
                        }
                    }
                }
            groupListeners[group.id] = listener
        }
    }
    
    func allGroupTasksByInterval() -> [TaskResetInterval: [IntervalTask]] {
        var result: [TaskResetInterval: [IntervalTask]] = [:]
        for (groupName, tasks) in groupedTasks {
            for task in tasks {
                result[task.resetInterval, default: []]
                    .append(IntervalTask(id: task.id, task: task, groupName: groupName))
            }
        }
        return result
    }

    func allTasksByInterval(groups: [Group]) -> [TaskResetInterval: [(TaskItem, String)]] {
        var result: [TaskResetInterval: [(TaskItem, String)]] = [:]

        // Eigene Aufgaben
        for task in personalTasks {
            result[task.resetInterval, default: []].append((task, "Meine Aufgaben"))
        }

        // Gruppenaufgaben
        for group in groups {
            let tasks = groupedTasks[group.name] ?? []
            for task in tasks {
                result[task.resetInterval, default: []].append((task, group.name))
            }
        }

        return result
    }


    
    deinit {
        personalListener?.remove()
        for listener in groupListeners.values {
            listener.remove()
        }
    }
    
    
    
    
}



