// MARK: - LoginView.swift
import SwiftUI

struct LoginView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var showAgeError: Bool = false
    @State private var animateGradient: Bool = false

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [animateGradient ? 0.6 : 0.4, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    .black, Color(red: 0.05, green: 0.05, blue: 0.15), .black,
                    Color(red: 0.0, green: 0.1, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.0), Color(red: 0.0, green: 0.1, blue: 0.3),
                    .black, Color(red: 0.05, green: 0.05, blue: 0.15), .black
                ]
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 110, height: 110)
                            .shadow(color: Color(red: 1.0, green: 0.4, blue: 0.0).opacity(0.3), radius: 20, y: 10)
                        
                        Image(systemName: "hands.and.sparkles.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.5, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("Help a Brother Out")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Hyper-local micro-gigs.\nPost a task. Set a price. Get it done.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 24) {
                    // Age verification
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            authViewModel.isAgeVerified.toggle()
                            if showAgeError { showAgeError = false }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: authViewModel.isAgeVerified ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(authViewModel.isAgeVerified ? Color(red: 1.0, green: 0.45, blue: 0.0) : .white.opacity(0.5))
                                .contentTransition(.symbolEffect(.replace))
                            Text("I confirm I am 18 years or older")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    }
                    .sensoryFeedback(.selection, trigger: authViewModel.isAgeVerified)

                    if showAgeError {
                        Text("You must confirm you are 18+ to continue")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.red)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let errorMsg = authViewModel.errorMessage {
                        Text(errorMsg)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Continue Button
                    Button {
                        if !authViewModel.isAgeVerified {
                            withAnimation(.spring(response: 0.3)) { showAgeError = true }
                            return
                        }
                        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let vc = scene.windows.first?.rootViewController else { return }
                        authViewModel.signInWithGoogle(presenting: vc)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Continue with Google")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            if authViewModel.isLoading {
                                Spacer()
                                ProgressView().tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            authViewModel.isAgeVerified
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)],
                                    startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(Color.white.opacity(0.15))
                        )
                        .foregroundStyle(.white)
                        .clipShape(.capsule)
                        .shadow(color: authViewModel.isAgeVerified ? Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.3) : .clear, radius: 8, y: 4)
                    }
                    .disabled(authViewModel.isLoading)

                    Text("By continuing, you agree to our Terms of Service\nand Privacy Policy")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
