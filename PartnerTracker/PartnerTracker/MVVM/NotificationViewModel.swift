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
    
    init() {
            requestAuthorization()
        }

        
        func handleGroupStatusChange(group: Group, tasks: [TaskItem]) {
            let allDone = tasks.allSatisfy { !$0.completedBy.isEmpty }

            if allDone {
                debounceTimers[group.id]?.cancel()
                debounceTimers[group.id] = Task {
                    try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)

                    
                    let stillAllDone = tasks.allSatisfy { !$0.completedBy.isEmpty }
                    if stillAllDone {
                        await self.sendLocalNotification(for: group)
                    }
                }
            } else {
                
                debounceTimers[group.id]?.cancel()
                debounceTimers[group.id] = nil
            }
        }
    
}
