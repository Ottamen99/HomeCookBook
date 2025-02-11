//
//  RecipeBookApp.swift
//  RecipeBook
//
//  Created by Ottavio Buonomo on 11.02.2025.
//

import SwiftUI
import UserNotifications

@main
struct RecipeBookApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
