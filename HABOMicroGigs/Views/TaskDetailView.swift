// MARK: - TaskDetailView.swift
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
    @State private var recipientPublicKey: String? = nil
    @State private var paymentError: String? = nil
    @State private var paymentSuccess: Bool = false
    @State private var currentStatus: String = ""

    private var categoryColor: Color {
        switch task.category {
        case "Academic": return .blue
        case "Roadside Help": return .red
        case "Labor": return .orange
        default: return .purple
        }
    }

    private var isOwner: Bool { task.creatorId == currentUser.id }
    private var canAccept: Bool { !isOwner && currentStatus == "Active" && !hasAccepted }
    private var canPay: Bool { isOwner && currentStatus == "Accepted" }
    private var chatIsUnlocked: Bool {
        hasAccepted || currentStatus == "Accepted" || currentStatus == "Completed"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                mapPreview

                VStack(alignment: .leading, spacing: 16) {

                    // Title + Budget
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.title).font(.title2.weight(.bold))
                            HStack(spacing: 8) {
                                Label(task.category, systemImage: categoryIcon)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(categoryColor)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(categoryColor.opacity(0.12)).clipShape(.capsule)
                                Label(
                                    currentStatus,
                                    systemImage: currentStatus == "Active" ? "clock.fill" : "checkmark.circle.fill"
                                )
                                .font(.caption.weight(.medium))
                                .foregroundStyle(currentStatus == "Active" ? .green : .secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("₹\(task.budget)")
                                .font(.title.weight(.bold))
                                .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                            if task.isNegotiable {
                                Text("Negotiable").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                        Text(task.description).font(.body)
                    }

                    Divider()

                    // Creator Info
                    HStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2).foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Posted by").font(.caption).foregroundStyle(.secondary)
                                Text(task.creatorName).font(.subheadline.weight(.medium))
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Posted").font(.caption).foregroundStyle(.secondary)
                            Text(task.createdAt.formatted(.relative(presentation: .named)))
                                .font(.subheadline.weight(.medium))
                        }
                    }

                    // Radius Info
                    HStack(spacing: 6) {
                        Image(systemName: "circle.dashed").font(.caption).foregroundStyle(.blue)
                        Text("Visible within \(task.radiusMetres / 1000) km radius")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    // Fee Notice
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").font(.caption).foregroundStyle(.orange)
                        Text("A 10–15% platform fee applies upon task completion.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08)).clipShape(.rect(cornerRadius: 10))

                    // Accept Button
                    if canAccept {
                        Button {
                            showAcceptConfirmation = true
                        } label: {
                            HStack(spacing: 10) {
                                if isAccepting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "hand.raised.fill")
                                    Text("Accept Task").font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(LinearGradient(
                                colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .foregroundStyle(.white).clipShape(.rect(cornerRadius: 16))
                        }
                        .disabled(isAccepting)
                        .confirmationDialog("Accept this task?", isPresented: $showAcceptConfirmation) {
                            Button("Accept Task") { Task { await acceptTask() } }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("You'll be assigned to \"\(task.title)\" for ₹\(task.budget). A 10–15% platform fee applies on completion.")
                        }
                    }

                    // Accepted confirmation badge
                    if hasAccepted {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("You accepted this task").font(.subheadline.weight(.medium))
                        }
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1)).clipShape(.rect(cornerRadius: 12))
                    }

                    // Open Chat Button — shows after task is accepted
                    if chatIsUnlocked {
                        NavigationLink(destination: chatDestination) {
                            HStack(spacing: 10) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Open Encrypted Chat").font(.headline)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.caption).foregroundStyle(.blue.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(.blue).clipShape(.rect(cornerRadius: 16))
                        }
                        .padding(.horizontal, 0)
                    }

                    // Pay Button
                    if canPay {
                        VStack(spacing: 8) {
                            Button {
                                Task { await initiatePayment() }
                            } label: {
                                HStack(spacing: 10) {
                                    if isPaying {
                                        ProgressView().tint(.white)
                                        Text("Processing...").font(.headline)
                                    } else {
                                        Image(systemName: "indianrupeesign.circle.fill")
                                        Text("Complete Task & Pay ₹\(task.budget)").font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.green, Color.green.opacity(0.8)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white).clipShape(.rect(cornerRadius: 16))
                            }
                            .disabled(isPaying || paymentSuccess)
                            Text("Powered by Razorpay • Test Mode")
                                .font(.caption2).foregroundStyle(.secondary)
                        }

                        if let err = paymentError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                                Text(err).font(.caption).foregroundStyle(.red)
                            }
                            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08)).clipShape(.rect(cornerRadius: 10))
                        }
                    }

                    // Payment Success Banner
                    if paymentSuccess {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Payment Successful!").font(.subheadline.weight(.semibold))
                                Text("Task has been marked as completed.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1)).clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
        }
        .onAppear {
            currentStatus = task.status
        }
        .task { await fetchRecipientKey() }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Map Preview
    private var mapPreview: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))) {
            Annotation(task.title, coordinate: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)) {
                ZStack {
                    Circle().fill(categoryColor.gradient).frame(width: 36, height: 36)
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
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
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading encryption keys...").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Accept Task
    private func acceptTask() async {
        isAccepting = true
        let success = await taskViewModel.acceptTask(taskId: task.id, by: currentUser.name)
        if success {
            hasAccepted = true
            currentStatus = "Accepted"
            await fetchRecipientKey()
        }
        isAccepting = false
    }

    // MARK: - Fetch Recipient Public Key
    private func fetchRecipientKey() async {
        let otherId = isOwner ? task.acceptedById : task.creatorId
        guard let id = otherId else {
            // If acceptedById not set yet, use creatorId as fallback
            if let creatorId = Optional(task.creatorId) {
                if let profile = try? await APIClient.shared.getUserProfile(userId: creatorId.uuidString) {
                    recipientPublicKey = profile.publicKey
                }
            }
            return
        }
        if let profile = try? await APIClient.shared.getUserProfile(userId: id.uuidString) {
            recipientPublicKey = profile.publicKey
        }
    }

    // MARK: - Payment
    private func initiatePayment() async {
        isPaying = true
        paymentError = nil
        do {
            let order = try await APIClient.shared.createPaymentOrder(
                taskId: task.id.uuidString,
                amountPaise: task.budget * 100
            )
            await processTestPayment(order: order)
        } catch {
            paymentError = "Could not initiate payment: \(error.localizedDescription)"
            isPaying = false
        }
    }

    private func processTestPayment(order: PaymentOrderResponse) async {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        let fakePaymentId = "pay_test_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(14))"
        do {
            try await APIClient.shared.verifyPayment(
                taskId: task.id.uuidString,
                orderId: order.razorpayOrderId,
                paymentId: fakePaymentId,
                signature: "test_signature_bypass"
            )
            await MainActor.run {
                paymentSuccess = true
                currentStatus = "Completed"
                isPaying = false
            }
        } catch {
            await MainActor.run {
                paymentError = "Payment verification failed: \(error.localizedDescription)"
                isPaying = false
            }
        }
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
