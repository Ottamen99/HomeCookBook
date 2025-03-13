//
//  ContentView.swift
//  RecipeBook
//
//  Created by Ottavio Buonomo on 11.02.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: RecipeViewModel
    
    init() {
        // Initialize the view model
        _viewModel = StateObject(wrappedValue: RecipeViewModel(viewContext: PersistenceController.shared.container.viewContext))
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = .orange
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.orange]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                RecipesView()
            }
            .tabItem {
                Label("Recipes", systemImage: "book")
            }

            NavigationStack {
                RecipeBooksGridView()
            }
            .tabItem {
                Label("Recipe Books", systemImage: "books.vertical.fill")
            }

            /*NavigationStack {
                PantryView()
            }
            .tabItem {
                Label("My Pantry", systemImage: "basket.fill")
            }*/
            
            NavigationStack {
                IngredientsListView()
            }
            .tabItem {
                Label("Ingredients", systemImage: "leaf")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
