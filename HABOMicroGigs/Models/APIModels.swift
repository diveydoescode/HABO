// MARK: - APIModels.swift
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

// MARK: - User & Skills
struct UserSkill: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var proficiency: Int // 1 to 5
    
    enum CodingKeys: String, CodingKey {
        case name
        case proficiency
    }
}

struct ProfileUpdateRequest: Encodable {
    let name: String
    let skills: [UserSkill]
}

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
    let skills: [UserSkill]?
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
    let skills: [UserSkill]?
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
    // ✅ Fields for Circles and Applications
    var circleId: UUID? = nil
    var requiresApplication: Bool = false
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
    let completionCode: String?
    // ✅ Fields for Circles and Applications
    let circleId: UUID?
    let requiresApplication: Bool
    
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
    let completionCode: String
}

// MARK: - Task Applications (NEW)
struct TaskApplicationCreate: Encodable {
    let coverMessage: String?
}

struct TaskApplicationResponse: Decodable, Identifiable {
    let id: UUID
    let taskId: UUID
    let applicantId: UUID
    let status: String
    let coverMessage: String?
    let appliedAt: Date
}

// MARK: - Circles (NEW)
struct Circle: Decodable, Identifiable {
    let id: UUID
    let name: String
    let description: String? // ✅ Added description support
    let adminId: UUID
    let inviteCode: String?  // ✅ Added invite code support
    let createdAt: Date
}

struct InviteCodeResponse: Decodable {
    let code: String
    let expiresInSeconds: Int
}

struct CircleCreateRequest: Encodable {
    let name: String
    let description: String? // ✅ Added description support
}

struct CircleJoinRequest: Encodable {
    let inviteCode: String
}

// MARK: - Chat
struct SendMessageRequest: Encodable {
    let taskId: String
    let ciphertext: String
    let nonce: String
}

struct MessageResponse: Decodable, Identifiable {
    let id: UUID
    let taskId: UUID?
    let senderId: UUID
    let ciphertext: String
    let nonce: String
    let sentAt: Date
    var plaintext: String? = nil
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

typealias RazorpayOrder = PaymentOrderResponse

struct VerifyPaymentResponse: Decodable {
    let success: Bool
    let message: String
}
