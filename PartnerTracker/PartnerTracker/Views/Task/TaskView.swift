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
                if !taskViewModel.personalTasks.isEmpty {
                    Text("Meine Aufgaben")
                        .font(.headline)
                        .padding(.horizontal)

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

                // Aufgaben aus Gruppen
                ForEach(taskViewModel.groupedTasks.sorted(by: { $0.key < $1.key }), id: \.key) { groupName, tasks in
                    Text("Gruppe: \(groupName)")
                        .font(.headline)
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

                Spacer(minLength: 40)
            }
        }
        .onAppear {
            Task {
                try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
            }
        }
    }
}

#Preview {
    TaskView(
        taskViewModel: TaskViewModel(),
        groupViewModel: GroupViewModel()
    )
}

