// MARK: - ContentView.swift
import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    @State private var authViewModel = AuthViewModel()
    @State private var taskViewModel = TaskViewModel()
    @State private var locationService = LocationService()
    
    @State private var selectedTab: Int = 0
    @State private var showPostTask: Bool = false

    var body: some View {
        Group {
            if authViewModel.isCheckingSession {
                SplashView()
            } else if authViewModel.isAuthenticated, let user = authViewModel.currentUser {
                // ✅ Check if they are authenticated BUT still need onboarding (name/skills empty)
                if authViewModel.needsOnboarding {
                    OnboardingView(authViewModel: authViewModel)
                } else {
                    mainTabView(user: user)
                }
            } else {
                // Not authenticated. Do they need the welcome tour?
                if !hasSeenOnboarding {
                    OnboardingView(authViewModel: authViewModel)
                } else {
                    LoginView(authViewModel: authViewModel)
                }
            }
        }
        .animation(.spring(response: 0.5), value: hasSeenOnboarding)
        .animation(.spring(response: 0.5), value: authViewModel.isAuthenticated)
        .animation(.spring(response: 0.5), value: authViewModel.needsOnboarding) // ✅ Added animation for this state
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isCheckingSession)
        .task {
            await authViewModel.restoreSessionIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToPostTab"))) { _ in
            showPostTask = true
            selectedTab = 0
        }
    }

    private func mainTabView(user: UserResponse) -> some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "map.fill", value: 0) {
                HomeView(taskViewModel: taskViewModel, locationService: locationService, currentUser: user)
            }
            
            Tab("Post", systemImage: "plus.circle.fill", value: 1) {
                Color.clear.onAppear {
                    showPostTask = true
                    selectedTab = 0
                }
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: 2) {
                SearchView()
            }
            
            // ✅ NEW CHAT TAB
            Tab("Chats", systemImage: "message.fill", value: 3) {
                ChatsListView(taskViewModel: taskViewModel, currentUser: user)
            }

            Tab("Profile", systemImage: "person.fill", value: 4) {
                ProfileView(user: user, taskViewModel: taskViewModel, onSignOut: { authViewModel.signOut() })
            }
        }
        .tint(Color(red: 1.0, green: 0.45, blue: 0.0))
        .onAppear { locationService.requestPermission() }
        .fullScreenCover(isPresented: $showPostTask) {
            PostTaskView(taskViewModel: taskViewModel, locationService: locationService, userName: user.name, onDismiss: { showPostTask = false })
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    // ✅ explicitly use SwiftUI.Circle to avoid colliding with your new API Model
                    SwiftUI.Circle().fill(.ultraThinMaterial).frame(width: 100, height: 100)
                    Image(systemName: "hands.and.sparkles.fill").font(.system(size: 44))
                        .foregroundStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.5, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                ProgressView().tint(Color(red: 1.0, green: 0.45, blue: 0.0)).scaleEffect(1.2)
            }
        }
    }
}
