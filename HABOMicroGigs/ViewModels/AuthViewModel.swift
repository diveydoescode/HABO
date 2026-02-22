import Foundation

@Observable
class AuthViewModel {
    var isAuthenticated: Bool = false
    var isAgeVerified: Bool = false
    var isLoading: Bool = false
    var currentUser: UserProfile?

    func signInWithGoogle() {
        guard isAgeVerified else { return }
        isLoading = true

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            self.currentUser = UserProfile(
                name: "Arjun Sharma",
                email: "arjun.sharma@gmail.com",
                avatarURL: nil,
                rating: 4.8,
                tasksPosted: 3,
                tasksCompleted: 7,
                memberSince: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
            )
            self.isAuthenticated = true
            self.isLoading = false
        }
    }

    func signOut() {
        isAuthenticated = false
        currentUser = nil
        isAgeVerified = false
    }
}
