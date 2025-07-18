//
//  TaskSheetType.swift
//  PartnerTracker
//
//  Created by Artur Günter on 18.07.25.
//

import Foundation

enum TaskSheetType: Identifiable {
    case personal(selectedInterval: TaskResetInterval)
    case group(Group, selectedInterval: TaskResetInterval)
    case edit(TaskItem)

    var id: String {
        switch self {
        case .personal:
            return "personal"
        case .group(let group, _):
            return "group_\(group.id)"
        case .edit(let task):
            return "edit_\(task.id)"
        }
    }
}

