// MARK: - ProfileView.swift
import SwiftUI

struct ProfileView: View {
    let user: UserResponse
    @Bindable var taskViewModel: TaskViewModel
    let onSignOut: () -> Void

    @State private var selectedTaskTab: ProfileTaskTab = .posted
    
    // ✅ NEW: Environment variable to handle URL redirects
    @Environment(\.openURL) var openURL

    enum ProfileTaskTab: String, CaseIterable {
        case posted = "Posted"
        case accepted = "Accepted"
        case completed = "Completed"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    statsSection
                    
                    // Edit Profile Button
                    Button {
                        // Action for Edit Profile
                    } label: {
                        Text("Edit Profile")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(.capsule)
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    }
                    
                    tasksSection
                    settingsSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 88, height: 88)
                    .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.3), radius: 10, y: 5)
                
                Text(String(user.name.prefix(1)).uppercased())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 6) {
                Text(user.name)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Stars Rating
            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    Image(systemName: Double(i) < user.rating ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(Double(i) < user.rating ? .yellow : Color(.systemGray4))
                }
                Text(String(format: "%.1f", user.rating))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(.leading, 4)
            }
            
            // Followers & Following
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(user.followerCount)").font(.system(.headline, design: .rounded, weight: .bold))
                    Text("Followers").font(.caption).foregroundStyle(.secondary)
                }
                
                Divider().frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("\(user.followingCount)").font(.system(.headline, design: .rounded, weight: .bold))
                    Text("Following").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
            
            Text("Joined \(user.memberSince.formatted(.dateTime.month(.wide).year()))")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(taskViewModel.tasksPostedBy(userId: user.id).count)", label: "Posted", icon: "arrow.up.circle.fill", color: .blue)
            StatCard(value: "\(taskViewModel.tasksAcceptedBy(userId: user.id).filter { $0.status == "Completed" }.count)", label: "Completed", icon: "checkmark.circle.fill", color: .green)
        }
    }

    // MARK: - Tasks Section
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Tasks", selection: $selectedTaskTab) {
                ForEach(ProfileTaskTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            
            let filteredTasks = displayedTasks
            
            if filteredTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color(.systemGray4))
                    Text("No \(selectedTaskTab.rawValue.lowercased()) tasks yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTasks) { task in
                        ProfileTaskRow(task: task)
                    }
                }
            }
        }
    }
    
    // Logic to filter tasks based on selected segment
    private var displayedTasks: [TaskResponse] {
        switch selectedTaskTab {
        case .posted:
            return taskViewModel.tasksPostedBy(userId: user.id)
        case .accepted:
            return taskViewModel.tasksAcceptedBy(userId: user.id).filter { $0.status == "Accepted" }
        case .completed:
            return taskViewModel.tasks.filter {
                $0.status == "Completed" && ($0.creatorId == user.id || $0.acceptedById == user.id)
            }
        }
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 0) {
            SettingsRow(icon: "bell.fill", title: "Notifications", color: .red)
            Divider().padding(.leading, 52)
            
            // ✅ NEW: Functional Redirect for Privacy
            Button {
                if let url = URL(string: "https://haboapp.com/privacy") { // Replace with actual URL
                    openURL(url)
                }
            } label: {
                SettingsRow(icon: "shield.fill", title: "Privacy & Safety", color: .blue)
            }
            .buttonStyle(.plain) // Prevents the whole row from looking like a standard blue button
            
            Divider().padding(.leading, 52)
            
            // ✅ NEW: Functional Redirect for Support
            Button {
                if let url = URL(string: "https://haboapp.com/support") { // Replace with actual URL
                    openURL(url)
                }
            } label: {
                SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
            }
            .buttonStyle(.plain)
            
            Divider().padding(.leading, 52)
            
            Button { onSignOut() } label: {
                HStack(spacing: 16) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title3)
                        .frame(width: 32)
                        .foregroundStyle(.red)
                    Text("Sign Out")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(16)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

// MARK: - Subviews

struct ProfileTaskRow: View {
    let task: TaskResponse
    
    private var statusColor: Color {
        switch task.status {
        case "Active": return .green
        case "Accepted": return Color(red: 1.0, green: 0.45, blue: 0.0)
        case "Completed": return .gray
        default: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .lineLimit(1)
                
                Text("₹\(task.budget)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
            }
            
            Spacer()
            
            Text(task.status)
                .font(.caption.weight(.bold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.12))
                .clipShape(.capsule)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
            
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 32)
                .foregroundStyle(color)
            Text(title)
                .font(.system(.body, design: .rounded, weight: .semibold))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
    }
}
