// MARK: - MyCirclesView.swift
import SwiftUI

struct MyCirclesView: View {
    @State private var circles: [Circle] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading circles...")
                        .tint(Color(red: 1.0, green: 0.45, blue: 0.0))
                } else if circles.isEmpty {
                    ContentUnavailableView(
                        "No Circles Yet",
                        systemImage: "shield.slash",
                        description: Text("Create a private circle for your campus, apartment, or friend group.")
                    )
                } else {
                    List(circles) { circle in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(circle.name)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            
                            if let desc = circle.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Optional: Show an invite code if your backend generates one
                            if let code = circle.inviteCode {
                                Text("Invite Code: \(code)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("My Circles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.0))
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateCircleView { newCircle in
                    circles.insert(newCircle, at: 0)
                }
            }
            .task {
                await loadCircles()
            }
        }
    }
    
    private func loadCircles() async {
        do {
            circles = try await APIClient.shared.fetchMyCircles()
        } catch {
            print("Error loading circles: \(error)")
        }
        isLoading = false
    }
}

// MARK: - CreateCircleView (Sheet)
struct CreateCircleView: View {
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
                            Text("Create Circle")
                                .font(.headline)
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
