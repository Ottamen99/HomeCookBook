//
//  RecipeBookApp.swift
//  RecipeBook
//
//  Created by Ottavio Buonomo on 11.02.2025.
//

import SwiftUI
import UserNotifications
import ActivityKit

@main
struct RecipeBookApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // Request notifications permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        
        // Request Live Activities permission if available
        if #available(iOS 16.1, *) {
            Task {
                let authorized = ActivityAuthorizationInfo().areActivitiesEnabled
                print("Live Activities authorized: \(authorized)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
