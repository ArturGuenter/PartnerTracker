//
//  TaskItem.swift
//  PartnerTracker
//
//  Created by Artur Günter on 03.07.25.
//

import Foundation
struct TaskItem: Identifiable, Codable {
    var id: String
    var title: String
    var isDone: Bool
    var ownerId: String?
    var groupId: String?
    let createdAt: Date
}
