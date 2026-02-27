// MARK: - SearchView.swift
import SwiftUI

struct SearchView: View {
    @State private var query: String = ""
    @State private var results: [UserSearchResult] = []
    @State private var isSearching: Bool = false
    @State private var followingIds: Set<UUID> = []
    @State private var searchTask: Task<Void, Never>? = nil

    // Persistent Recent Searches
    @AppStorage("habo_recent_searches") private var recentSearchesData: Data = Data()
    @State private var recentSearches: [String] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                if query.isEmpty {
                    recentSearchesView
                } else if isSearching {
                    Spacer()
                    ProgressView().tint(Color(red: 1.0, green: 0.45, blue: 0.0))
                    Spacer()
                } else if results.isEmpty && query.count >= 2 {
                    ContentUnavailableView(
                        "No Users Found",
                        systemImage: "person.slash",
                        description: Text("No one matched \"\(query)\". Try another name.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results) { user in
                                UserSearchRow(
                                    user: user,
                                    isFollowing: followingIds.contains(user.id)
                                ) {
                                    toggleFollowOptimistically(user)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Search People")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: loadRecentSearches)
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            TextField("Search by name...", text: $query)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .autocorrectionDisabled()
                .onSubmit {
                    if !query.trimmingCharacters(in: .whitespaces).isEmpty {
                        addRecentSearch(query)
                    }
                }
                .onChange(of: query) { _, newValue in
                    searchTask?.cancel()
                    guard newValue.count >= 2 else {
                        results = []
                        isSearching = false
                        return
                    }
                    searchTask = Task {
                        try? await Task.sleep(for: .milliseconds(400))
                        guard !Task.isCancelled else { return }
                        await performSearch(newValue)
                    }
                }
            
            if !query.isEmpty {
                Button {
                    withAnimation { query = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Recent Searches View
    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !recentSearches.isEmpty {
                HStack {
                    Text("Recent Searches")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Clear") {
                        withAnimation {
                            recentSearches.removeAll()
                            saveRecentSearches()
                        }
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(recentSearches, id: \.self) { pastQuery in
                            Button {
                                query = pastQuery
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "clock")
                                        .foregroundStyle(.tertiary)
                                    Text(pastQuery)
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color(.systemGray4))
                    Text("Search for users to follow")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
    }

    // MARK: - Logic
    private func performSearch(_ q: String) async {
        isSearching = true
        do {
            results = try await APIClient.shared.searchUsers(query: q)
        } catch {
            results = []
        }
        isSearching = false
    }

    private func toggleFollowOptimistically(_ user: UserSearchResult) {
        let isCurrentlyFollowing = followingIds.contains(user.id)
        
        // Optimistic UI Update
        withAnimation(.spring(response: 0.3)) {
            if isCurrentlyFollowing {
                followingIds.remove(user.id)
            } else {
                followingIds.insert(user.id)
            }
        }
        
        // Background API Call
        Task {
            do {
                if isCurrentlyFollowing {
                    _ = try await APIClient.shared.unfollowUser(userId: user.id.uuidString)
                } else {
                    _ = try await APIClient.shared.followUser(userId: user.id.uuidString)
                }
            } catch {
                // Revert on failure
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        if isCurrentlyFollowing {
                            followingIds.insert(user.id)
                        } else {
                            followingIds.remove(user.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Local Storage Helpers
    private func loadRecentSearches() {
        if let decoded = try? JSONDecoder().decode([String].self, from: recentSearchesData) {
            recentSearches = decoded
        }
    }

    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            recentSearchesData = encoded
        }
    }

    private func addRecentSearch(_ q: String) {
        let trimmed = q.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        var searches = recentSearches
        if let idx = searches.firstIndex(of: trimmed) {
            searches.remove(at: idx)
        }
        searches.insert(trimmed, at: 0)
        if searches.count > 10 { searches = Array(searches.prefix(10)) }
        
        withAnimation { recentSearches = searches }
        saveRecentSearches()
    }
}

// MARK: - User Search Row
struct UserSearchRow: View {
    let user: UserSearchResult
    let isFollowing: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                Text(String(user.name.prefix(1)).uppercased())
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption2)
                        Text(String(format: "%.1f", user.rating))
                    }
                    Text("·").foregroundStyle(.tertiary)
                    Text("\(user.followerCount) followers")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Follow Button
            Button(action: onToggle) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(isFollowing ? .white : Color(red: 1.0, green: 0.45, blue: 0.0))
                    .frame(width: 100)
                    .padding(.vertical, 8)
                    .background(
                        isFollowing
                            ? AnyShapeStyle(Color.black)
                            : AnyShapeStyle(Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.12))
                    )
                    .clipShape(.capsule)
            }
            .buttonStyle(.plain) // Prevents the whole row from becoming tappable
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}
