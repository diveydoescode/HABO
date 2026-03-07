// MARK: - TaskApplicantsView.swift
import SwiftUI

struct TaskApplicantsView: View {
    let task: TaskResponse
    var onHired: () -> Void
    
    @State private var applicants: [TaskApplicationResponse] = []
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    init(task: TaskResponse, onHired: @escaping () -> Void) {
        self.task = task
        self.onHired = onHired
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Fetching applications...")
                } else if applicants.isEmpty {
                    ContentUnavailableView(
                        "No Applicants Yet",
                        systemImage: "person.3.sequence",
                        description: Text("Hang tight! Brothers in your circle will see this demand soon.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(applicants) { applicant in
                                // ✅ FIXED: Use explicit 'onHire:' parameter
                                ApplicantRow(application: applicant, onHire: {
                                    Task { await hireBrother(applicant) }
                                })
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Review Applicants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .background(Color(.systemGroupedBackground))
            .task {
                await loadApplicants()
            }
        }
    }
    
    private func loadApplicants() async {
        do {
            applicants = try await APIClient.shared.getTaskApplications(taskId: task.id.uuidString)
            isLoading = false
        } catch {
            print("Error: \(error)")
            isLoading = false
        }
    }
    
    private func hireBrother(_ application: TaskApplicationResponse) async {
        do {
            _ = try await APIClient.shared.acceptApplication(applicationId: application.id.uuidString)
            onHired()
            dismiss()
        } catch {
            print("Hiring failed: \(error)")
        }
    }
}
