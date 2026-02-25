// MARK: - TaskDetailView.swift
// ⚠️  REPLACE existing HABOMicroGigs/Views/TaskDetailView.swift
//
// Changes from old file:
//   - acceptTask() now calls taskViewModel.acceptTask() async (API)
//   - Added "Complete Task & Pay" button for task creator (calls Razorpay)
//   - Added "Open Chat" button after acceptance (navigates to ChatView)
//   - recipientPublicKey fetched from API for E2EE chat setup

import SwiftUI
import MapKit

struct TaskDetailView: View {
    let task: TaskResponse
    @Bindable var taskViewModel: TaskViewModel
    let currentUser: UserResponse
    @Environment(\.dismiss) private var dismiss

    @State private var showAcceptConfirmation: Bool = false
    @State private var hasAccepted: Bool = false
    @State private var isAccepting: Bool = false
    @State private var isPaying: Bool = false
    @State private var showChat: Bool = false
    @State private var recipientPublicKey: String? = nil
    @State private var paymentError: String? = nil

    private var categoryColor: Color {
        switch task.category {
        case "Academic": return .blue
        case "Roadside Help": return .red
        case "Labor": return .orange
        default: return .purple
        }
    }

    private var isOwner: Bool { task.creatorId == currentUser.id }
    private var canAccept: Bool { !isOwner && task.status == "Active" }
    private var canPay: Bool { isOwner && task.status == "Completed" }
    private var chatIsUnlocked: Bool { hasAccepted || task.status == "Accepted" || task.status == "Completed" }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                mapPreview

                VStack(alignment: .leading, spacing: 16) {
                    // Title + budget
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.title).font(.title2.weight(.bold))
                            HStack(spacing: 8) {
                                Label(task.category, systemImage: categoryIcon)
                                    .font(.caption.weight(.semibold)).foregroundStyle(categoryColor)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(categoryColor.opacity(0.12)).clipShape(.capsule)
                                Label(task.status, systemImage: task.status == "Active" ? "clock.fill" : "checkmark.circle.fill")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(task.status == "Active" ? .green : .secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("₹\(task.budget)").font(.title.weight(.bold)).foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                            if task.isNegotiable { Text("Negotiable").font(.caption).foregroundStyle(.secondary) }
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                        Text(task.description).font(.body).foregroundStyle(.primary)
                    }

                    Divider()

                    // Creator info
                    HStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill").font(.title2).foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Posted by").font(.caption).foregroundStyle(.secondary)
                                Text(task.creatorName).font(.subheadline.weight(.medium))
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Posted").font(.caption).foregroundStyle(.secondary)
                            Text(task.createdAt.formatted(.relative(presentation: .named))).font(.subheadline.weight(.medium))
                        }
                    }

                    // Radius info
                    HStack(spacing: 6) {
                        Image(systemName: "circle.dashed").font(.caption).foregroundStyle(.blue)
                        Text("Visible within \(task.radiusMetres / 1000) km radius").font(.caption).foregroundStyle(.secondary)
                    }

                    // Fee notice
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").font(.caption).foregroundStyle(.orange)
                        Text("A 10–15% platform fee applies upon task completion.").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08)).clipShape(.rect(cornerRadius: 10))

                    // ── ACCEPT BUTTON (non-owner, active task) ────────────
                    if canAccept {
                        Button {
                            showAcceptConfirmation = true
                        } label: {
                            HStack(spacing: 10) {
                                if isAccepting { ProgressView().tint(.white) }
                                else {
                                    Image(systemName: "hand.raised.fill")
                                    Text(hasAccepted ? "Accepted ✅" : "Accept Task").font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .leading, endPoint: .trailing))
                            .foregroundStyle(.white).clipShape(.rect(cornerRadius: 16))
                        }
                        .disabled(hasAccepted || isAccepting)
                        .confirmationDialog("Accept this task?", isPresented: $showAcceptConfirmation) {
                            Button("Accept Task") {
                                Task { await acceptTask() }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("You'll be assigned to \"\(task.title)\" for ₹\(task.budget). A 10–15% platform fee applies on completion.")
                        }
                    }

                    // ── OPEN CHAT BUTTON (both parties after acceptance) ──
                    if chatIsUnlocked {
                        NavigationLink(destination: chatDestination) {
                            HStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Open Encrypted Chat").font(.headline)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(.blue).clipShape(.rect(cornerRadius: 16))
                        }
                    }

                    // ── PAY BUTTON (owner, task completed) ────────────────
                    if canPay {
                        Button {
                            Task { await initiatePayment() }
                        } label: {
                            HStack(spacing: 10) {
                                if isPaying { ProgressView().tint(.white) }
                                else {
                                    Image(systemName: "indianrupeesign.circle.fill")
                                    Text("Complete Task & Pay ₹\(task.budget)").font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.green).foregroundStyle(.white).clipShape(.rect(cornerRadius: 16))
                        }
                        .disabled(isPaying)

                        if let err = paymentError {
                            Text(err).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
        }
        .task { await fetchRecipientKey() }
    }

    // MARK: - Map Preview (unchanged)
    private var mapPreview: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))) {
            Annotation(task.title, coordinate: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)) {
                ZStack {
                    Circle().fill(categoryColor.gradient).frame(width: 36, height: 36)
                    Image(systemName: categoryIcon).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                }
            }
        }
        .mapStyle(.standard).frame(height: 200).allowsHitTesting(false)
    }

    @ViewBuilder
    private var chatDestination: some View {
        if let pubKey = recipientPublicKey {
            ChatView(taskId: task.id, currentUserId: currentUser.id, recipientPublicKey: pubKey)
        } else {
            Text("Could not load recipient's encryption key").foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions
    private func acceptTask() async {
        isAccepting = true
        _ = await taskViewModel.acceptTask(taskId: task.id, by: currentUser.name)
        hasAccepted = true
        isAccepting = false
    }

    private func fetchRecipientKey() async {
        // Fetch the OTHER participant's public key for E2EE
        let otherId = isOwner ? task.acceptedById : task.creatorId
        guard let id = otherId else { return }
        if let profile = try? await APIClient.shared.getUserProfile(userId: id.uuidString) {
            recipientPublicKey = profile.publicKey
        }
    }

    private func initiatePayment() async {
        isPaying = true
        paymentError = nil
        do {
            let order = try await APIClient.shared.createPaymentOrder(
                taskId: task.id.uuidString,
                amountPaise: task.budget * 100
            )
            // Launch Razorpay SDK — requires adding razorpay-pod or SPM package
            // See: https://razorpay.com/docs/payments/payment-gateway/ios-integration/
            // RazorpayEventDelegate handles success/failure callbacks
            // On success: await taskViewModel.completeTask(taskId: task.id)
            print("Razorpay Order ID: \(order.razorpayOrderId) Key: \(order.keyId)")
            // TODO: Replace print with actual Razorpay SDK call
        } catch {
            paymentError = error.localizedDescription
        }
        isPaying = false
    }

    private var categoryIcon: String {
        switch task.category {
        case "Academic": return "book.fill"
        case "Roadside Help": return "car.fill"
        case "Labor": return "hammer.fill"
        default: return "star.fill"
        }
    }
}
