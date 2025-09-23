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
    
    
    // MARK: - Interval Section (für sortByInterval = true)
    @ViewBuilder
    private func intervalSection(_ interval: TaskResetInterval) -> some View {
        let personalForInterval = taskViewModel.personalTasks
            .filter { $0.resetInterval == interval }
            .sortedByCreationDate()
        
        let groupedForInterval = groupedTasksByInterval(interval)
        
        if !personalForInterval.isEmpty || !groupedForInterval.isEmpty {
            Section(header: intervalHeader(interval)) {
                personalTasksInInterval(personalForInterval, interval: interval)
                groupTasksInInterval(groupedForInterval, interval: interval)
            }
            .listRowBackground(color(for: interval).opacity(0.05))
        }
    }
    
    // MARK: - Interval Header
    private func intervalHeader(_ interval: TaskResetInterval) -> some View {
        HStack {
            Text(intervalHeaderText(interval))
                .font(.headline)
                .foregroundColor(color(for: interval))
            Spacer()
            Button {
                newTaskTitle = ""
                personalTaskInterval = interval
                activeSheet = .personal
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(color(for: interval))
            }
        }
    }
    
    // MARK: - Persönliche Aufgaben in Intervall-Ansicht
    @ViewBuilder
    private func personalTasksInInterval(_ tasks: [TaskItem], interval: TaskResetInterval) -> some View {
        ForEach(tasks, id: \.id) { task in
            taskRow(task: task, group: nil, interval: interval)
        }
    }
    
    // MARK: - Gruppenaufgaben in Intervall-Ansicht
    @ViewBuilder
    private func groupTasksInInterval(_ tasks: [(task: TaskItem, group: Group)], interval: TaskResetInterval) -> some View {
        ForEach(groupViewModel.groups, id: \.id) { group in
            let tasksForGroup = tasks.filter { $0.group.id == group.id }
            if !tasksForGroup.isEmpty {
                groupHeaderInInterval(group, interval: interval)
                ForEach(tasksForGroup, id: \.task.id) { element in
                    taskRow(task: element.task, group: element.group, interval: interval)
                }
            }
        }
    }
    
    // MARK: - Gruppen-Header in Intervall-Ansicht
    private func groupHeaderInInterval(_ group: Group, interval: TaskResetInterval) -> some View {
        HStack {
            Text(group.name)
                .font(.subheadline).bold()
            Spacer()
            Button {
                newTaskTitle = ""
                groupTaskInterval = interval
                activeSheet = .group(group)
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }
    
    
    // MARK: - Hilfsfunktionen
    private func groupedTasksByInterval(_ interval: TaskResetInterval) -> [(task: TaskItem, group: Group)] {
        return groupViewModel.groups.flatMap { group in
            (taskViewModel.groupedTasks[group.name] ?? [])
                .filter { $0.resetInterval == interval }
                .map { (task: $0, group: group) }
        }.sorted { a, b in
            if a.task.createdAt == b.task.createdAt { return a.task.id < b.task.id }
            return a.task.createdAt > b.task.createdAt
        }
    }

    private func intervalHeaderText(_ interval: TaskResetInterval) -> String {
        switch interval {
        case .daily: return "Täglich"
        case .weekly: return "Wöchentlich"
        case .monthly: return "Monatlich"
        }
    }

    // MARK: - Task Row vereinfacht
    private func taskRow(task: TaskItem, group: Group?, interval: TaskResetInterval) -> some View {
        taskCard(task: task, group: group, interval: interval)
            .swipeActions {
                Button(role: .destructive) {
                    deleteTaskSafely(task)
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
    }
    
    // MARK: - Persönliche Aufgaben nach Intervallen gruppiert
    @ViewBuilder
    private var personalTasksByInterval: some View {
        ForEach(TaskResetInterval.allCases, id: \.self) { interval in
            let tasks = taskViewModel.personalTasks
                .filter { $0.resetInterval == interval }
                .sortedByCreationDate()
            
            if !tasks.isEmpty {
                Section(header: personalSectionHeader(interval)) {
                    ForEach(tasks, id: \.id) { task in
                        taskRow(task: task, group: nil, interval: interval)
                    }
                }
                .listRowBackground(color(for: interval).opacity(0.05))
            }
        }
    }

    // MARK: - Gruppenaufgaben nach Gruppen
    @ViewBuilder
    private var groupTasksByGroup: some View {
        ForEach(groupViewModel.groups, id: \.id) { group in
            Section(header: groupSectionHeader(group)) {
                let tasks = taskViewModel.groupedTasks[group.name] ?? []
                if tasks.isEmpty {
                    Text("Keine Aufgaben in dieser Gruppe.")
                        .foregroundColor(.gray)
                } else {
                    groupTasksContent(tasks, group: group)
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

