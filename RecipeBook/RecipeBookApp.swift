//
//  RecipeBookApp.swift
//  RecipeBook
//
//  Created by Ottavio Buonomo on 11.02.2025.
//

import SwiftUI

@main
struct RecipeBookApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
