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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Eigene Aufgaben
                if !taskViewModel.ownTasks.isEmpty {
                    Text("Meine Aufgaben")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(taskViewModel.ownTasks) { task in
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

                // Gruppenaufgaben pro Gruppe
                ForEach(groupViewModel.groups) { group in
                    let tasksForGroup = taskViewModel.groupTasks.filter { $0.groupId == group.id }

                    if !tasksForGroup.isEmpty {
                        Text("Gruppe: \(group.name)")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(tasksForGroup) { task in
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
                }

                Spacer(minLength: 40)
            }
        }
        .onAppear {
            Task {
                try? await taskViewModel.fetchTasks()
            }
        }
    }
}



#Preview {
    TaskView()
}
