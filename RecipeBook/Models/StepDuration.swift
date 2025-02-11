import Foundation

struct StepDuration {
    let hours: Int
    let minutes: Int
    let seconds: Int
    let originalText: String
    let range: Range<String.Index>
    
    var totalSeconds: Int {
        hours * 3600 + minutes * 60 + seconds
    }
    
    static func detect(in text: String) -> StepDuration? {
        // Simpler pattern that's more lenient
        let patterns = [
            #"(\d+)\s*(?:hours?|hrs?|h)"#,        // hours
            #"(\d+)\s*(?:minutes?|mins?|m)"#,     // minutes
            #"(\d+)\s*(?:seconds?|secs?|s)"#      // seconds
        ]
        
        var foundHours = 0
        var foundMinutes = 0
        var foundSeconds = 0
        var foundRange: Range<String.Index>?
        
        for (index, pattern) in patterns.enumerated() {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let numberRange = Range(match.range(at: 1), in: text),
               let number = Int(text[numberRange]) {
                
                switch index {
                case 0: foundHours = number
                case 1: foundMinutes = number
                case 2: foundSeconds = number
                default: break
                }
                
                if let range = Range(match.range, in: text) {
                    if let existingRange = foundRange {
                        // Combine ranges by taking the minimum start and maximum end
                        foundRange = min(existingRange.lowerBound, range.lowerBound)..<max(existingRange.upperBound, range.upperBound)
                    } else {
                        foundRange = range
                    }
                }
            }
        }
        
        // Also try to match simple minute patterns like "X minutes"
        if foundHours == 0 && foundMinutes == 0 && foundSeconds == 0 {
            let simplePattern = #"(\d+)\s*(?:minutes?|mins?|m)"#
            if let regex = try? NSRegularExpression(pattern: simplePattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let numberRange = Range(match.range(at: 1), in: text),
               let minutes = Int(text[numberRange]) {
                foundMinutes = minutes
                foundRange = Range(match.range, in: text)
            }
        }
        
        // Return nil if no time was found
        guard (foundHours + foundMinutes + foundSeconds) > 0,
              let range = foundRange else {
            return nil
        }
        
        return StepDuration(
            hours: foundHours,
            minutes: foundMinutes,
            seconds: foundSeconds,
            originalText: String(text[range]),
            range: range
        )
    }
    
    var formattedString: String {
        var components: [String] = []
        if hours > 0 { components.append("\(hours)h") }
        if minutes > 0 { components.append("\(minutes)m") }
        if seconds > 0 { components.append("\(seconds)s") }
        return components.joined(separator: " ")
    }
} 