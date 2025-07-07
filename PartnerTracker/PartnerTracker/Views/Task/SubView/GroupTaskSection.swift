//
//  GroupTaskSection.swift
//  PartnerTracker
//
//  Created by Artur Günter on 07.07.25.
//

import SwiftUI

struct GroupTaskSection: View {
    let group: Group
    let tasks: [TaskItem]
    let onAddTapped: () -> Void
    let onToggleDone: (TaskItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Gruppe: \(group.name)")
                    .font(.subheadline)
                    .bold()
                Spacer()
                Button(action: onAddTapped) {
                    Label("Neue Aufgabe", systemImage: "plus.circle")
                }
            }
            .padding(.horizontal)

            if tasks.isEmpty {
                Text("Keine Aufgaben in dieser Gruppe.")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            } else {
                ForEach(tasks) { task in
                    HStack {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isDone ? .green : .gray)
                            .onTapGesture {
                                onToggleDone(task)
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
                }
            }
        }
    }
}

#Preview {
    GroupTaskSection()
}
