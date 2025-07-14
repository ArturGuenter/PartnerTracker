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
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    EditTaskSheet(task: <#TaskItem#>, onSave: <#(String) -> Void#>)
}
