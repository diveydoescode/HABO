// MARK: - ChatView.swift
import SwiftUI

struct ChatView: View {
    let taskId: UUID
    let currentUserId: UUID
    let recipientPublicKey: String

    @State private var messages: [MessageResponse] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var pollingTask: Task<Void, Never>? = nil
    
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.green)
                Text("End-to-end encrypted").font(.caption2.weight(.medium)).foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8).background(Color.green.opacity(0.1))

            if isLoading {
                Spacer()
                ProgressView().tint(Color(red: 1.0, green: 0.45, blue: 0.0))
                Spacer()
            } else {
                messageList
            }

            if let err = errorMessage {
                Text(err)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.red.opacity(0.8))
                    .clipShape(.capsule)
                    .padding(.bottom, 4)
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

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg, isMine: msg.senderId == currentUserId).id(msg.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count) { _, _ in scrollToBottom(proxy: proxy) }
            .onChange(of: isInputFocused) { _, isFocused in
                if isFocused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { scrollToBottom(proxy: proxy) }
                }
            }
        }
        .onTapGesture { isInputFocused = false }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(lastId, anchor: .bottom) }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message...", text: $inputText, axis: .vertical)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(.rect(cornerRadius: 20, style: .continuous))

            Button {
                Task { await sendMessage() }
            } label: {
                ZStack {
                    Circle()
                        .fill(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color(.systemGray5) : Color(red: 1.0, green: 0.45, blue: 0.0))
                        .frame(width: 44, height: 44)
                    
                    if isSending {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color(.systemGray) : .white)
                    }
                }
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color(.systemBackground).shadow(color: .black.opacity(0.05), radius: 5, y: -2))
    }

    private func loadMessages() async {
        do {
            var fetched = try await APIClient.shared.getMessages(taskId: taskId.uuidString)
            fetched = fetched.map { msg in
                var m = msg
                if msg.senderId != currentUserId {
                    m.plaintext = try? CryptoService.shared.decrypt(ciphertextB64: msg.ciphertext, nonceB64: msg.nonce, senderPublicKeyB64: recipientPublicKey)
                } else {
                    // ✅ Looks up your own sent messages from device memory!
                    m.plaintext = getCachedText(for: msg.id) ?? "🔒"
                }
                return m
            }
            
            if messages.count != fetched.count {
                await MainActor.run { messages = fetched }
            }
        } catch { }
        isLoading = false
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isSending = true
        errorMessage = nil
        let tempText = inputText
        inputText = ""

        do {
            let encrypted = try CryptoService.shared.encrypt(plaintext: text, recipientPublicKeyB64: recipientPublicKey)
            var sent = try await APIClient.shared.sendMessage(
                taskId: taskId.uuidString,
                ciphertext: encrypted.ciphertext,
                nonce: encrypted.nonce
            )
            sent.plaintext = text
            // ✅ Saves the text you just typed to the device memory
            cacheText(text, for: sent.id)
            messages.append(sent)
            isSending = false
        } catch {
            inputText = tempText
            errorMessage = error.localizedDescription
            isSending = false
        }
    }

    private func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                await loadMessages()
            }
        }
    }
    
    // MARK: - Local Message Cache
    private func getCachedText(for id: UUID) -> String? {
        let cache = UserDefaults.standard.dictionary(forKey: "habo_sent_messages") as? [String: String] ?? [:]
        return cache[id.uuidString]
    }
    
    private func cacheText(_ text: String, for id: UUID) {
        var cache = UserDefaults.standard.dictionary(forKey: "habo_sent_messages") as? [String: String] ?? [:]
        cache[id.uuidString] = text
        UserDefaults.standard.set(cache, forKey: "habo_sent_messages")
    }
}

struct MessageBubble: View {
    let message: MessageResponse
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 50) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(message.plaintext ?? "🔒")
                    .font(.body)
                    .foregroundStyle(isMine ? .white : .primary)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(isMine ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color(.secondarySystemBackground))
                    .clipShape(.rect(topLeadingRadius: 20, bottomLeadingRadius: isMine ? 20 : 4, bottomTrailingRadius: isMine ? 4 : 20, topTrailingRadius: 20))
                    .shadow(color: isMine ? .clear : .black.opacity(0.03), radius: 2, y: 1)
                Text(message.sentAt.formatted(.dateTime.hour().minute()))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
            }
            if !isMine { Spacer(minLength: 50) }
        }
    }
}
