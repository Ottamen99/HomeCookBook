import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endTime: Date
        var progress: Double
    }
    
    let recipeName: String
    let stepNumber: Int
    let stepDescription: String
    let duration: TimeInterval
} 