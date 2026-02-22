import Foundation
import CoreLocation

nonisolated enum TaskCategory: String, CaseIterable, Identifiable, Sendable {
    case academic = "Academic"
    case roadsideHelp = "Roadside Help"
    case labor = "Labor"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .academic: return "book.fill"
        case .roadsideHelp: return "car.fill"
        case .labor: return "hammer.fill"
        case .custom: return "star.fill"
        }
    }

    var tintColor: String {
        switch self {
        case .academic: return "blue"
        case .roadsideHelp: return "red"
        case .labor: return "orange"
        case .custom: return "purple"
        }
    }
}

nonisolated enum TaskStatus: String, Sendable {
    case active = "Active"
    case accepted = "Accepted"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

struct GigTask: Identifiable, Sendable {
    let id: UUID
    var title: String
    var category: TaskCategory
    var description: String
    var budget: Int
    var isNegotiable: Bool
    var latitude: Double
    var longitude: Double
    var status: TaskStatus
    var createdAt: Date
    var creatorName: String
    var acceptedBy: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory,
        description: String,
        budget: Int,
        isNegotiable: Bool,
        latitude: Double,
        longitude: Double,
        status: TaskStatus = .active,
        createdAt: Date = Date(),
        creatorName: String,
        acceptedBy: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.description = description
        self.budget = budget
        self.isNegotiable = isNegotiable
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.createdAt = createdAt
        self.creatorName = creatorName
        self.acceptedBy = acceptedBy
    }
}
