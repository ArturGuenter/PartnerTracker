//
//  User.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.06.25.
//

import Foundation
struct User: Codable, Identifiable {
    var id: UUID = UUID()
    var surname: String
    var name: String
    var email: String
}
