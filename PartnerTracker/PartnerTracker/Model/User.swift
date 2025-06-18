//
//  User.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.06.25.
//

import Foundation

struct AppUser: Codable, Identifiable {
    var id: String
    var surname: String
    var name: String
    var email: String
    var favorites: [String] = []
}

