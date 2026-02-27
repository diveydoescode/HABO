// MARK: - AuthViewModel.swift
import Foundation
import GoogleSignIn

@Observable
class AuthViewModel {
    var isAuthenticated: Bool = false
    var isCheckingSession: Bool = true // NEW: Starts true so we show a splash screen first
    var isAgeVerified: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var currentUser: UserResponse?

    func signInWithGoogle(presenting viewController: UIViewController) {
        guard isAgeVerified else {
            errorMessage = "Please confirm you are 18 or older"
            return
        }
        isLoading = true
        errorMessage = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.isLoading = false }

                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let idToken = result?.user.idToken?.tokenString else {
                    self.errorMessage = "Could not get ID token from Google"
                    return
                }

                do {
                    let publicKeyB64 = try CryptoService.shared.getPublicKeyB64()
                    let response = try await APIClient.shared.loginWithGoogle(
                        idToken: idToken,
                        publicKey: publicKeyB64
                    )
                    APIClient.shared.accessToken = response.accessToken
                    self.currentUser = response.user
                    self.isAuthenticated = true
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        APIClient.shared.clearToken()
        isAuthenticated = false
        currentUser = nil
        isAgeVerified = false
    }

    /// Call on app launch to restore session if token exists
    func restoreSessionIfNeeded() async {
        // Automatically set to false when this function finishes, no matter what
        defer {
            Task { @MainActor in self.isCheckingSession = false }
        }
        
        guard APIClient.shared.accessToken != nil else { return }
        
        do {
            let user = try await APIClient.shared.getMe()
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            // Token expired or invalid
            APIClient.shared.clearToken()
        }
    }
}
