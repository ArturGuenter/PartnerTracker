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

    var body: some View {
        List {
            personalTasksSection
            groupTasksSection
        }
        .listStyle(.insetGrouped)
        .onAppear(perform: loadData)
        .sheet(item: $activeSheet, content: { sheet in
            sheetView(for: sheet)
        })
    }

    // MARK: - Eigene Aufgaben
    var personalTasksSection: some View {
        Section(header:
            HStack {
                Text("Meine Aufgaben").font(.headline)
                Spacer()
                Button {
                    newTaskTitle = ""
                    personalTaskInterval = .daily
                    activeSheet = .personal
                } label: {
                    Label("Neue Aufgabe", systemImage: "plus.circle")
                }
            }
        ) {
            if taskViewModel.personalTasks.isEmpty {
                Text("Noch keine eigenen Aufgaben.")
                    .foregroundColor(.gray)
            } else {
                ForEach(TaskResetInterval.allCases) { interval in
                    let tasks = taskViewModel.personalTasks.filter { $0.resetInterval == interval }
                    if !tasks.isEmpty {
                        Section(header: Text(intervalHeader(interval))) {
                            ForEach(tasks) { task in
                                taskRow(task: task)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Gruppenaufgaben
    var groupTasksSection: some View {
        Section(header: Text("Gruppenaufgaben").font(.headline)) {
            if groupViewModel.groups.isEmpty {
                Text("Du bist noch keiner Gruppe beigetreten.").foregroundColor(.gray)
            } else {
                ForEach(groupViewModel.groups) { group in
                    Section(header:
                        HStack {
                            Text(group.name).bold()
                            Spacer()
                            Button {
                                newTaskTitle = ""
                                groupTaskInterval = .daily
                                activeSheet = .group(group)
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                        }
                    ) {
                        let tasks = taskViewModel.groupedTasks[group.name] ?? []
                        if tasks.isEmpty {
                            Text("Keine Aufgaben in dieser Gruppe.").foregroundColor(.gray)
                        } else {
                            ForEach(tasks) { task in
                                taskRow(task: task, group: group)
                            }

                        }
                    }
                }
            }
        }
    }

    // MARK: - Aufgaben-Row
    func taskRow(task: TaskItem, group: Group? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                let isGroupTask = task.groupId != nil
                let currentUserId = taskViewModel.currentUserId
                let userHasCompleted = isGroupTask && currentUserId != nil && task.completedBy.contains(currentUserId!)
                let showCheckmark = isGroupTask ? userHasCompleted : task.isDone
                let iconName = showCheckmark ? "checkmark.circle.fill" : "circle"
                let iconColor = showCheckmark ? Color.green : Color.gray

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
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 4)
            .swipeActions {
                if task.ownerId == taskViewModel.currentUserId {
                    Button(role: .destructive) {
                        Task {
                            await taskViewModel.deleteTask(task)
                        }
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
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
                .padding(.top, 4)
            }
        }
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
                        try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
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
                        try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
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
                        try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                        activeSheet = nil
                    }
                },
                onCancel: {
                    activeSheet = nil
                }
            )
        }
    }

    // MARK: - Laden der Daten
    func loadData() {
        Task {
            do {
                try await taskViewModel.addDefaultTaskIfNeeded()
                try await groupViewModel.fetchGroupsForCurrentUser()
                try await taskViewModel.fetchTasks(groups: groupViewModel.groups)
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
            password: "1234"
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

