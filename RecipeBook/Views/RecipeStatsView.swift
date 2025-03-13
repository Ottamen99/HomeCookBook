import SwiftUI
#if canImport(Charts)
import Charts
#endif
import CoreData

struct RecipeStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.name, ascending: true)],
        animation: .default)
    private var recipes: FetchedResults<Recipe>
    
    @State private var selectedChart: ChartType = .cookingTime
    
    enum ChartType: String, CaseIterable, Identifiable {
        case cookingTime = "Cooking Time"
        case ingredientCount = "Ingredient Count"
        case difficultyDistribution = "Difficulty"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Chart Type", selection: $selectedChart) {
                    ForEach(ChartType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if #available(iOS 16.0, *) {
                    switch selectedChart {
                    case .cookingTime:
                        cookingTimeChart
                    case .ingredientCount:
                        ingredientCountChart
                    case .difficultyDistribution:
                        difficultyChart
                    }
                } else {
                    // Fallback for iOS 15 and earlier
                    legacyStatsView
                }
                
                Text("Statistics Summary")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    statRow(title: "Total Recipes", value: "\(recipes.count)")
                    
                    let avgTimeFormatted = String(format: "%.0f", averageCookingTime)
                    statRow(title: "Avg. Cooking Time", value: "\(avgTimeFormatted) min")
                    
                    let avgIngredientsFormatted = String(format: "%.1f", averageIngredientCount)
                    statRow(title: "Avg. Ingredients", value: "\(avgIngredientsFormatted)")
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Recipe Statistics")
    }
    
    @available(iOS 16.0, *)
    var cookingTimeChart: some View {
        #if canImport(Charts)
        Chart {
            ForEach(recipesForChart, id: \.id) { recipe in
                BarMark(
                    x: .value("Recipe", recipe.name ?? "Unnamed"),
                    y: .value("Time (min)", recipe.timeInMinutes)
                )
                .foregroundStyle(Color.orange.gradient)
                .annotation(position: .top) {
                    Text("\(recipe.timeInMinutes)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 300)
        .padding()
        .chartXAxis {
            AxisMarks(preset: .aligned) { _ in
                AxisValueLabel(collisionResolution: .greedy)
                    .font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    Text("\(value.as(Int.self) ?? 0) min")
                        .font(.caption)
                }
            }
        }
        #else
        EmptyView()
        #endif
    }
    
    @available(iOS 16.0, *)
    var ingredientCountChart: some View {
        #if canImport(Charts)
        // Break down complex expression
        let chartData = recipesForChart.map { recipe in
            (
                name: recipe.name ?? "Unnamed",
                count: getIngredientCount(for: recipe)
            )
        }
        
        return Chart {
            ForEach(chartData, id: \.name) { item in
                BarMark(
                    x: .value("Recipe", item.name),
                    y: .value("Ingredients", item.count)
                )
                .foregroundStyle(Color.green.gradient)
                .annotation(position: .top) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: 300)
        .padding()
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel(collisionResolution: .greedy)
                    .font(.caption)
            }
        }
        #else
        EmptyView()
        #endif
    }
    
    @available(iOS 16.0, *)
    var difficultyChart: some View {
        #if canImport(Charts)
        let difficultyData = difficultyDistribution
        
        // Break down complex expression
        let chartContent = Chart(difficultyData, id: \.key) { item in
            SectorMark(
                angle: .value("Count", item.value),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .cornerRadius(5)
            .foregroundStyle(by: .value("Category", item.key))
            .annotation(position: .overlay) {
                Text("\(item.value)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
        
        return chartContent
            .frame(height: 300)
            .padding()
            .chartForegroundStyleScale([
                "Easy": .green,
                "Medium": .orange,
                "Hard": .red,
                "Unknown": .gray
            ])
        #else
        EmptyView()
        #endif
    }
    
    // Legacy view for iOS 15 and earlier
    var legacyStatsView: some View {
        VStack(spacing: 15) {
            Text("Charts require iOS 16 or later")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            
            // Simple bar representation for recipe times
            if selectedChart == .cookingTime {
                VStack(spacing: 8) {
                    ForEach(recipesForChart.prefix(5), id: \.id) { recipe in
                        HStack {
                            Text(recipe.name ?? "Unnamed")
                                .font(.caption)
                                .frame(width: 100, alignment: .leading)
                            
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: CGFloat(recipe.timeInMinutes) * 1.5, height: 20)
                            
                            Text("\(recipe.timeInMinutes) min")
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }
            
            // Simple bar representation for ingredient counts
            else if selectedChart == .ingredientCount {
                VStack(spacing: 8) {
                    ForEach(recipesForChart.prefix(5), id: \.id) { recipe in
                        let count = getIngredientCount(for: recipe)
                        HStack {
                            Text(recipe.name ?? "Unnamed")
                                .font(.caption)
                                .frame(width: 100, alignment: .leading)
                            
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: CGFloat(count) * 15, height: 20)
                            
                            Text("\(count)")
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }
            
            // Simple representation for difficulty
            else if selectedChart == .difficultyDistribution {
                HStack(spacing: 15) {
                    ForEach(difficultyDistribution, id: \.key) { item in
                        VStack {
                            Circle()
                                .fill(difficultyColor(for: item.key))
                                .frame(height: CGFloat(item.value) * 10 + 30)
                            Text(item.key)
                                .font(.caption)
                            Text("\(item.value)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(height: 300)
    }
    
    // Helper function to get ingredient count for a recipe
    private func getIngredientCount(for recipe: Recipe) -> Int {
        return (recipe.recipeIngredients as? Set<RecipeIngredient>)?.count ?? 0
    }
    
    var recipesForChart: [Recipe] {
        // Limit to top 10 by cooking time for better visualization
        let sorted = recipes.sorted { 
            ($0.timeInMinutes) > ($1.timeInMinutes)
        }
        return Array(sorted.prefix(10))
    }
    
    var difficultyDistribution: [ChartDataItem] {
        var counts: [String: Int] = ["Easy": 0, "Medium": 0, "Hard": 0, "Unknown": 0]
        
        for recipe in recipes {
            if let difficulty = recipe.difficulty {
                counts[difficulty, default: 0] += 1
            } else {
                counts["Unknown", default: 0] += 1
            }
        }
        
        return counts.map { ChartDataItem(key: $0.key, value: $0.value) }
    }
    
    var averageCookingTime: Double {
        guard !recipes.isEmpty else { return 0 }
        let total = recipes.reduce(0) { $0 + $1.timeInMinutes }
        return Double(total) / Double(recipes.count)
    }
    
    var averageIngredientCount: Double {
        guard !recipes.isEmpty else { return 0 }
        let total = recipes.reduce(0) { $0 + getIngredientCount(for: $1) }
        return Double(total) / Double(recipes.count)
    }
    
    func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
    
    func difficultyColor(for key: String) -> Color {
        switch key {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .gray
        }
    }
}

struct ChartDataItem: Identifiable {
    var key: String
    var value: Int
    var id: String { key }
}

#Preview {
    NavigationStack {
        RecipeStatsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 