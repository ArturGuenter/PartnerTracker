//
//  TaskSheetView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.07.25.
//

import SwiftUI

struct TaskSheetView: View {
    var title: String
    @Binding var taskTitle: String
    @Binding var selectedInterval: TaskResetInterval
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Titel")) {
                    TextField("Titel", text: $taskTitle)
                }
                Section(header: Text("Intervall")) {
                    Picker("Wiederholen", selection: $selectedInterval) {
                        ForEach(TaskResetInterval.allCases) { interval in
                            Text(interval.rawValue.capitalized).tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen", action: onConfirm)
                        .disabled(taskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}


#Preview {
    @Previewable @State var taskTitle = "Test Aufgabe"
    @Previewable @State var interval: TaskResetInterval = .daily

    return TaskSheetView(
        title: "Neue Aufgabe",
        taskTitle: $taskTitle,
        selectedInterval: $interval,
        onCancel: {
            print("Abgebrochen")
        },
        onConfirm: {
            print("Hinzufügen gedrückt mit Titel: \(taskTitle) und Intervall: \(interval.rawValue)")
        }
    )
}

