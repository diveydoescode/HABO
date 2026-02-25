// MARK: - SearchView.swift
// ✅ NEW FILE — Add to HABOMicroGigs/Views/SearchView.swift
// Then add a Search tab in ContentView.swift (see ContentView changes below)

import SwiftUI

struct SearchView: View {
    @State private var query: String = ""
    @State private var results: [UserSearchResult] = []
    @State private var isSearching: Bool = false
    @State private var followingIds: Set<UUID> = []
    @State private var searchTask: Task<Void, Never>? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if isSearching {
                    Spacer()
                    ProgressView().tint(Color(red: 1.0, green: 0.45, blue: 0.0))
                    Spacer()
                } else if results.isEmpty && query.count >= 2 {
                    ContentUnavailableView("No Users Found", systemImage: "person.slash",
                                           description: Text("No one matched \"\(query)\""))
                } else {
                    List(results) { user in
                        UserSearchRow(user: user, isFollowing: followingIds.contains(user.id)) {
                            Task { await toggleFollow(user) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search People")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search by name...", text: $query)
                .autocorrectionDisabled()
                .onChange(of: query) { _, newValue in
                    searchTask?.cancel()
                    guard newValue.count >= 2 else { results = []; return }
                    searchTask = Task {
                        try? await Task.sleep(for: .milliseconds(400))
                        guard !Task.isCancelled else { return }
                        await performSearch(newValue)
                    }
                }
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func performSearch(_ q: String) async {
        isSearching = true
        do {
            results = try await APIClient.shared.searchUsers(query: q)
        } catch {
            results = []
        }
        isSearching = false
    }

    private func toggleFollow(_ user: UserSearchResult) async {
        do {
            if followingIds.contains(user.id) {
                _ = try await APIClient.shared.unfollowUser(userId: user.id.uuidString)
                followingIds.remove(user.id)
            } else {
                _ = try await APIClient.shared.followUser(userId: user.id.uuidString)
                followingIds.insert(user.id)
            }
        } catch {}
    }
}

struct UserSearchRow: View {
    let user: UserSearchResult
    let isFollowing: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar initial
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                Text(String(user.name.prefix(1)).uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(user.name).font(.headline)
                HStack(spacing: 6) {
                    Label(String(format: "%.1f", user.rating), systemImage: "star.fill")
                        .font(.caption).foregroundStyle(.yellow)
                    Text("·").foregroundStyle(.tertiary)
                    Text("\(user.followerCount) followers")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onToggle) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isFollowing ? .white : Color(red: 1.0, green: 0.45, blue: 0.0))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        isFollowing
                            ? AnyShapeStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                            : AnyShapeStyle(Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.12))
                    )
                    .clipShape(.capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
