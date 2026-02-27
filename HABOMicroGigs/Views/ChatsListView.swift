// MARK: - ChatsListView.swift
import SwiftUI

struct ChatsListView: View {
    @Bindable var taskViewModel: TaskViewModel
    let currentUser: UserResponse
    
    // Filter tasks to only those where chat is unlocked AND user is involved
    var activeChats: [TaskResponse] {
        taskViewModel.tasks.filter { task in
            (task.status == "Accepted" || task.status == "Completed") &&
            (task.creatorId == currentUser.id || task.acceptedById == currentUser.id)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeChats.isEmpty {
                    ContentUnavailableView(
                        "No Active Chats",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("When you accept a task or someone accepts yours, the chat will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(activeChats) { task in
                                NavigationLink {
                                    TaskDetailView(task: task, taskViewModel: taskViewModel, currentUser: currentUser)
                                } label: {
                                    ChatRowView(task: task, isOwner: task.creatorId == currentUser.id)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ChatRowView: View {
    let task: TaskResponse
    let isOwner: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                Image(systemName: "lock.fill")
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .lineLimit(1)
                
                Text(isOwner ? "You posted this" : "You accepted this")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}
