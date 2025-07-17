//
//  TaskResetInterval.swift
//  PartnerTracker
//
//  Created by Artur Günter on 16.07.25.
//

import Foundation

enum TaskResetInterval: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    
    var id: String { rawValue }
}
