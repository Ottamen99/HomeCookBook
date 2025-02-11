import ActivityKit
import SwiftUI
import WidgetKit
import RecipeBookKit

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                
                VStack(spacing: 12) {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.attributes.recipeName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Step \(context.attributes.stepNumber + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Timer display
                        VStack(alignment: .trailing, spacing: 4) {
                            if context.state.isPaused {
                                Label("Paused", systemImage: "pause.circle.fill")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(.orange)
                            } else {
                                Text(timerInterval: Date()...context.state.endTime)
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    
                    // Step description
                    if !context.attributes.stepDescription.isEmpty {
                        Text(context.attributes.stepDescription)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Progress bar
                    VStack(spacing: 8) {
                        ProgressView(value: context.state.progress)
                            .tint(context.state.isPaused ? .orange : .green)
                        
                        // Progress percentage
                        HStack {
                            Text("\(Int(context.state.progress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if !context.state.isPaused {
                                Text("Remaining")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .activitySystemActionForegroundColor(.black)
            .activityBackgroundTint(Color.cyan.opacity(0.2))
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.center) {
                    HStack {
                        Label {
                            Text(context.attributes.recipeName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "timer")
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Text(timerInterval: Date()...context.state.endTime)
                            .monospacedDigit()
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(context.state.isPaused ? .orange : .green)
                }
            } compactLeading: {
                Label {
                    Text(timerInterval: Date()...context.state.endTime)
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "timer")
                        .foregroundStyle(.primary)
                }
            } compactTrailing: {
                Text(context.attributes.recipeName)
                    .foregroundStyle(.secondary)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.primary)
            }
        }
    }
}

#Preview("Dynamic Island", as: .dynamicIsland(.expanded), using: TimerActivityAttributes(
    recipeName: "Test Recipe",
    stepNumber: 1,
    stepDescription: "Test description",
    duration: 300
)) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(endTime: Date().addingTimeInterval(300), progress: 0.5, isPaused: false)
    TimerActivityAttributes.ContentState(endTime: Date().addingTimeInterval(300), progress: 0.5, isPaused: true)
}

#Preview("Lock Screen", using: TimerActivityAttributes(
    recipeName: "Chocolate Cake",
    stepNumber: 2,
    stepDescription: "Mix the dry ingredients together in a large bowl: flour, cocoa powder, sugar, baking powder, and salt.",
    duration: 300
)) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(
        endTime: Date().addingTimeInterval(300),
        progress: 0.65,
        isPaused: false
    )
    TimerActivityAttributes.ContentState(
        endTime: Date().addingTimeInterval(300),
        progress: 0.65,
        isPaused: true
    )
} 