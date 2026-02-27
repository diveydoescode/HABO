// MARK: - OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    
    let accentColor = Color(red: 1.0, green: 0.45, blue: 0.0)
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack {
                // Skip Button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding()
                    .opacity(currentPage == 2 ? 0 : 1) // Hide on last page
                }
                
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        imageName: "map.circle.fill",
                        title: "Find help nearby",
                        description: "See micro-gigs and tasks posted by people in your local neighborhood right on the map.",
                        color: .blue
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        imageName: "plus.circle.fill",
                        title: "Post what you need",
                        description: "Need a hand? Post a task, set your budget, and get help from verified locals in minutes.",
                        color: accentColor
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        imageName: "indianrupeesign.circle.fill",
                        title: "Earn by helping",
                        description: "Accept tasks, complete them, and get paid securely right through the app.",
                        color: .green
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Get Started Button
                if currentPage == 2 {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Get Started")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentColor)
                            .foregroundStyle(.white)
                            .clipShape(.capsule)
                            .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    // Placeholder to keep spacing consistent
                    Color.clear.frame(height: 50).padding(.bottom, 40)
                }
            }
        }
        .animation(.easeInOut, value: currentPage)
    }
    
    private func completeOnboarding() {
        withAnimation(.spring(response: 0.5)) {
            hasSeenOnboarding = true
        }
    }
}

struct OnboardingPage: View {
    let imageName: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 160, height: 160)
                
                Image(systemName: imageName)
                    .font(.system(size: 80))
                    .foregroundStyle(color)
            }
            .padding(.bottom, 20)
            
            Text(title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}
