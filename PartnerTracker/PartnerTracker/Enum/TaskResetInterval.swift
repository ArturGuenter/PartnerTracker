//
//  TaskResetInterval.swift
//  PartnerTracker
//
//  Created by Artur Günter on 16.07.25.
//

import Foundation

enum TaskResetInterval: String, CaseIterable, Codable, Identifiable {
    case daily
    case weekly
    case monthly
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "Täglich"
        case .weekly: return "Wöchentlich"
        case .monthly: return "Monatlich"
        }
    }
}

