import Foundation

class TimerViewModel: ObservableObject {
    @Published var timeRemaining: Int
    @Published var isRunning = false
    private var timer: Timer?
    private var originalDuration: Int
    
    init(duration: Int) {
        self.timeRemaining = duration
        self.originalDuration = duration
    }
    
    var progress: Double {
        Double(timeRemaining) / Double(originalDuration)
    }
    
    var displayTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.pause()
            }
        }
    }
    
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        timeRemaining = originalDuration
        pause()
    }
    
    deinit {
        timer?.invalidate()
    }
} 