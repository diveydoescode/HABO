// MARK: - ContentView.swift
// ⚠️  REPLACE existing HABOMicroGigs/ContentView.swift
//
// Changes from old file:
//   - Auth now uses real UserResponse instead of UserProfile
//   - Added Search tab (Tab 2, pushes existing Profile to Tab 3)
//   - HomeView now receives currentUser: UserResponse
//   - restoreSessionIfNeeded() called on launch

import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var taskViewModel = TaskViewModel()
    @State private var locationService = LocationService()
    @State private var selectedTab: Int = 0
    @State private var showPostTask: Bool = false

    var body: some View {
        Group {
            if authViewModel.isAuthenticated, let user = authViewModel.currentUser {
                mainTabView(user: user)
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
        .animation(.spring(response: 0.5), value: authViewModel.isAuthenticated)
        .task {
            // Restore JWT session on app launch
            await authViewModel.restoreSessionIfNeeded()
        }
    }

    private func mainTabView(user: UserResponse) -> some View {
        TabView(selection: $selectedTab) {
            // Tab 0 — Home / Map
            Tab("Home", systemImage: "map.fill", value: 0) {
                HomeView(
                    taskViewModel: taskViewModel,
                    locationService: locationService,
                    currentUser: user              // ← now passes UserResponse
                )
            }

            // Tab 1 — Post (tap opens sheet, returns to Home)
            Tab("Post", systemImage: "plus.circle.fill", value: 1) {
                Color.clear.onAppear {
                    showPostTask = true
                    selectedTab = 0
                }
            }

            // Tab 2 — Search (NEW)
            Tab("Search", systemImage: "magnifyingglass", value: 2) {
                SearchView()
            }

            // Tab 3 — Profile
            Tab("Profile", systemImage: "person.fill", value: 3) {
                ProfileView(
                    user: user,
                    taskViewModel: taskViewModel,
                    onSignOut: { authViewModel.signOut() }
                )
            }
        }
        .tint(Color(red: 1.0, green: 0.45, blue: 0.0))
        .onAppear { locationService.requestPermission() }
        .fullScreenCover(isPresented: $showPostTask) {
            PostTaskView(
                taskViewModel: taskViewModel,
                locationService: locationService,
                userName: user.name,
                onDismiss: { showPostTask = false }
            )
        }
    }
}
