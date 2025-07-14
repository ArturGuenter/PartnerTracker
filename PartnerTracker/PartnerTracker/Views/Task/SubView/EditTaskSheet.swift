//
//  EditTaskSheet.swift
//  PartnerTracker
//
//  Created by Artur Günter on 14.07.25.
//

import SwiftUI

struct EditTaskSheet: View {
    
    @State var task: TaskItem
    @State private var updatedTitle: String
        var onSave: (String) -> Void

        init(task: TaskItem, onSave: @escaping (String) -> Void) {
            self.task = task
            self.onSave = onSave
            _updatedTitle = State(initialValue: task.title)
        }
    
    var body: some View {
        NavigationStack {
                   Form {
                       Section(header: Text("Aufgabe bearbeiten")) {
                           TextField("Titel", text: $updatedTitle)
                       }
                   }
                   .navigationTitle("Bearbeiten")
                   .toolbar {
                       ToolbarItem(placement: .cancellationAction) {
                           Button("Abbrechen") {
                               onSave(task.title)
                           }
                       }
                       ToolbarItem(placement: .confirmationAction) {
                           Button("Speichern") {
                               onSave(updatedTitle)
                           }
                           .disabled(updatedTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                       }
                   }
               }
    }
}

#Preview {
    EditTaskSheet(task: <#TaskItem#>, onSave: <#(String) -> Void#>)
}
