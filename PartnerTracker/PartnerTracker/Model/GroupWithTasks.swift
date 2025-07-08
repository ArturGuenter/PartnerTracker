//
//  GroupWithTasks.swift
//  PartnerTracker
//
//  Created by Artur Günter on 08.07.25.
//

import Foundation

struct GroupWithTasks: Identifiable {
    let group: Group
    let tasks: [TaskItem]
    
    var id: String { group.id }
}
