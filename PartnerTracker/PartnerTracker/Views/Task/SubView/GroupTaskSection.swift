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
    GroupTaskSection(
        group: Group(
            id: "g1",
            name: "Projektteam Alpha",
            memberIds: ["user1", "user2"],
            createdAt: Date(),
            password: "1234"
        ),
        tasks: [
            TaskItem(
                id: "t1",
                title: "Design finalisieren",
                isDone: false,
                ownerId: "user1",
                groupId: "g1",
                createdAt: Date(),
                resetInterval: TaskResetInterval.daily,
                lastResetAt: Date()
            ),
            TaskItem(
                id: "t2",
                title: "Meeting vorbereiten",
                isDone: true,
                ownerId: "user2",
                groupId: "g1",
                createdAt: Date(),
                resetInterval: TaskResetInterval.daily,
                lastResetAt: Date()
            )
        ],
        onAddTapped: {
            print("Neue Gruppenaufgabe hinzufügen")
        },
        onToggleDone: { task in
            print("Toggle für Aufgabe: \(task.title)")
        }
    )
}

