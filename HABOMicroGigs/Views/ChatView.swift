// MARK: - ChatView.swift
// ✅ NEW FILE — Add to HABOMicroGigs/Views/ChatView.swift
// Presented from TaskDetailView after a task is accepted

import SwiftUI

struct ChatView: View {
    let taskId: UUID
    let currentUserId: UUID
    let recipientPublicKey: String      // Fetched from recipient's profile

    @State private var messages: [MessageResponse] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var pollingTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 0) {
            // E2EE badge
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.green)
                Text("End-to-end encrypted").font(.caption2).foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.08))

            if isLoading {
                Spacer()
                ProgressView().tint(Color(red: 1.0, green: 0.45, blue: 0.0))
                Spacer()
            } else {
                messageList
            }

            inputBar
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadMessages() }
            startPolling()
        }
        .onDisappear { pollingTask?.cancel() }
    }

    // MARK: - Message List
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { msg in
                        MessageBubble(
                            message: msg,
                            isMine: msg.senderId == currentUserId
                        )
                        .id(msg.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $inputText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(.capsule)

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color(.systemGray4)
                                     : Color(red: 1.0, green: 0.45, blue: 0.0))
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Logic
    private func loadMessages() async {
        do {
            var fetched = try await APIClient.shared.getMessages(taskId: taskId.uuidString)
            // Decrypt each message locally
            fetched = fetched.map { msg in
                var m = msg
                if msg.senderId != currentUserId {
                    m.plaintext = try? CryptoService.shared.decrypt(
                        ciphertextB64: msg.ciphertext,
                        nonceB64: msg.nonce,
                        senderPublicKeyB64: recipientPublicKey
                    )
                } else {
                    // Own messages: we stored encrypted but can display from local input
                    m.plaintext = msg.plaintext ?? "🔒"
                }
                return m
            }
            messages = fetched
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isSending = true
        inputText = ""

        do {
            let encrypted = try CryptoService.shared.encrypt(plaintext: text, recipientPublicKeyB64: recipientPublicKey)
            var sent = try await APIClient.shared.sendMessage(
                taskId: taskId.uuidString,
                ciphertext: encrypted.ciphertext,
                nonce: encrypted.nonce
            )
            sent.plaintext = text   // Show our own message in plaintext locally
            messages.append(sent)
        } catch {
            inputText = text       // Restore on failure
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    private func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                await loadMessages()
            }
        }
    }
}

struct MessageBubble: View {
    let message: MessageResponse
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 60) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(message.plaintext ?? "🔒 Encrypted")
                    .font(.body)
                    .foregroundStyle(isMine ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMine ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color(.secondarySystemBackground))
                    .clipShape(.rect(
                        topLeadingRadius: 18, bottomLeadingRadius: isMine ? 18 : 4,
                        bottomTrailingRadius: isMine ? 4 : 18, topTrailingRadius: 18
                    ))

                Text(message.sentAt.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if !isMine { Spacer(minLength: 60) }
        }
    }
}
