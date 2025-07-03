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
            VStack(alignment: .leading, spacing: 16) {

                // Eigene Aufgaben
                if !taskViewModel.personalTasks.isEmpty {
                    Text("Meine Aufgaben")
                        .font(.headline)

                    ForEach(taskViewModel.personalTasks) { task in
                        TaskRow(task: task)
                    }
                }

                // Gruppenaufgaben
                ForEach(Array(taskViewModel.groupedTasks.keys), id: \.self) { groupName in
                    if let tasks = taskViewModel.groupedTasks[groupName] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gruppe: \(groupName)")
                                .font(.headline)

                            ForEach(tasks) { task in
                                TaskRow(task: task)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                try? await taskViewModel.fetchTasks(groups: groupViewModel.groups)
            }
        }
    }
}


#Preview {
    TaskView()
}
