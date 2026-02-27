// MARK: - TaskDetailView.swift
import SwiftUI
import MapKit

struct TaskDetailView: View {
    let task: TaskResponse
    @Bindable var taskViewModel: TaskViewModel
    let currentUser: UserResponse
    @Environment(\.dismiss) private var dismiss

    @State private var showAcceptConfirmation: Bool = false
    @State private var showPaymentConfirmation: Bool = false
    @State private var hasAccepted: Bool = false
    @State private var isAccepting: Bool = false
    @State private var isPaying: Bool = false
    @State private var recipientPublicKey: String? = nil
    @State private var otherUserProfile: UserProfileResponse? = nil
    @State private var paymentError: String? = nil
    @State private var paymentSuccess: Bool = false
    @State private var currentStatus: String = ""
    @State private var showChat: Bool = false
    
    // Mock unread count for UI purposes
    @State private var unreadMessagesCount: Int = Int.random(in: 0...3)

    private var categoryColor: Color {
        switch task.category {
        case "Academic": return .blue
        case "Roadside Help": return .red
        case "Labor": return .orange
        default: return .purple
        }
    }

    private var statusColor: Color {
        switch currentStatus {
        case "Active": return .green
        case "Accepted": return Color(red: 1.0, green: 0.45, blue: 0.0) // Orange
        case "Completed": return .gray
        default: return .red
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
            VStack(spacing: 0) {
                mapPreview

                VStack(spacing: 20) {
                    
                    // Main Task Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.title)
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                                HStack(spacing: 8) {
                                    Label(task.category, systemImage: categoryIcon)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(categoryColor)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(categoryColor.opacity(0.12))
                                        .clipShape(.capsule)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("₹\(task.budget)")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                                if task.isNegotiable {
                                    Text("Negotiable")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color(.systemGray5)).clipShape(.capsule)
                                }
                            }
                        }

                        Text(task.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                    .padding(.top, -24) // Overlap the map
                    
                    // Task Timeline
                    TaskTimelineView(status: currentStatus)
                        .padding(.horizontal, 4)

                    // Profile Card (Creator or Acceptor)
                    if let profile = otherUserProfile {
                        UserProfileCardView(
                            title: isOwner ? "Task Accepted By" : "Task Posted By",
                            profile: profile
                        )
                    } else if !isOwner {
                        // Fallback Creator Info if profile not loaded yet
                        HStack {
                            Image(systemName: "person.circle.fill").font(.title).foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text("Posted by").font(.caption).foregroundStyle(.secondary)
                                Text(task.creatorName).font(.subheadline.weight(.semibold))
                            }
                            Spacer()
                            ProgressView()
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    // Action Buttons Area
                    VStack(spacing: 12) {
                        
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
                                        Text("Accept Task").font(.system(.headline, design: .rounded, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .foregroundStyle(.white).clipShape(.capsule)
                                .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(isAccepting)
                            .confirmationDialog("Accept this task?", isPresented: $showAcceptConfirmation) {
                                Button("Accept Task") { Task { await acceptTask() } }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("You'll be assigned to \"\(task.title)\" for ₹\(task.budget). A 10–15% platform fee applies on completion.")
                            }
                        }

                        // Open Chat Button
                        if chatIsUnlocked {
                            Button {
                                unreadMessagesCount = 0 // clear mock badge
                                showChat = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.fill").font(.caption).foregroundStyle(.green)
                                    Text("Encrypted Chat").font(.system(.headline, design: .rounded, weight: .bold))
                                    Spacer()
                                    
                                    if unreadMessagesCount > 0 {
                                        Text("\(unreadMessagesCount) New")
                                            .font(.caption2.weight(.bold))
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(.red).foregroundStyle(.white)
                                            .clipShape(.capsule)
                                    } else {
                                        Image(systemName: "chevron.right").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity).padding(.horizontal, 20).padding(.vertical, 16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(.primary)
                                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                            }
                        }

                        // Pay Button
                        if canPay {
                            Button {
                                showPaymentConfirmation = true
                            } label: {
                                HStack(spacing: 10) {
                                    if isPaying {
                                        ProgressView().tint(.white)
                                        Text("Processing...").font(.headline)
                                    } else {
                                        Image(systemName: "indianrupeesign.circle.fill")
                                        Text("Complete & Pay ₹\(task.budget)")
                                            .font(.system(.headline, design: .rounded, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color.black)
                                .foregroundStyle(.white).clipShape(.capsule)
                                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                            }
                            .disabled(isPaying || paymentSuccess)
                            .confirmationDialog("Confirm Payment", isPresented: $showPaymentConfirmation) {
                                Button("Pay ₹\(task.budget)") { Task { await initiatePayment() } }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("You are about to transfer ₹\(task.budget) to the task acceptor. This action cannot be undone.")
                            }
                            
                            Text("Powered by Razorpay • Test Mode")
                                .font(.caption2).foregroundStyle(.secondary)

                            if let err = paymentError {
                                Text(err).font(.caption).foregroundStyle(.red)
                                    .padding(10).background(Color.red.opacity(0.1)).clipShape(.rect(cornerRadius: 8))
                            }
                        }

                        // Payment Success
                        if paymentSuccess {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.title3)
                                VStack(alignment: .leading) {
                                    Text("Payment Successful!").font(.subheadline.weight(.semibold))
                                    Text("Task marked as completed.").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(16).background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 30)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            currentStatus = task.status
            Task { await fetchOtherUserProfile() }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showChat) {
            NavigationStack {
                Group {
                    if let pubKey = recipientPublicKey {
                        ChatView(taskId: task.id, currentUserId: currentUser.id, recipientPublicKey: pubKey)
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading encryption keys...")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .task { await fetchOtherUserProfile() }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Map Preview
    private var mapPreview: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))) {
            Annotation(task.title, coordinate: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)) {
                ZStack {
                    Circle().fill(categoryColor.gradient).frame(width: 36, height: 36).shadow(radius: 4)
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                }
            }
        }
        .mapStyle(.standard).frame(height: 250).allowsHitTesting(false)
    }

    // MARK: - API Calls
    private func acceptTask() async {
        isAccepting = true
        // ✅ FIXED: Passed currentUser here instead of currentUser.name
        let success = await taskViewModel.acceptTask(taskId: task.id, by: currentUser)
        if success {
            hasAccepted = true
            currentStatus = "Accepted"
            await fetchOtherUserProfile()
        }
        isAccepting = false
    }

    private func fetchOtherUserProfile() async {
        let targetId: UUID?
        if isOwner {
            targetId = task.acceptedById
        } else {
            targetId = task.creatorId
        }
        
        guard let uid = targetId else { return }
        
        if let profile = try? await APIClient.shared.getUserProfile(userId: uid.uuidString) {
            await MainActor.run {
                self.otherUserProfile = profile
                self.recipientPublicKey = profile.publicKey
            }
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

// MARK: - Subviews

struct TaskTimelineView: View {
    let status: String
    
    private var step2Active: Bool { status == "Accepted" || status == "Completed" }
    private var step3Active: Bool { status == "Completed" }
    
    var body: some View {
        HStack(spacing: 0) {
            TimelineNode(title: "Active", icon: "megaphone.fill", isActive: true, isCompleted: step2Active)
            TimelineLine(isActive: step2Active)
            TimelineNode(title: "Accepted", icon: "hand.raised.fill", isActive: step2Active, isCompleted: step3Active)
            TimelineLine(isActive: step3Active)
            TimelineNode(title: "Completed", icon: "checkmark.seal.fill", isActive: step3Active, isCompleted: false)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}

struct TimelineNode: View {
    let title: String
    let icon: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isActive ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color(.systemGray5))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isCompleted ? "checkmark" : icon)
                    .font(.system(size: 14, weight: .bold))
                    // FIX: Wrapped in AnyShapeStyle to match types
                    .foregroundStyle(isActive ? AnyShapeStyle(.white) : AnyShapeStyle(.tertiary))
            }
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isActive ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TimelineLine: View {
    let isActive: Bool
    var body: some View {
        Rectangle()
            .fill(isActive ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color(.systemGray5))
            .frame(height: 3)
            .offset(y: -12) // Align with circles
    }
}

struct UserProfileCardView: View {
    let title: String
    let profile: UserProfileResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    Text(String(profile.name.prefix(1)).uppercased())
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                            Text(String(format: "%.1f", profile.rating)).font(.caption.weight(.semibold))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption)
                            Text("\(profile.tasksCompleted) tasks").font(.caption.weight(.semibold))
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}
