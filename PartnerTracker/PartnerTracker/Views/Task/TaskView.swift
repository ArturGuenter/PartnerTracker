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
    @State private var showGroupTaskSheetForGroupId: String?
    @State private var newTaskTitle = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // "Meine Aufgaben"
                Text("Meine Aufgaben")
                    .font(.headline)
                    .padding(.horizontal)

                if taskViewModel.personalTasks.isEmpty {
                    Text("Noch keine eigenen Aufgaben.")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
                    ForEach(taskViewModel.personalTasks) { task in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isDone ? .green : .gray)
                                Text(task.title)
                                    .strikethrough(task.isDone)
                                    .foregroundColor(task.isDone ? .gray : .primary)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }

                // "Gruppenaufgaben"
                Text("Gruppenaufgaben")
                    .font(.headline)
                    .padding(.horizontal)

                if groupViewModel.groups.isEmpty {
                    Text("Du bist noch keiner Gruppe beigetreten.")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                } else {
                    ForEach(groupViewModel.groups) { group in
                        if let tasks = taskViewModel.groupedTasks[group.name], !tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gruppe: \(group.name)")
                                    .font(.subheadline)
                                    .bold()
                                    .padding(.horizontal)

                                ForEach(tasks) { task in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(task.isDone ? .green : .gray)
                                            Text(task.title)
                                                .strikethrough(task.isDone)
                                                .foregroundColor(task.isDone ? .gray : .primary)
                                            Spacer()
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                        } else {
                            Text("Gruppe: \(group.name) – Keine Aufgaben")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .onAppear {
            Task {
                do {
                    try await groupViewModel.fetchGroupsForCurrentUser()
                    try await taskViewModel.addDefaultTaskIfNeeded()
                    try await taskViewModel.fetchTasks(groups: groupViewModel.groups)
                } catch {
                    print("Fehler beim Laden: \(error.localizedDescription)")
                }
            }
        }
    }
}



#Preview {
    let taskVM = TaskViewModel()
    let groupVM = GroupViewModel()

    // Beispielaufgabe (persönlich)
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

    // Beispielgruppe mit Passwort
    groupVM.groups = [
        Group(
            id: "g1",
            name: "Projekt X",
            memberIds: ["demo"],
            createdAt: Date(),
            password: "1234"
        )
    ]

    // Beispielaufgabe in Gruppe
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



