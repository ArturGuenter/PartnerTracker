//
//  EditTaskSheet.swift
//  PartnerTracker
//
//  Created by Artur Günter on 14.07.25.
//

import SwiftUI

struct EditTaskSheetWithInterval: View {
    let task: TaskItem
    @State private var updatedTitle: String
    @State private var updatedInterval: TaskResetInterval

    var onSave: (String, TaskResetInterval) -> Void
    var onCancel: () -> Void

    init(task: TaskItem,
         onSave: @escaping (String, TaskResetInterval) -> Void,
         onCancel: @escaping () -> Void) {
        self.task = task
        self.onSave = onSave
        self.onCancel = onCancel
        _updatedTitle = State(initialValue: task.title)
        _updatedInterval = State(initialValue: task.resetInterval)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Titel")) {
                    TextField("Titel", text: $updatedTitle)
                }
                Section(header: Text("Intervall")) {
                    Picker("Intervall", selection: $updatedInterval) {
                        ForEach(TaskResetInterval.allCases, id: \.self) { interval in
                            Text(interval.rawValue.capitalized).tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Aufgabe bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave(updatedTitle, updatedInterval)
                    }
                    .disabled(updatedTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}



