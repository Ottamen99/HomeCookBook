import SwiftUI

struct TimerView: View {
    @StateObject var viewModel: TimerViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Timer display
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text(viewModel.displayTime)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
            }
            .frame(width: 150, height: 150)
            .padding()
            
            // Controls
            HStack(spacing: 20) {
                Button {
                    if viewModel.isRunning {
                        viewModel.pause()
                    } else {
                        viewModel.start()
                    }
                } label: {
                    Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                
                Button {
                    viewModel.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .frame(width: 44, height: 44)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
} 