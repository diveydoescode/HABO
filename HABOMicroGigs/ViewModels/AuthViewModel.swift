// MARK: - AuthViewModel.swift
import Foundation
import GoogleSignIn

@Observable
class AuthViewModel {
    var isAuthenticated: Bool = false
    var isCheckingSession: Bool = true
    var isAgeVerified: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var currentUser: UserResponse?
    
    var needsOnboarding: Bool = false // ✅ NEW

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
                    
                    // ✅ NEW: Check if user needs to be onboarded
                    self.needsOnboarding = response.user.name.isEmpty || (response.user.skills?.isEmpty ?? true)
                    
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
        needsOnboarding = false // ✅ Reset on sign out
    }

    func restoreSessionIfNeeded() async {
        defer {
            Task { @MainActor in self.isCheckingSession = false }
        }
        
        guard APIClient.shared.accessToken != nil else { return }
        
        do {
            let user = try await APIClient.shared.getMe()
            await MainActor.run {
                self.currentUser = user
                // ✅ NEW: Check if returning user somehow bypassed onboarding
                self.needsOnboarding = user.name.isEmpty || (user.skills?.isEmpty ?? true)
                self.isAuthenticated = true
            }
        } catch {
            APIClient.shared.clearToken()
        }
    }
}
