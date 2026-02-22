import SwiftUI

struct ProfileView: View {
    let user: UserProfile
    @Bindable var taskViewModel: TaskViewModel
    let onSignOut: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    statsSection
                    myTasksSection
                    settingsSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Text(String(user.name.prefix(1)).uppercased())
                    .font(.system(.title, design: .default, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text(user.name)
                    .font(.title2.weight(.bold))

                Text(user.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Image(systemName: Double(index) < user.rating ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(Double(index) < user.rating ? .yellow : .secondary)
                }
                Text(String(format: "%.1f", user.rating))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text("Member since \(user.memberSince.formatted(.dateTime.month(.wide).year()))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                value: "\(taskViewModel.tasksPostedBy(user.name).count)",
                label: "Posted",
                icon: "arrow.up.circle.fill",
                color: .blue
            )

            StatCard(
                value: "\(taskViewModel.tasksAcceptedBy(user.name).count)",
                label: "Completed",
                icon: "checkmark.circle.fill",
                color: .green
            )

            StatCard(
                value: String(format: "%.1f", user.rating),
                label: "Rating",
                icon: "star.fill",
                color: .yellow
            )
        }
    }

    private var myTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Posted Tasks")
                .font(.headline)

            let myTasks = taskViewModel.tasksPostedBy(user.name)
            if myTasks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No tasks posted yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
            } else {
                ForEach(myTasks) { task in
                    MyTaskRow(task: task)
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(spacing: 0) {
            SettingsRow(icon: "bell.fill", title: "Notifications", color: .red)
            Divider().padding(.leading, 52)
            SettingsRow(icon: "shield.fill", title: "Privacy & Safety", color: .blue)
            Divider().padding(.leading, 52)
            SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
            Divider().padding(.leading, 52)

            Button {
                onSignOut()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.body)
                        .frame(width: 28)
                        .foregroundStyle(.red)

                    Text("Sign Out")
                        .font(.body)
                        .foregroundStyle(.red)

                    Spacer()
                }
                .padding(14)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
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
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.weight(.bold))

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}

struct MyTaskRow: View {
    let task: GigTask

    private var statusColor: Color {
        switch task.status {
        case .active: return .green
        case .accepted: return .blue
        case .completed: return .secondary
        case .cancelled: return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text("₹\(task.budget)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
            }

            Spacer()

            Text(task.status.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12))
                .clipShape(.capsule)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 28)
                .foregroundStyle(color)

            Text(title)
                .font(.body)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
    }
}
