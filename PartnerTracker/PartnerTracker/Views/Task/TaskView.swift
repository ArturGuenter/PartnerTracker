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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Eigene Aufgaben
                VStack(alignment: .leading, spacing: 12) {
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
                    .padding(.horizontal)

                    if taskViewModel.personalTasks.isEmpty {
                        Text("Noch keine eigenen Aufgaben.")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        LazyVStack(spacing: 8) {
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
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
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
                }

                // MARK: - Gruppenaufgaben
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gruppenaufgaben")
                        .font(.headline)
                        .padding(.horizontal)

                    if groupViewModel.groups.isEmpty {
                        Text("Du bist noch keiner Gruppe beigetreten.")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        ForEach(groupViewModel.groups) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(group.name)
                                        .font(.subheadline)
                                        .bold()
                                    Spacer()
                                    Button(action: {
                                        showGroupTaskSheetForGroup = group
                                    }) {
                                        Image(systemName: "plus.circle")
                                    }
                                }
                                .padding(.horizontal)

                                ForEach(taskViewModel.groupedTasks[group.name] ?? []) { task in
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
                                    }
                                    .padding()
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
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

                Spacer(minLength: 40)
            }
        }
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

        // MARK: - Sheet für eigene Aufgabe
        .sheet(isPresented: $showPersonalTaskSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Neue persönliche Aufgabe")) {
                        TextField("Titel", text: $newTaskTitle)
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

        // MARK: - Sheet für Gruppenaufgabe
        .sheet(item: $showGroupTaskSheetForGroup) { group in
            NavigationView {
                Form {
                    Section(header: Text("Neue Aufgabe für \(group.name)")) {
                        TextField("Titel", text: $newTaskTitle)
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
            createdAt: Date()
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
                createdAt: Date()
            )
        ]
    ]

    return TaskView(
        taskViewModel: taskVM,
        groupViewModel: groupVM
    )
}
