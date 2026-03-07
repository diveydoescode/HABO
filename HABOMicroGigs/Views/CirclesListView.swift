import SwiftUI

struct CirclesListView: View {
    @State private var circles: [Circle] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    // Sheets state
    @State private var showingCreateSheet = false
    @State private var showingJoinSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading your circles...")
                } else if let error = errorMessage {
                    VStack {
                        Text("⚠️")
                            .font(.largeTitle)
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Try Again") {
                            Task { await loadCircles() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if circles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Circles Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Create a private circle for your campus, or join one using a 45-second trust code.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List(circles) { circle in
                        NavigationLink(destination: GenerateInviteView(circle: circle)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(circle.name)
                                    .font(.headline)
                                Text("Tap to view or generate invite code")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .refreshable {
                        await loadCircles()
                    }
                }
            }
            .navigationTitle("My Circles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("Create Circle", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showingJoinSheet = true
                        } label: {
                            Label("Join Circle", systemImage: "person.badge.key")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .task {
                await loadCircles()
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateCircleSheet(circles: $circles)
            }
            .sheet(isPresented: $showingJoinSheet) {
                JoinCircleSheet(circles: $circles)
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

// MARK: - Create Circle Sheet
struct CreateCircleSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var circles: [Circle]
    
    @State private var circleName: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Circle Details")) {
                    TextField("Enter Circle Name", text: $circleName)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Button(action: {
                    Task { await createCircle() }
                }) {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Circle")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(circleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                .listRowBackground(Color.blue)
                .foregroundColor(.white)
            }
            .navigationTitle("New Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func createCircle() async {
        isSubmitting = true
        errorMessage = nil
        do {
            let newCircle = try await APIClient.shared.createCircle(name: circleName)
            circles.append(newCircle)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Join Circle Sheet
struct JoinCircleSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var circles: [Circle]
    
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
                            Text("Join Circle")
                                .fontWeight(.bold)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func joinCircle() async {
        isSubmitting = true
        errorMessage = nil
        do {
            try await APIClient.shared.joinCircle(inviteCode: inviteCode)
            // Refresh circles by re-fetching them from the API
            circles = try await APIClient.shared.fetchMyCircles()
            dismiss()
        } catch {
            errorMessage = "Invalid or expired code. Please ask the admin for a fresh one."
        }
        isSubmitting = false
    }
}
