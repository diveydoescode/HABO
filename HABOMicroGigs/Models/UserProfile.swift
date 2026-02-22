import Foundation

struct UserProfile: Sendable {
    let id: UUID
    var name: String
    var email: String
    var avatarURL: String?
    var rating: Double
    var tasksPosted: Int
    var tasksCompleted: Int
    var memberSince: Date

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        avatarURL: String? = nil,
        rating: Double = 5.0,
        tasksPosted: Int = 0,
        tasksCompleted: Int = 0,
        memberSince: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.rating = rating
        self.tasksPosted = tasksPosted
        self.tasksCompleted = tasksCompleted
        self.memberSince = memberSince
    }
}
