//
//  TaskView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 19.06.25.
//

import SwiftUI

struct TaskView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var groupViewModel: GroupViewModel

    @State private var activeSheet: TaskSheetType?
    @State private var newTaskTitle = ""
    @State private var personalTaskInterval: TaskResetInterval = .daily
    @State private var groupTaskInterval: TaskResetInterval = .daily
    
    @State private var sortByInterval = false


    var body: some View {
        NavigationStack {
            VStack {
                if sortByInterval {
                    renderTasksByInterval()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            personalTasksSection
                            groupTasksSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Aufgaben")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadData)
            .sheet(item: $activeSheet) { sheet in
                sheetView(for: sheet)
            }
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


    // MARK: - Eigene Aufgaben
    var personalTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meine Aufgaben")
                    .font(.title2.bold())
                Spacer()
                Button {
                    newTaskTitle = ""
                    personalTaskInterval = .daily
                    activeSheet = .personal
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
            }

            if taskViewModel.personalTasks.isEmpty {
                Text("Noch keine eigenen Aufgaben.")
                    .foregroundColor(.gray)
            } else {
                ForEach(TaskResetInterval.allCases) { interval in
                    let tasks = taskViewModel.personalTasks.filter { $0.resetInterval == interval }
                    if !tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(intervalHeader(interval))
                                .font(.headline)
                                .foregroundColor(color(for: interval))

                            ForEach(tasks) { task in
                                taskCard(task: task, interval: interval)
                            }
                        }
                        .padding()
                        .background(color(for: interval).opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Gruppenaufgaben
    var groupTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gruppenaufgaben")
                .font(.title2.bold())

            if groupViewModel.groups.isEmpty {
                Text("Du bist noch keiner Gruppe beigetreten.")
                    .foregroundColor(.gray)
            } else {
                ForEach(groupViewModel.groups) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(group.name)
                                .font(.headline)
                            Spacer()
                            Button {
                                newTaskTitle = ""
                                groupTaskInterval = .daily
                                activeSheet = .group(group)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.orange)
                                    .imageScale(.large)
                            }
                        }

                        let tasks = taskViewModel.groupedTasks[group.name] ?? []
                        if tasks.isEmpty {
                            Text("Keine Aufgaben in dieser Gruppe.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(TaskResetInterval.allCases) { interval in
                                let filteredTasks = tasks.filter { $0.resetInterval == interval }
                                if !filteredTasks.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(intervalHeader(interval))
                                            .font(.headline)
                                            .foregroundColor(color(for: interval))

                                        ForEach(filteredTasks) { task in
                                            taskCard(task: task, group: group, interval: interval)
                                        }
                                    }
                                    .padding()
                                    .background(color(for: interval).opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                }
            }
        }
    }

    // MARK: - TaskCard
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

                Button {
                    activeSheet = .edit(task)
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
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
            TaskSheetView(
                title: "Neue Aufgabe für \(group.name)",
                taskTitle: $newTaskTitle,
                selectedInterval: $groupTaskInterval,
                onCancel: { activeSheet = nil },
                onConfirm: {
                    Task {
                        await taskViewModel.addGroupTask(title: newTaskTitle, group: group, interval: groupTaskInterval)
                        activeSheet = nil
                    }
                }
            )

        case .edit(let task):
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
    
    @ViewBuilder
    private func renderTasksByInterval() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: Eigene Aufgaben
                VStack(alignment: .leading, spacing: 12) {
                    Text("Meine Aufgaben")
                        .font(.title2.bold())
                    
                    ForEach(TaskResetInterval.allCases, id: \.self) { interval in
                        let tasks = taskViewModel.personalTasks.filter { $0.resetInterval == interval }
                        if !tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(intervalHeader(interval))
                                    .font(.headline)
                                    .foregroundColor(color(for: interval))
                                
                                ForEach(tasks) { task in
                                    taskCard(task: task, interval: interval)
                                }
                            }
                            .padding()
                            .background(color(for: interval).opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // MARK: Gruppenaufgaben
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gruppenaufgaben")
                        .font(.title2.bold())
                    
                    ForEach(groupViewModel.groups) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.name)
                                .font(.headline)
                            
                            ForEach(TaskResetInterval.allCases, id: \.self) { interval in
                                let tasks = taskViewModel.groupedTasks[group.name]?.filter { $0.resetInterval == interval } ?? []
                                if !tasks.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(intervalHeader(interval))
                                            .font(.subheadline)
                                            .foregroundColor(color(for: interval))
                                        
                                        ForEach(tasks) { task in
                                            taskCard(task: task, group: group, interval: interval)
                                        }
                                    }
                                    .padding()
                                    .background(color(for: interval).opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                }
            }
            .padding()
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

    // MARK: - Interval Header
    func intervalHeader(_ interval: TaskResetInterval) -> String {
        switch interval {
        case .daily: return "Täglich"
        case .weekly: return "Wöchentlich"
        case .monthly: return "Monatlich"
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

