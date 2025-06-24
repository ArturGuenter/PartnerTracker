//
//  Group.swift
//  PartnerTracker
//
//  Created by Artur Günter on 24.06.25.
//

import Foundation

struct Group: Identifiable, Codable {
    var id: String
    var name: String
    var memberIds: [String] 
}
