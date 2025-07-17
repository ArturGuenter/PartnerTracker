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

    @State private var showPersonalTaskSheet = false
    @State private var showGroupTaskSheetForGroup: Group?
    @State private var newTaskTitle = ""
    
    @State private var editingTask: TaskItem?
    
    @State private var selectedInterval: TaskResetInterval = .daily


    var body: some View {
        List {
            // MARK: - Eigene Aufgaben
            Section(header:
                HStack {
                    Text("Meine Aufgaben")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        showPersonalTaskSheet = true
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
                                    showGroupTaskSheetForGroup = group
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
/*
        // MARK: - Sheet eigene Aufgabe
        .sheet(isPresented: $showPersonalTaskSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Neue persönliche Aufgabe")) {
                        TextField("Titel", text: $newTaskTitle)
                    }
                    Section(header: Text("Intervall")) {
                        TaskIntervalPicker(selectedInterval: $selectedInterval)
                    }

                }
                .navigationTitle("Eigene Aufgabe")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            newTaskTitle = ""
                            showPersonalTaskSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Hinzufügen") {
                            Task {
                                await taskViewModel.addPersonalTask(title: newTaskTitle)
                                try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                                newTaskTitle = ""
                                showPersonalTaskSheet = false
                            }
                        }
                        .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }

        // MARK: - Sheet Gruppenaufgabe
        .sheet(item: $showGroupTaskSheetForGroup) { group in
            NavigationView {
                Form {
                    Section(header: Text("Neue Aufgabe für \(group.name)")) {
                        TextField("Titel", text: $newTaskTitle)
                    }
                    Section(header: Text("Intervall")) {
                        TaskIntervalPicker(selectedInterval: $selectedInterval)
                    
                    }

                }
                .navigationTitle("Gruppenaufgabe")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            newTaskTitle = ""
                            showGroupTaskSheetForGroup = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Hinzufügen") {
                            Task {
                                await taskViewModel.addGroupTask(title: newTaskTitle, group: group)
                                try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                                newTaskTitle = ""
                                showGroupTaskSheetForGroup = nil
                            }
                        }
                        .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
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

