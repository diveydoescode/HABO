import SwiftUI
import GoogleSignIn

@main
struct HABOMicroGigsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // This line handles the redirect back from Google after login
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
