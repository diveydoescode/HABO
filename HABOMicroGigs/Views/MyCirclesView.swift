// MARK: - MyCirclesView.swift
import SwiftUI

struct MyCirclesView: View {
    @State private var circles: [Circle] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading circles...")
                        .tint(Color(red: 1.0, green: 0.45, blue: 0.0))
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(.red)
                        Text(errorMessage).multilineTextAlignment(.center).foregroundStyle(.secondary)
                        Button("Retry") { Task { await loadCircles() } }.buttonStyle(.bordered)
                    }
                } else if circles.isEmpty {
                    ContentUnavailableView(
                        "No Circles Yet",
                        systemImage: "shield.slash",
                        description: Text("Create a private circle or join one using an 8-digit trust code.")
                    )
                } else {
                    List(circles) { circle in
                        // ✅ Navigates to the invite generation screen when tapped
                        NavigationLink(destination: GenerateInviteView(circle: circle)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(circle.name)
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                
                                Text("Tap to view or generate invite code")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable { await loadCircles() }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("My Circles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                
                // ✅ Menu for both Join and Create
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("Create Circle", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showJoinSheet = true
                        } label: {
                            Label("Join Circle", systemImage: "person.badge.key")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.0))
                    }
                }
            }
            // ✅ Updated references to new unique names
            .sheet(isPresented: $showCreateSheet) {
                MyCircleCreateSheet { newCircle in
                    circles.insert(newCircle, at: 0)
                }
            }
            .sheet(isPresented: $showJoinSheet) {
                MyCircleJoinSheet {
                    Task { await loadCircles() } // Reload after joining
                }
            }
            .task {
                await loadCircles()
            }
        }
    }
    
    private func loadCircles() async {
        isLoading = true
        errorMessage = nil
        do {
            circles = try await APIClient.shared.fetchMyCircles()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - MyCircleCreateSheet (Renamed to avoid conflict)
struct MyCircleCreateSheet: View {
    @Environment(\.dismiss) var dismiss
    var onCreated: (Circle) -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Circle Details")) {
                    TextField("Circle Name (e.g. Stanford Dorm)", text: $name)
                    TextField("Description (Optional)", text: $description)
                }
                
                if let error = errorMessage {
                    Text(error).foregroundColor(.red).font(.caption)
                }
                
                Button {
                    Task { await createCircle() }
                } label: {
                    HStack {
                        Spacer()
                        if isCreating {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Circle").font(.headline)
                        }
                        Spacer()
                    }
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                .listRowBackground(
                    name.trimmingCharacters(in: .whitespaces).isEmpty
                    ? Color(.systemGray4)
                    : Color(red: 1.0, green: 0.45, blue: 0.0)
                )
                .foregroundColor(.white)
            }
            .navigationTitle("New Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func createCircle() async {
        isCreating = true
        do {
            let newCircle = try await APIClient.shared.createCircle(name: name, description: description)
            onCreated(newCircle)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isCreating = false
        }
    }
}

// MARK: - MyCircleJoinSheet (Renamed to avoid conflict)
struct MyCircleJoinSheet: View {
    @Environment(\.dismiss) var dismiss
    var onJoined: () -> Void
    
    @State private var inviteCode: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section(footer: Text("Enter the 8-digit trust code generated by the circle admin. This code expires every 45 seconds.")) {
                    TextField("Invite Code (e.g. 12345678)", text: $inviteCode)
                        .keyboardType(.numberPad)
                        .font(.system(.title3, design: .monospaced))
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Button(action: {
                    Task { await joinCircle() }
                }) {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Join Circle").fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(inviteCode.count < 6 || isSubmitting)
                .listRowBackground(Color.green)
                .foregroundColor(.white)
            }
            .navigationTitle("Join Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func joinCircle() async {
        isSubmitting = true
        errorMessage = nil
        do {
            // Sends the code to your PyOTP backend verification
            try await APIClient.shared.joinCircle(inviteCode: inviteCode)
            onJoined()
            dismiss()
        } catch {
            errorMessage = "Invalid or expired code. Please ask for a fresh one."
        }
        isSubmitting = false
    }
}
