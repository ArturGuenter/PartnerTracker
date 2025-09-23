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
    @State private var sortByInterval = false

    var body: some View {
        NavigationStack {
            listContent
                .listStyle(.insetGrouped)
                .navigationTitle("Aufgaben")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear(perform: loadData)
                .sheet(item: $activeSheet) { sheet in sheetView(for: sheet) }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            sortByInterval.toggle()
                        } label: {
                            Image(systemName: sortByInterval ? "list.bullet" : "line.3.horizontal.decrease.circle")
                        }
                    }
                }
        }
    }
    
    // MARK: - Haupt-Liste aufgeteilt
    @ViewBuilder
    private var listContent: some View {
        if sortByInterval {
            sortedByIntervalView
        } else {
            sortedByGroupView
        }
    }
    
    // MARK: - Nach Intervall sortierte Ansicht
    private var sortedByIntervalView: some View {
        List {
            ForEach(TaskResetInterval.allCases, id: \.self) { interval in
                intervalSection(interval)
            }
        }
    }
    
    // MARK: - Nach Gruppen sortierte Ansicht
    private var sortedByGroupView: some View {
        List {
            personalTasksByInterval
            groupTasksByGroup
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
            password: "1234",
            ownerId: "123"
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

