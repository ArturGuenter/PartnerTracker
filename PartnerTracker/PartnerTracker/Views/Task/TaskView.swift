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
    
    @State private var editingTask: TaskItem?
    
    @State private var personalTaskInterval: TaskResetInterval = .daily
    @State private var groupTaskInterval: TaskResetInterval = .daily



    var body: some View {
        List {
            // MARK: - Eigene Aufgaben
            Section(header:
                HStack {
                    Text("Meine Aufgaben")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        activeSheet = .personal
                    }) {
                        Label("Neue Aufgabe", systemImage: "plus.circle")
                    }
                }
            ) {
                if taskViewModel.personalTasks.isEmpty {
                    Text("Noch keine eigenen Aufgaben.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(taskViewModel.personalTasks) { task in
                        HStack {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isDone ? .green : .gray)
                                .onTapGesture {
                                    Task {
                                        await taskViewModel.toggleTaskDone(task)
                                    }
                                }
                            Text(task.title)
                                .strikethrough(task.isDone)
                                .foregroundColor(task.isDone ? .gray : .primary)
                            Spacer()
                            Button {
                                editingTask = task
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())

                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await taskViewModel.deleteTask(task)
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            // MARK: - Gruppenaufgaben
            Section(header: Text("Gruppenaufgaben").font(.headline)) {
                if groupViewModel.groups.isEmpty {
                    Text("Du bist noch keiner Gruppe beigetreten.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(groupViewModel.groups) { group in
                        Section(header:
                            HStack {
                                Text(group.name)
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Button {
                                    activeSheet = .group(group)
                                } label: {
                                    Image(systemName: "plus.circle")
                                }
                            }
                        ) {
                            let tasks = taskViewModel.groupedTasks[group.name] ?? []
                            if tasks.isEmpty {
                                Text("Keine Aufgaben in dieser Gruppe.")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(tasks) { task in
                                    HStack {
                                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.isDone ? .green : .gray)
                                            .onTapGesture {
                                                Task {
                                                    await taskViewModel.toggleTaskDone(task)
                                                }
                                            }
                                        Text(task.title)
                                            .strikethrough(task.isDone)
                                            .foregroundColor(task.isDone ? .gray : .primary)
                                        Spacer()
                                        Button {
                                            editingTask = task
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
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
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

        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .personal:
                TaskSheetView(
                    title: "Eigene Aufgabe",
                    taskTitle: $newTaskTitle,
                    selectedInterval: $selectedInterval,
                    onCancel: {
                        newTaskTitle = ""
                        activeSheet = nil
                    },
                    onConfirm: {
                        Task {
                            await taskViewModel.addPersonalTask(title: newTaskTitle, interval: selectedInterval)
                            try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                            newTaskTitle = ""
                            activeSheet = nil
                        }
                    }
                )

            case .group(let group):
                TaskSheetView(
                    title: "Neue Aufgabe für \(group.name)",
                    taskTitle: $newTaskTitle,
                    selectedInterval: $selectedInterval,
                    onCancel: {
                        newTaskTitle = ""
                        activeSheet = nil
                    },
                    onConfirm: {
                        Task {
                            await taskViewModel.addGroupTask(title: newTaskTitle, group: group, interval: selectedInterval)
                            try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                            newTaskTitle = ""
                            activeSheet = nil
                        }
                    }
                )

            case .edit(let task):
                EditTaskSheet(task: task) { updatedTitle in
                    Task {
                        await taskViewModel.updateTaskTitle(task: task, newTitle: updatedTitle)
                        try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                        activeSheet = nil
                    }
                }
            }
        }

        /*
        // MARK: - Sheet eigene Aufgabe
        .sheet(isPresented: $showPersonalTaskSheet) {
            TaskSheetView(
                title: "Neue persönliche Aufgabe",
                taskTitle: $newTaskTitle,
                selectedInterval: $personalTaskInterval,
                onCancel: {
                    newTaskTitle = ""
                    showPersonalTaskSheet = false
                },
                onConfirm: {
                    Task {
                        await taskViewModel.addPersonalTask(title: newTaskTitle, interval: personalTaskInterval)
                        try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                        newTaskTitle = ""
                        showPersonalTaskSheet = false
                        personalTaskInterval = .daily
                    }
                }
            )
        }


        // MARK: - Sheet Gruppenaufgabe
        .sheet(isPresented: $showPersonalTaskSheet) {
            TaskSheetView(
                title: "Neue persönliche Aufgabe",
                taskTitle: $newTaskTitle,
                selectedInterval: $personalTaskInterval,
                onCancel: {
                    newTaskTitle = ""
                    showPersonalTaskSheet = false
                },
                onConfirm: {
                    Task {
                        await taskViewModel.addPersonalTask(title: newTaskTitle, interval: personalTaskInterval)
                        try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                        newTaskTitle = ""
                        showPersonalTaskSheet = false
                        personalTaskInterval = .daily
                    }
                }
            )
        }

        
        // MARK: - Sheet Aufagabe Bearbeiten
        .sheet(item: $editingTask) { task in
            EditTaskSheet(task: task) { updatedTitle in
                Task {
                    await taskViewModel.updateTaskTitle(task: task, newTitle: updatedTitle)
                    try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                }
                editingTask = nil
            }
        }
        */

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

