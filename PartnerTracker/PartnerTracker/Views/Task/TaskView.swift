//
//  TaskView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 19.06.25.
//

import SwiftUI

extension Array where Element == TaskItem {
    func sortedByCreationDate() -> [TaskItem] {
        self.sorted {
            if $0.createdAt == $1.createdAt { return $0.id < $1.id }
            return $0.createdAt > $1.createdAt
        }
    }
}

struct TaskView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var groupViewModel: GroupViewModel
    
    @State private var activeSheet: TaskSheetType?
    @State private var newTaskTitle = ""
    @State private var personalTaskInterval: TaskResetInterval = .daily
    @State private var groupTaskInterval: TaskResetInterval = .daily
    @State private var sortByInterval = false
    
    
    private func isUserAdmin(of group: Group) -> Bool {
        return group.ownerId == taskViewModel.currentUserId
    }
    
    var body: some View {
        NavigationStack {
            listContent
                .listStyle(.insetGrouped)
                .navigationTitle("Aufgaben")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear(perform: loadData)
                .sheet(item: $activeSheet) { sheet in sheetView(for: sheet) }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            sortByInterval.toggle()
                        } label: {
                            Image(systemName: sortByInterval ? "list.bullet" : "line.3.horizontal.decrease.circle")
                        }
                    }
                }
        }
    }
    
    // MARK: - Haupt-Liste aufgeteilt
    @ViewBuilder
    private var listContent: some View {
        if sortByInterval {
            sortedByIntervalView
        } else {
            sortedByGroupView
        }
    }
    
    // MARK: - Nach Intervall sortierte Ansicht
    private var sortedByIntervalView: some View {
        List {
            ForEach(TaskResetInterval.allCases, id: \.self) { interval in
                intervalSection(interval)
            }
        }
    }
    
    // MARK: - Nach Gruppen sortierte Ansicht
    private var sortedByGroupView: some View {
        List {
            personalTasksByInterval
            groupTasksByGroup
        }
    }
    
    // MARK: - Interval Section (für sortByInterval = true)
    @ViewBuilder
    private func intervalSection(_ interval: TaskResetInterval) -> some View {
        let personalForInterval = taskViewModel.personalTasks
            .filter { $0.resetInterval == interval }
            .sortedByCreationDate()
        
        let groupedForInterval = groupedTasksByInterval(interval)
        
        if !personalForInterval.isEmpty || !groupedForInterval.isEmpty {
            Section(header: intervalHeader(interval)) {
                personalTasksInInterval(personalForInterval, interval: interval)
                groupTasksInInterval(groupedForInterval, interval: interval)
            }
            .listRowBackground(color(for: interval).opacity(0.05))
        }
    }
    
    // MARK: - Interval Header
    private func intervalHeader(_ interval: TaskResetInterval) -> some View {
        HStack {
            Text(intervalHeaderText(interval))
                .font(.headline)
                .foregroundColor(color(for: interval))
            Spacer()
            // Plus-Button für persönliche Aufgaben - immer sichtbar
            Button {
                newTaskTitle = ""
                personalTaskInterval = interval
                activeSheet = .personal
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(color(for: interval))
            }
        }
    }
    
    // MARK: - Persönliche Aufgaben in Intervall-Ansicht
    @ViewBuilder
    private func personalTasksInInterval(_ tasks: [TaskItem], interval: TaskResetInterval) -> some View {
        ForEach(tasks, id: \.id) { task in
            taskRow(task: task, group: nil, interval: interval)
        }
    }
    
    // MARK: - Gruppenaufgaben in Intervall-Ansicht
    @ViewBuilder
    private func groupTasksInInterval(_ tasks: [(task: TaskItem, group: Group)], interval: TaskResetInterval) -> some View {
        ForEach(groupViewModel.groups, id: \.id) { group in
            let tasksForGroup = tasks.filter { $0.group.id == group.id }
            if !tasksForGroup.isEmpty {
                groupHeaderInInterval(group, interval: interval)
                ForEach(tasksForGroup, id: \.task.id) { element in
                    taskRow(task: element.task, group: element.group, interval: interval)
                }
            }
        }
    }
    
    // MARK: - Gruppen-Header in Intervall-Ansicht
    private func groupHeaderInInterval(_ group: Group, interval: TaskResetInterval) -> some View {
        HStack {
            Text(group.name)
                .font(.subheadline).bold()
            Spacer()
            // Plus-Button nur für Admin sichtbar
            if isUserAdmin(of: group) {
                Button {
                    newTaskTitle = ""
                    groupTaskInterval = interval
                    activeSheet = .group(group)
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
    
    // MARK: - Persönliche Aufgaben nach Intervallen gruppiert
    @ViewBuilder
    private var personalTasksByInterval: some View {
        ForEach(TaskResetInterval.allCases, id: \.self) { interval in
            let tasks = taskViewModel.personalTasks
                .filter { $0.resetInterval == interval }
                .sortedByCreationDate()
            
            if !tasks.isEmpty {
                Section(header: personalSectionHeader(interval)) {
                    ForEach(tasks, id: \.id) { task in
                        taskRow(task: task, group: nil, interval: interval)
                    }
                }
                .listRowBackground(color(for: interval).opacity(0.05))
            }
        }
    }
    
    // MARK: - Gruppenaufgaben nach Gruppen
    @ViewBuilder
    private var groupTasksByGroup: some View {
        ForEach(groupViewModel.groups, id: \.id) { group in
            Section(header: groupSectionHeader(group)) {
                let tasks = taskViewModel.groupedTasks[group.name] ?? []
                if tasks.isEmpty {
                    Text("Keine Aufgaben in dieser Gruppe.")
                        .foregroundColor(.gray)
                } else {
                    groupTasksContent(tasks, group: group)
                }
            }
        }
    }
    
    // MARK: - Personal Section Header
    private func personalSectionHeader(_ interval: TaskResetInterval) -> some View {
        HStack {
            Text("Meine Aufgaben — \(intervalHeaderText(interval))")
                .foregroundColor(color(for: interval))
                .font(.headline)
            Spacer()
            // Plus-Button für persönliche Aufgaben - immer sichtbar
            Button {
                newTaskTitle = ""
                personalTaskInterval = interval
                activeSheet = .personal
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(color(for: interval))
            }
        }
    }
    
    // MARK: - Group Section Header
    private func groupSectionHeader(_ group: Group) -> some View {
        HStack {
            Text(group.name)
                .font(.headline)
            Spacer()
            // Plus-Button nur für Admin sichtbar
            if isUserAdmin(of: group) {
                Button {
                    newTaskTitle = ""
                    groupTaskInterval = .daily
                    activeSheet = .group(group)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    // MARK: - Group Tasks Content
    @ViewBuilder
    private func groupTasksContent(_ tasks: [TaskItem], group: Group) -> some View {
        ForEach(TaskResetInterval.allCases, id: \.self) { interval in
            let filteredTasks = tasks
                .filter { $0.resetInterval == interval }
                .sortedByCreationDate()
            
            if !filteredTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(intervalHeaderText(interval))
                            .font(.subheadline.bold())
                            .foregroundColor(color(for: interval))
                        Spacer()
                        // Plus-Button für spezifisches Intervall nur für Admin sichtbar
                        if isUserAdmin(of: group) {
                            Button {
                                newTaskTitle = ""
                                groupTaskInterval = interval
                                activeSheet = .group(group)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(color(for: interval))
                            }
                        }
                    }
                    
                    ForEach(filteredTasks, id: \.id) { task in
                        taskRow(task: task, group: group, interval: interval)
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(color(for: interval).opacity(0.05))
            }
        }
    }
    
    // MARK: - Hilfsfunktionen
    private func groupedTasksByInterval(_ interval: TaskResetInterval) -> [(task: TaskItem, group: Group)] {
        return groupViewModel.groups.flatMap { group in
            (taskViewModel.groupedTasks[group.name] ?? [])
                .filter { $0.resetInterval == interval }
                .map { (task: $0, group: group) }
        }.sorted { a, b in
            if a.task.createdAt == b.task.createdAt { return a.task.id < b.task.id }
            return a.task.createdAt > b.task.createdAt
        }
    }

    private func intervalHeaderText(_ interval: TaskResetInterval) -> String {
        switch interval {
        case .daily: return "Täglich"
        case .weekly: return "Wöchentlich"
        case .monthly: return "Monatlich"
        }
    }

    // MARK: - Task Row vereinfacht
    private func taskRow(task: TaskItem, group: Group?, interval: TaskResetInterval) -> some View {
        taskCard(task: task, group: group, interval: interval)
            .swipeActions {
                // Löschen-Button nur für Admin sichtbar bei Gruppenaufgaben
                if task.groupId == nil || (group != nil && isUserAdmin(of: group!)) {
                    Button(role: .destructive) {
                        deleteTaskSafely(task)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
    }
    
    // MARK: - Task Card
    func taskCard(task: TaskItem, group: Group? = nil, interval: TaskResetInterval? = nil) -> some View {
        let isGroupTask = task.groupId != nil
        let currentUserId = taskViewModel.currentUserId
        let userHasCompleted = isGroupTask && currentUserId != nil && task.completedBy.contains(currentUserId!)
        let showCheckmark = isGroupTask ? userHasCompleted : task.isDone
        let iconName = showCheckmark ? "checkmark.circle.fill" : "circle"
        let iconColor = showCheckmark ? Color.green : .gray

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .onTapGesture {
                        Task {
                            let actualGroup = group ?? groupViewModel.groups.first(where: { $0.id == task.groupId })
                            await taskViewModel.toggleTaskStatus(task, group: actualGroup)
                        }
                    }

                Text(task.title)
                    .strikethrough(showCheckmark)
                    .foregroundColor(showCheckmark ? .gray : .primary)

                Spacer()

                // Bearbeiten-Button nur für Admin sichtbar bei Gruppenaufgaben
                if task.groupId == nil || (group != nil && isUserAdmin(of: group!)) {
                    Button {
                        activeSheet = .edit(task)
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let groupId = task.groupId,
               let group = groupViewModel.groups.first(where: { $0.id == groupId }) {
                HStack(spacing: 8) {
                    ForEach(group.memberIds, id: \.self) { memberId in
                        GroupMemberCircle(
                            memberId: memberId,
                            completed: task.completedBy.contains(memberId),
                            groupViewModel: groupViewModel
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: color(for: interval ?? .daily).opacity(0.2), radius: 3, x: 0, y: 2)
    }
    
    // MARK: - Sheet Handling
    @ViewBuilder
    func sheetView(for sheet: TaskSheetType) -> some View {
        switch sheet {
        case .personal:
            TaskSheetView(
                title: "Eigene Aufgabe",
                taskTitle: $newTaskTitle,
                selectedInterval: $personalTaskInterval,
                onCancel: { activeSheet = nil },
                onConfirm: {
                    Task {
                        await taskViewModel.addPersonalTask(title: newTaskTitle, interval: personalTaskInterval)
                        activeSheet = nil
                    }
                }
            )

        case .group(let group):
            // Nur Admin kann Gruppenaufgaben hinzufügen (Sicherheitscheck)
            if isUserAdmin(of: group) {
                TaskSheetView(
                    title: "Neue Aufgabe für \(group.name)",
                    taskTitle: $newTaskTitle,
                    selectedInterval: $groupTaskInterval,
                    onCancel: { activeSheet = nil },
                    onConfirm: {
                        Task {
                            do {
                                try await taskViewModel.addGroupTask(
                                    title: newTaskTitle,
                                    group: group,
                                    interval: groupTaskInterval
                                )
                                activeSheet = nil
                            } catch {
                                print("Fehler beim Hinzufügen der Gruppenaufgabe: \(error)")
                            }
                        }
                    }
                )
            }

        case .edit(let task):
            // Bearbeiten nur erlauben wenn User Admin ist oder es eine persönliche Aufgabe ist
            if task.groupId == nil ||
               (task.groupId != nil && groupViewModel.groups.contains { $0.id == task.groupId && isUserAdmin(of: $0) }) {
                EditTaskSheetWithInterval(
                    task: task,
                    onSave: { updatedTitle, updatedInterval in
                        Task {
                            await taskViewModel.updateTask(task: task, newTitle: updatedTitle, newInterval: updatedInterval)
                            activeSheet = nil
                        }
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
            }
        }
    }
    
    // MARK: - Farben für Intervalle
    func color(for interval: TaskResetInterval) -> Color {
        switch interval {
        case .daily: return .blue
        case .weekly: return .orange
        case .monthly: return .purple
        }
    }

    // MARK: - Daten Laden
    func loadData() {
        Task {
            do {
                try await groupViewModel.fetchGroupsForCurrentUser()
                taskViewModel.listenToTasks(groups: groupViewModel.groups)
                await taskViewModel.fetchCompletionHistory()
            } catch {
                print("Fehler beim Laden: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteTaskSafely(_ task: TaskItem) {
        Task {
            do {
                try await taskViewModel.deleteTask(task)
            } catch {
                print("Fehler beim Löschen: \(error)")
            }
        }
    }
}

// MARK: - Vorschau mit Beispieldaten
#Preview {
    let taskVM = TaskViewModel()
    let groupVM = GroupViewModel()
    
    taskVM.personalTasks = [
        TaskItem(
            id: "1",
            title: "App öffnen",
            isDone: false,
            ownerId: "demo",
            groupId: nil,
            createdAt: Date(),
            resetInterval: .daily,
            lastResetAt: Date()
        )
    ]
    
    groupVM.groups = [
        Group(
            id: "g1",
            name: "Projekt X",
            memberIds: ["demo"],
            createdAt: Date(),
            password: "1234",
            ownerId: "123"
        )
    ]
    
    taskVM.groupedTasks = [
        "Projekt X": [
            TaskItem(
                id: "2",
                title: "Meeting vorbereiten",
                isDone: true,
                ownerId: "demo",
                groupId: "g1",
                createdAt: Date(),
                resetInterval: .weekly,
                lastResetAt: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date()
            )
        ]
    ]
    
    return TaskView(
        taskViewModel: taskVM,
        groupViewModel: groupVM
    )
}





