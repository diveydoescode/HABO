// MARK: - APIClient.swift
// HABOMicroGigs/Services/APIClient.swift

import Foundation

let API_BASE_URL = "https://habo-backend.azurewebsites.net"

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .unauthorized: return "Session expired. Please sign in again."
        case .serverError(let msg): return msg
        case .decodingError: return "Could not parse server response"
        }
    }
}

@MainActor
class APIClient {
    static let shared = APIClient()
    private let session = URLSession.shared
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        
        d.dateDecodingStrategy = .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = ISO8601DateFormatter()
            
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot parse date string: \(dateString)"
            )
        }
        return d
    }()
    
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private init() {}

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "habo_access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "habo_access_token") }
    }

    func clearToken() {
        UserDefaults.standard.removeObject(forKey: "habo_access_token")
    }

    private func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(string: "\(API_BASE_URL)\(path)")!
        if !queryItems.isEmpty { components.queryItems = queryItems }

        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.serverError("No response")
        }

        if http.statusCode == 401 {
            clearToken()
            throw APIError.unauthorized
        }
        if !(200...299).contains(http.statusCode) {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
                ?? "Server error \(http.statusCode)"
            throw APIError.serverError(msg)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
    }

    // MARK: - Auth
    func loginWithGoogle(idToken: String, publicKey: String) async throws -> AuthResponse {
        try await request("POST", path: "/auth/login", body: GoogleLoginRequest(idToken: idToken, publicKey: publicKey))
    }

    func getMe() async throws -> UserResponse {
        try await request("GET", path: "/auth/me")
    }

    // MARK: - Tasks
    func getTasks(lat: Double, lon: Double, category: String? = nil) async throws -> [TaskResponse] {
        var items = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon))
        ]
        if let cat = category { items.append(URLQueryItem(name: "category", value: cat)) }
        return try await request("GET", path: "/tasks", queryItems: items)
    }

    func getMyTasks() async throws -> [TaskResponse] {
        try await request("GET", path: "/tasks/me")
    }

    func postTask(_ payload: TaskCreateRequest) async throws -> TaskResponse {
        try await request("POST", path: "/tasks", body: payload)
    }

    func acceptTask(taskId: String) async throws -> TaskAcceptResponse {
        try await request("POST", path: "/tasks/\(taskId)/accept")
    }

    // ✅ FIXED: Takes the code here
    func completeTask(taskId: String, code: String) async throws -> TaskResponse {
        try await request(
            "POST",
            path: "/tasks/\(taskId)/complete",
            queryItems: [URLQueryItem(name: "code", value: code)]
        )
    }
    
    // MARK: - Users
    func searchUsers(query: String) async throws -> [UserSearchResult] {
        try await request("GET", path: "/users/search", queryItems: [URLQueryItem(name: "q", value: query)])
    }

    func getUserProfile(userId: String) async throws -> UserProfileResponse {
        try await request("GET", path: "/users/\(userId)")
    }

    func followUser(userId: String) async throws -> FollowResponse {
        try await request("POST", path: "/users/\(userId)/follow")
    }

    func unfollowUser(userId: String) async throws -> FollowResponse {
        try await request("DELETE", path: "/users/\(userId)/follow")
    }

    // MARK: - Chat
    func sendMessage(taskId: String, ciphertext: String, nonce: String) async throws -> MessageResponse {
        try await request("POST", path: "/chat/messages", body: SendMessageRequest(taskId: taskId, ciphertext: ciphertext, nonce: nonce))
    }

    func getMessages(taskId: String) async throws -> [MessageResponse] {
        try await request("GET", path: "/chat/messages/\(taskId)")
    }

    // MARK: - Payments
    func createPaymentOrder(taskId: String, amountPaise: Int) async throws -> PaymentOrderResponse {
        try await request("POST", path: "/payments/create-order", body: CreateOrderRequest(taskId: taskId, amountPaise: amountPaise))
    }

    func verifyPayment(taskId: String, orderId: String, paymentId: String, signature: String) async throws {
        let _: [String: Bool] = try await request(
            "POST", path: "/payments/verify",
            body: VerifyPaymentRequest(taskId: taskId, razorpayOrderId: orderId, razorpayPaymentId: paymentId, razorpaySignature: signature)
        )
    }
}
