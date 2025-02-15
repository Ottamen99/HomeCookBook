import SwiftUI
import UserNotifications
import ActivityKit
import RecipeBookKit

// Make the view public
public struct StepTimelineView: View {
    let recipe: Recipe
    let step: Step
    let isCompleted: Bool
    let isActive: Bool
    let isFirst: Bool
    let isLast: Bool
    let onToggleComplete: (Bool) -> Void
    let canComplete: Bool
    
    private var timerButton: some View {
        let instructions = step.instructions ?? ""
        
        return Group {
            if let duration = StepDuration.detect(in: instructions) {
                StepTimerView(recipe: recipe, step: step, duration: duration)
                    .padding(.top, 4)
            }
        }
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 20)
                }
                
                Circle()
                    .stroke(isCompleted ? .green : (isActive ? .blue : .gray), lineWidth: 2)
                    .background(Circle().fill(isCompleted ? .green : (isActive ? .blue : .gray)))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .bold))
                        } else if isActive {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .shadow(color: .clear, radius: 4)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 20)
                }
            }
            
            // Step content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Step \(step.order + 1)")
                        .font(.headline)
                        .foregroundColor(isCompleted ? .green : (canComplete ? .blue : .gray))
                    
                    Spacer()
                    
                    if canComplete || isCompleted {
                        Button {
                            onToggleComplete(!isCompleted)
                        } label: {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isCompleted ? .green : .gray)
                                .font(.system(size: 24))
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                }
                
                Text(step.instructions ?? "")
                    .foregroundColor(isCompleted ? .secondary : (canComplete ? .primary : .gray))
                
                if let ingredients = step.ingredients as? Set<RecipeIngredient>, !ingredients.isEmpty {
                    Text("Uses: " + ingredients.compactMap { $0.ingredient?.name }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                timerButton
            }
            .padding(.bottom, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                if canComplete || isCompleted {
                    onToggleComplete(!isCompleted)
                }
            }
            .onAppear {
                #if DEBUG
                if StepDuration.detect(in: step.instructions ?? "") == nil {
                    print("No duration detected in step \(step.order + 1): \(step.instructions ?? "")")
                }
                #endif
            }
        }
        .background(isActive && canComplete ? Color.blue.opacity(0.05) : Color.clear)
        .cornerRadius(8)
    }
}

private struct StepTimerView: View {
    let recipe: Recipe
    let step: Step
    let duration: StepDuration
    
    @State private var timeRemaining: TimeInterval
    @State private var isRunning = false
    @State private var activity: Activity<TimerActivityAttributes>?
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    init(recipe: Recipe, step: Step, duration: StepDuration) {
        self.recipe = recipe
        self.step = step
        self.duration = duration
        _timeRemaining = State(initialValue: TimeInterval(duration.totalSeconds))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if isRunning {
                    pauseTimer()
                } else {
                    startTimer()
                }
            } label: {
                HStack {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .foregroundColor(timeRemaining > 0 ? .blue : .green)
                    
                    Text(formatTime(timeRemaining))
                        .monospacedDigit()
                        .foregroundColor(timeRemaining > 0 ? .blue : .green)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .disabled(timeRemaining <= 0)
            
            if timeRemaining < TimeInterval(duration.totalSeconds) {
                Button {
                    resetTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if timeRemaining > 0 {
                timeRemaining -= 0.1
                updateLiveActivity()
                
                if timeRemaining <= 0 {
                    stopTimer()
                    notifyTimerComplete()
                }
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        startLiveActivity()
    }
    
    private func pauseTimer() {
        isRunning = false
        updateLiveActivity()
    }
    
    private func stopTimer() {
        isRunning = false
        endLiveActivity()
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = TimeInterval(duration.totalSeconds)
    }
    
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = TimerActivityAttributes(
            recipeName: recipe.name ?? "",
            stepNumber: Int(step.order),
            stepDescription: step.instructions ?? "",
            duration: TimeInterval(duration.totalSeconds)
        )
        
        let initialContent = ActivityContent(
            state: TimerActivityAttributes.ContentState(
                endTime: Date().addingTimeInterval(timeRemaining),
                progress: 1 - (timeRemaining / TimeInterval(duration.totalSeconds)),
                isPaused: false
            ),
            staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        )
        
        Task {
            do {
                activity = try Activity.request(
                    attributes: attributes,
                    content: initialContent
                )
            } catch {
                print("Error starting live activity: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateLiveActivity() {
        Task {
            let content = ActivityContent(
                state: TimerActivityAttributes.ContentState(
                    endTime: Date().addingTimeInterval(timeRemaining),
                    progress: 1 - (timeRemaining / TimeInterval(duration.totalSeconds)),
                    isPaused: !isRunning
                ),
                staleDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            )
            
            await activity?.update(content)
        }
    }
    
    private func endLiveActivity() {
        Task {
            await activity?.end(
                ActivityContent(
                    state: TimerActivityAttributes.ContentState(
                        endTime: Date(),
                        progress: 1.0,
                        isPaused: false
                    ),
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
            activity = nil
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "Done!"
        }
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func notifyTimerComplete() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "The timer for \(duration.formattedString) has finished"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
} 
