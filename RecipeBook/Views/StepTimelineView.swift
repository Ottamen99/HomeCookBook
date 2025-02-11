import SwiftUI

struct StepTimelineView: View {
    let step: Step
    let isCompleted: Bool
    let isActive: Bool
    let isFirst: Bool
    let isLast: Bool
    let onToggleComplete: (Bool) -> Void
    
    let canComplete: Bool
    
    private var timelineColor: Color {
        isCompleted ? .green : (isActive ? .blue : .gray)
    }
    
    private var circleStrokeColor: Color {
        if !canComplete && !isCompleted {
            return .gray.opacity(0.3)
        }
        return isCompleted ? .green : (isActive ? .blue : .gray)
    }
    
    private var circleFillColor: Color {
        if isCompleted {
            return .green
        } else if isActive && canComplete {
            return .blue.opacity(0.1)
        } else {
            return .white
        }
    }
    
    private var shadowColor: Color {
        if !canComplete && !isCompleted {
            return .clear
        }
        if isCompleted {
            return .green
        } else if isActive {
            return .blue
        } else {
            return .clear
        }
    }
    
    var body: some View {
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
                    .stroke(circleStrokeColor, lineWidth: 2)
                    .background(Circle().fill(circleFillColor))
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
                    .shadow(color: shadowColor.opacity(0.3), radius: 4)
                
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
                
                if let duration = StepDuration.detect(in: step.instructions ?? "") {
                    Button {
                        startNativeTimer(duration: duration)
                    } label: {
                        Label("\(duration.formattedString) timer", systemImage: "timer")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                if canComplete || isCompleted {
                    onToggleComplete(!isCompleted)
                }
            }
        }
        .background(isActive && canComplete ? Color.blue.opacity(0.05) : Color.clear)
        .cornerRadius(8)
    }
    
    private func startNativeTimer(duration: StepDuration) {
        var components = URLComponents()
        components.scheme = "x-apple-timer"
        components.queryItems = [
            URLQueryItem(name: "minutes", value: String(duration.totalSeconds / 60))
        ]
        
        if let url = components.url {
            UIApplication.shared.open(url) { success in
                if !success {
                    if let clockURL = URL(string: "clock:") {
                        UIApplication.shared.open(clockURL)
                    }
                }
            }
        }
    }
} 