//
//  Group.swift
//  PartnerTracker
//
//  Created by Artur Günter on 24.06.25.
//

import Foundation
import FirebaseFirestore

struct Group: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var memberIds: [String]
    var createdAt: Date?
    var password: String 
}
