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
        _viewModel = StateObject(wrappedValue: RecipeViewModel(viewContext: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        TabView {
            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
            
            IngredientsView()
                .tabItem {
                    Label("Ingredients", systemImage: "leaf")
                }
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
