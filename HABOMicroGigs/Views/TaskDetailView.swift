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
    
    // ✅ Application States
    @State private var showApplicantsSheet: Bool = false
    @State private var showApplySheet: Bool = false
    @State private var coverMessage: String = ""
    
    @State private var hasAccepted: Bool = false
    @State private var isAccepting: Bool = false
    
    @State private var isPaying: Bool = false
    // ✅ Razorpay Handler
    @StateObject private var razorpayHandler = RazorpayHandler()
    
    @State private var recipientPublicKey: String? = nil
    @State private var otherUserProfile: UserProfileResponse? = nil
    @State private var paymentError: String? = nil
    @State private var paymentSuccess: Bool = false
    @State private var currentStatus: String = ""
    @State private var showChat: Bool = false
    
    @State private var enteredCode: String = ""
    @State private var dynamicCompletionCode: String? = nil
    @State private var unreadMessagesCount: Int = Int.random(in: 0...3)
    
    @State private var showDeleteConfirmation: Bool = false
    @State private var isDeleting: Bool = false

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
        case "Accepted": return Color(red: 1.0, green: 0.45, blue: 0.0)
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
                                    
                                    if task.circleId != nil {
                                        Label("Private Circle", systemImage: "shield.fill")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.blue)
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(Color.blue.opacity(0.12))
                                            .clipShape(.capsule)
                                    }
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
                            
                        if currentStatus != "Completed" {
                            Button {
                                openInAppleMaps()
                            } label: {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("Get Directions")
                                }
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .clipShape(.capsule)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                    .padding(.top, -24)
                    
                    TaskTimelineView(status: currentStatus)
                        .padding(.horizontal, 4)

                    if let profile = otherUserProfile {
                        UserProfileCardView(
                            title: isOwner ? "Task Accepted By" : "Task Posted By",
                            profile: profile
                        )
                    }

                    // Action Buttons Area
                    VStack(spacing: 12) {
                        
                        // ✅ Review Applicants Button (Owner Only)
                        if isOwner && currentStatus == "Active" && task.requiresApplication {
                            Button {
                                showApplicantsSheet = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.2.badge.gearshape.fill")
                                    Text("Review Applicants")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color.purple.opacity(0.1))
                                .foregroundStyle(.purple)
                                .clipShape(.capsule)
                                .overlay(Capsule().stroke(Color.purple.opacity(0.2), lineWidth: 1))
                            }
                        }
                        
                        // ✅ Accept or Apply Button (Seeker Only)
                        if canAccept {
                            Button {
                                if task.requiresApplication {
                                    showApplySheet = true
                                } else {
                                    showAcceptConfirmation = true
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if isAccepting {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: task.requiresApplication ? "paperplane.fill" : "hand.raised.fill")
                                        Text(task.requiresApplication ? "Apply for Task" : "Accept Task")
                                            .font(.system(.headline, design: .rounded, weight: .bold))
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
                                Text("You'll be assigned to \"\(task.title)\" for ₹\(task.budget).")
                            }
                        }

                        if chatIsUnlocked {
                            Button {
                                unreadMessagesCount = 0
                                showChat = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.fill").font(.caption).foregroundStyle(.green)
                                    Text("Encrypted Chat").font(.system(.headline, design: .rounded, weight: .bold))
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.subheadline).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity).padding(.horizontal, 20).padding(.vertical, 16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(.primary)
                                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                            }
                        }

                        if currentStatus == "Accepted" {
                            if !isOwner {
                                VStack(spacing: 8) {
                                    Text("Provide this code to the poster when finished:")
                                        .font(.caption).foregroundStyle(.secondary)
                                    
                                    // ✅ Restored fallback so the code always shows
                                    Text(dynamicCompletionCode ?? task.completionCode ?? "------")
                                        .font(.system(.title, design: .monospaced, weight: .black))
                                        .tracking(10)
                                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                                
                            } else if canPay {
                                VStack(spacing: 12) {
                                    Text("Enter the 6-digit code from the task doer to complete the gig and initiate payment.")
                                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                                        
                                    // ✅ Restored your EXACT UI code for the input field
                                    TextField("000000", text: $enteredCode)
                                        .keyboardType(.numberPad)
                                        .font(.system(.title, design: .monospaced, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    Button {
                                        Task { await initiatePayment() }
                                    } label: {
                                        HStack(spacing: 10) {
                                            if isPaying {
                                                ProgressView().tint(.white)
                                                Text("Verifying...").font(.headline)
                                            } else {
                                                Image(systemName: "checkmark.shield.fill")
                                                Text("Verify Code & Pay ₹\(task.budget)")
                                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                            }
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                                        .background(enteredCode.count == 6 ? Color.black : Color.gray)
                                        .foregroundStyle(.white).clipShape(.capsule)
                                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                                    }
                                    .disabled(isPaying || paymentSuccess || enteredCode.count != 6)
                                }
                                .padding(16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 16, style: .continuous))
                                
                                if let err = paymentError {
                                    Text(err).font(.caption).foregroundStyle(.red)
                                        .padding(10).background(Color.red.opacity(0.1)).clipShape(.rect(cornerRadius: 8))
                                }
                            }
                        }

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
                        
                        if isOwner {
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                HStack(spacing: 10) {
                                    if isDeleting {
                                        ProgressView().tint(.red)
                                    } else {
                                        Image(systemName: "trash.fill")
                                        Text("Delete Task").font(.system(.headline, design: .rounded, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red).clipShape(.capsule)
                            }
                            .disabled(isDeleting)
                            .confirmationDialog("Delete Task?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                                Button("Delete", role: .destructive) {
                                    Task { await deleteThisTask() }
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("Are you sure you want to delete this task? This will also delete any encrypted chat history. This cannot be undone.")
                            }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 30)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            currentStatus = task.status
            dynamicCompletionCode = task.completionCode
            Task { await fetchOtherUserProfile() }
        }
        .navigationBarTitleDisplayMode(.inline)
        // ✅ Sheet for Applicants
        .sheet(isPresented: $showApplicantsSheet) {
            TaskApplicantsView(task: task, onHired: {
                currentStatus = "Accepted"
                Task {
                    await taskViewModel.fetchTasks(location: nil)
                    await fetchOtherUserProfile()
                }
            })
        }
        // ✅ Sheet for Applying
        .sheet(isPresented: $showApplySheet) {
            applicationSheet
        }
        .sheet(isPresented: $showChat) {
            NavigationStack {
                Group {
                    if let pubKey = recipientPublicKey {
                        ChatView(taskId: task.id, currentUserId: currentUser.id, recipientPublicKey: pubKey)
                    } else if otherUserProfile != nil {
                        // ✅ Tell the user exactly what is wrong if the other user has no keys
                        ContentUnavailableView("Encryption Key Missing", systemImage: "key.slash", description: Text("This user is using an old account without encryption. They need to sign out and log back in to generate their keys."))
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
    
    // MARK: - Apply Sheet
    private var applicationSheet: some View {
        NavigationStack {
            Form {
                Section("Cover Message") {
                    TextField("Briefly explain why you're a good fit...", text: $coverMessage, axis: .vertical)
                        .lineLimit(4...6)
                }
                Button("Submit Application") {
                    Task { await submitApplication() }
                }
                .frame(maxWidth: .infinity)
                .font(.headline)
                .listRowBackground(Color(red: 1.0, green: 0.45, blue: 0.0))
                .foregroundStyle(.white)
            }
            .navigationTitle("Apply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showApplySheet = false } }
            }
        }
        .presentationDetents([.medium])
    }

    private func openInAppleMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = task.title
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private var mapPreview: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))) {
            Annotation(task.title, coordinate: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)) {
                ZStack {
                    SwiftUI.Circle().fill(categoryColor.gradient).frame(width: 36, height: 36).shadow(radius: 4)
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                }
            }
        }
        .mapStyle(.standard).frame(height: 250).allowsHitTesting(false)
    }

    private func submitApplication() async {
        isAccepting = true
        do {
            _ = try await APIClient.shared.applyForTask(taskId: task.id.uuidString, coverMessage: coverMessage)
            hasAccepted = true
            showApplySheet = false
        } catch {
            paymentError = error.localizedDescription
        }
        isAccepting = false
    }

    private func acceptTask() async {
        isAccepting = true
        if let newCode = await taskViewModel.acceptTask(taskId: task.id, by: currentUser) {
            hasAccepted = true
            currentStatus = "Accepted"
            dynamicCompletionCode = newCode
            
            await taskViewModel.fetchTasks(location: nil)
            await fetchOtherUserProfile()
        }
        isAccepting = false
    }

    private func fetchOtherUserProfile() async {
        // ✅ FIXED: Get the absolute most up-to-date version of this task from the ViewModel.
        // This ensures that right after you hire an applicant, we know exactly who the `acceptedById` is!
        let freshestTask = taskViewModel.tasks.first(where: { $0.id == task.id }) ?? task
        
        let targetId: UUID?
        if isOwner {
            targetId = freshestTask.acceptedById
        } else {
            targetId = freshestTask.creatorId
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
        // Dismiss keyboard so Razorpay UI can slide up properly
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isPaying = true
        paymentError = nil
        
        let verified = await taskViewModel.completeTask(taskId: task.id, code: enteredCode)
        
        guard verified else {
            paymentError = "Verification Failed. Check the 6-digit code."
            isPaying = false
            return
        }
        
        do {
            let order = try await APIClient.shared.createPaymentOrder(
                taskId: task.id.uuidString,
                amountPaise: task.budget * 100
            )
            
            razorpayHandler.onSuccess = { paymentId, orderId, signature in
                Task {
                    await finalizeVerificationWithBackend(paymentId: paymentId, orderId: orderId, signature: signature)
                }
            }
            
            razorpayHandler.onError = { errorString in
                self.paymentError = errorString
                self.isPaying = false
            }
            
            // ✅ ADDED: Give the UI 0.4 seconds to let the keyboard finish dropping down completely so Razorpay isn't blocked
            try? await Task.sleep(nanoseconds: 400_000_000)
            
            // Safely passes the API key sent dynamically from Azure
            razorpayHandler.startPayment(
                orderId: order.razorpayOrderId,
                amountPaise: order.amountPaise,
                keyId: order.keyId,
                email: currentUser.email,
                contact: "9999999999"
            )
            
        } catch {
            paymentError = "Could not initiate payment: \(error.localizedDescription)"
            isPaying = false
        }
    }

    private func finalizeVerificationWithBackend(paymentId: String, orderId: String, signature: String) async {
        do {
            try await APIClient.shared.verifyPayment(
                taskId: task.id.uuidString,
                orderId: orderId,
                paymentId: paymentId,
                signature: signature
            )
            await MainActor.run {
                paymentSuccess = true
                currentStatus = "Completed"
                isPaying = false
            }
        } catch {
            await MainActor.run {
                paymentError = "Payment Verification Failed: \(error.localizedDescription)"
                isPaying = false
            }
        }
    }
    
    private func deleteThisTask() async {
        isDeleting = true
        let success = await taskViewModel.deleteTask(taskId: task.id)
        if success {
            dismiss()
        } else {
            paymentError = "Failed to delete task."
        }
        isDeleting = false
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
                SwiftUI.Circle()
                    .fill(isActive ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color(.systemGray5))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isCompleted ? "checkmark" : icon)
                    .font(.system(size: 14, weight: .bold))
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
            .offset(y: -12)
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
                ZStack {
                    SwiftUI.Circle()
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
