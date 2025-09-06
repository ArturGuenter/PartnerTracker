//
//  NotificationViewModel.swift
//  PartnerTracker
//
//  Created by Artur Günter on 24.06.25.
//

import Foundation
import UserNotifications

@MainActor
class NotificationViewModel: ObservableObject {
    private var debounceTimers: [String: Task<Void, Never>] = [:]
    
}
