// MARK: - APIModels.swift
// HABOMicroGigs/Models/APIModels.swift

import Foundation

// MARK: - Auth
struct GoogleLoginRequest: Encodable {
    let idToken: String
    let publicKey: String
}

struct AuthResponse: Decodable {
    let accessToken: String
    let user: UserResponse
}

// MARK: - User
struct UserResponse: Decodable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let avatarUrl: String?
    let rating: Double
    let tasksPosted: Int
    let tasksCompleted: Int
    let memberSince: Date
    let publicKey: String?
    let followerCount: Int
    let followingCount: Int
}

struct UserSearchResult: Decodable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let avatarUrl: String?
    let rating: Double
    let followerCount: Int
}

struct UserProfileResponse: Decodable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let avatarUrl: String?
    let rating: Double
    let tasksPosted: Int
    let tasksCompleted: Int
    let memberSince: Date
    let publicKey: String?
    let followerCount: Int
    let followingCount: Int
    let isFollowing: Bool
}

struct FollowResponse: Decodable {
    let following: Bool
    let followerCount: Int
}

// MARK: - Tasks
struct TaskCreateRequest: Encodable {
    let title: String
    let category: String
    let description: String
    let budget: Int
    let isNegotiable: Bool
    let latitude: Double
    let longitude: Double
    let radiusMetres: Int
}

struct TaskResponse: Decodable, Identifiable {
    let id: UUID
    let title: String
    let category: String
    let description: String
    let budget: Int
    let isNegotiable: Bool
    let latitude: Double
    let longitude: Double
    let radiusMetres: Int
    let status: String
    let createdAt: Date
    let creatorName: String
    let creatorId: UUID
    let acceptedById: UUID?
}

struct TaskAcceptResponse: Decodable {
    let taskId: UUID
    let acceptedBy: String
    let status: String
    let chatUnlocked: Bool
}

// MARK: - Chat (E2EE)
struct SendMessageRequest: Encodable {
    let taskId: String
    let ciphertext: String
    let nonce: String
}

struct MessageResponse: Decodable, Identifiable {
    let id: UUID
    let taskId: UUID
    let senderId: UUID
    let ciphertext: String
    let nonce: String
    let sentAt: Date
    var plaintext: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, taskId, senderId, ciphertext, nonce, sentAt
    }
}

// MARK: - Payments
struct CreateOrderRequest: Encodable {
    let taskId: String
    let amountPaise: Int
}

struct VerifyPaymentRequest: Encodable {
    let taskId: String
    let razorpayOrderId: String
    let razorpayPaymentId: String
    let razorpaySignature: String
}

struct PaymentOrderResponse: Decodable {
    let razorpayOrderId: String
    let amountPaise: Int
    let currency: String
    let keyId: String
}

// Typealias so TaskDetailView can use either name
typealias RazorpayOrder = PaymentOrderResponse
