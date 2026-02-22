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

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 100, height: 100)

                        Image(systemName: "hands.and.sparkles.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.5, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Text("Help a Brother Out")
                        .font(.system(.largeTitle, design: .default, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Hyper-local micro-gigs.\nPost a task. Set a price. Get it done.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                Spacer()

                VStack(spacing: 20) {
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
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    }
                    .sensoryFeedback(.selection, trigger: authViewModel.isAgeVerified)

                    if showAgeError {
                        Text("You must confirm you are 18+ to continue")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Button {
                        if !authViewModel.isAgeVerified {
                            withAnimation(.spring(response: 0.3)) {
                                showAgeError = true
                            }
                            return
                        }
                        authViewModel.signInWithGoogle()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)

                            Text("Continue with Google")
                                .font(.headline)

                            if authViewModel.isLoading {
                                Spacer()
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            authViewModel.isAgeVerified
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                : AnyShapeStyle(Color.white.opacity(0.15))
                        )
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 16))
                    }
                    .disabled(authViewModel.isLoading)
                    .sensoryFeedback(.impact(weight: .medium), trigger: authViewModel.isLoading)

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

