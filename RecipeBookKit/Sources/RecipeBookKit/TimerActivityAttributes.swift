import ActivityKit
import Foundation

public struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var endTime: Date
        public var progress: Double
        public var isPaused: Bool
        
        public init(endTime: Date, progress: Double, isPaused: Bool) {
            self.endTime = endTime
            self.progress = progress
            self.isPaused = isPaused
        }
    }
    
    public let recipeName: String
    public let stepNumber: Int
    public let stepDescription: String
    public let duration: TimeInterval
    
    public init(recipeName: String, stepNumber: Int, stepDescription: String, duration: TimeInterval) {
        self.recipeName = recipeName
        self.stepNumber = stepNumber
        self.stepDescription = stepDescription
        self.duration = duration
    }
} 