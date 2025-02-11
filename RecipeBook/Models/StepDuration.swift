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
        // Match patterns like:
        // "X hours Y minutes Z seconds"
        // "X hrs Y min Z sec"
        // "X h Y m Z s"
        let pattern = #"(?:(\d+)\s*(?:hours?|hrs?|h))?\s*(?:(\d+)\s*(?:minutes?|mins?|m))?\s*(?:(\d+)\s*(?:seconds?|secs?|s))?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        // Extract hours, minutes, and seconds
        let hours = match.range(at: 1).location != NSNotFound ? 
            Int(text[Range(match.range(at: 1), in: text)!]) ?? 0 : 0
        let minutes = match.range(at: 2).location != NSNotFound ? 
            Int(text[Range(match.range(at: 2), in: text)!]) ?? 0 : 0
        let seconds = match.range(at: 3).location != NSNotFound ? 
            Int(text[Range(match.range(at: 3), in: text)!]) ?? 0 : 0
        
        // Ensure at least one value is present
        guard hours > 0 || minutes > 0 || seconds > 0 else {
            return nil
        }
        
        let fullRange = Range(match.range, in: text)!
        return StepDuration(
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            originalText: String(text[fullRange]),
            range: fullRange
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