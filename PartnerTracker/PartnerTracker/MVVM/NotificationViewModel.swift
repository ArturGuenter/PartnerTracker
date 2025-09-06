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
    
    private func sendLocalNotification(for group: Group) async {
           let content = UNMutableNotificationContent()
           content.title = "Gruppe erledigt 🎉"
           content.body = "Alle Aufgaben in der Gruppe „\(group.name)“ sind abgeschlossen."
           content.sound = .default

           let request = UNNotificationRequest(
               identifier: UUID().uuidString,
               content: content,
               trigger: nil
           )

           do {
               try await UNUserNotificationCenter.current().add(request)
               print("Benachrichtigung gesendet für Gruppe \(group.name)")
           } catch {
               print("Fehler beim Senden der Benachrichtigung: \(error.localizedDescription)")
           }
       }
    
    
    private func requestAuthorization() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Fehler bei Benachrichtigungs-Erlaubnis: \(error)")
                } else {
                    print("Benachrichtigungen erlaubt: \(granted)")
                }
            }
        }
    
    
}
