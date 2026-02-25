// MARK: - AuthViewModel.swift
// ⚠️  REPLACE existing HABOMicroGigs/ViewModels/AuthViewModel.swift
//
// Changes from old file:
//   - Removed mock 1.2s delay + hardcoded "Arjun Sharma"
//   - Added real Google Sign-In via GoogleSignIn SDK
//   - Sends id_token + NaCl public_key to POST /auth/login
//   - Stores JWT in UserDefaults via APIClient
//
// Before this works, add GoogleSignIn SDK:
//   File → Add Package Dependencies →
//   https://github.com/google/GoogleSignIn-iOS
//   Then add your REVERSED_CLIENT_ID to Info.plist URL schemes

import Foundation
import GoogleSignIn   // Add package: https://github.com/google/GoogleSignIn-iOS

@Observable
class AuthViewModel {
    var isAuthenticated: Bool = false
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
                    // Get or generate E2EE key pair — public key goes to server
                    let publicKeyB64 = try CryptoService.shared.getPublicKeyB64()

                    let response = try await APIClient.shared.loginWithGoogle(
                        idToken: idToken,
                        publicKey: publicKeyB64
                    )
                    // Store JWT
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
        guard APIClient.shared.accessToken != nil else { return }
        do {
            let user = try await APIClient.shared.getMe()
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            // Token expired
            APIClient.shared.clearToken()
        }
    }
}
