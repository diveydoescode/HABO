import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var taskViewModel = TaskViewModel()
    @State private var locationService = LocationService()
    @State private var selectedTab: Int = 0
    @State private var showPostTask: Bool = false

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                mainTabView
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
        .animation(.spring(response: 0.5), value: authViewModel.isAuthenticated)
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "map.fill", value: 0) {
                HomeView(
                    taskViewModel: taskViewModel,
                    locationService: locationService,
                    userName: authViewModel.currentUser?.name ?? "User"
                )
            }

            Tab("Post", systemImage: "plus.circle.fill", value: 1) {
                Color.clear
                    .onAppear {
                        showPostTask = true
                        selectedTab = 0
                    }
            }

            Tab("Profile", systemImage: "person.fill", value: 2) {
                ProfileView(
                    user: authViewModel.currentUser ?? UserProfile(name: "User", email: "user@email.com"),
                    taskViewModel: taskViewModel,
                    onSignOut: { authViewModel.signOut() }
                )
            }
        }
        .tint(Color(red: 1.0, green: 0.45, blue: 0.0))
        .onAppear {
            locationService.requestPermission()
        }
        .fullScreenCover(isPresented: $showPostTask) {
            PostTaskView(
                taskViewModel: taskViewModel,
                locationService: locationService,
                userName: authViewModel.currentUser?.name ?? "User",
                onDismiss: { showPostTask = false }
            )
        }
    }
}


