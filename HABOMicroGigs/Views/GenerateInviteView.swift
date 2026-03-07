import SwiftUI
import Combine

struct GenerateInviteView: View {
    let circle: Circle
    
    @State private var inviteCode: String = "--------"
    @State private var timeRemaining: Double = 45.0
    @State private var isLoading: Bool = true
    
    // The SwiftUI Timer publisher that ticks every 1 second
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 30) {
            Text("Invite to \(circle.name)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Share this secure code with someone you trust. It expires in 45 seconds.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                ZStack {
                    // Background Track
                    CircleShape()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 200, height: 200)

                    // Animated Countdown Ring
                    CircleShape()
                        .trim(from: 0, to: timeRemaining / 45.0)
                        .stroke(
                            timeRemaining > 10 ? Color.blue : Color.red,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)

                    // The Code
                    VStack {
                        Text(inviteCode)
                            .font(.system(size: 36, design: .monospaced))
                            .fontWeight(.bold)
                            .tracking(5)
                        
                        Text("\(Int(timeRemaining))s")
                            .font(.headline)
                            .foregroundColor(timeRemaining > 10 ? .secondary : .red)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                await fetchNewCode()
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 && !isLoading {
                timeRemaining -= 1
            } else if timeRemaining <= 0 && !isLoading {
                // Code expired! Fetch the next one.
                Task {
                    await fetchNewCode()
                }
            }
        }
    }
    
    // Helper shape to make the ring
    struct CircleShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.addEllipse(in: rect)
            return path
        }
    }
    
    private func fetchNewCode() async {
        isLoading = true
        do {
            let response = try await APIClient.shared.getInviteCode(circleId: circle.id.uuidString)
            self.inviteCode = response.code
            self.timeRemaining = Double(response.expiresInSeconds) // Matches the new camelCase we added to APIModels
            self.isLoading = false
        } catch {
            print("Failed to fetch invite code: \(error)")
        }
    }
}
