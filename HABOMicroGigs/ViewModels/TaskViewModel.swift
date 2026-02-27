// MARK: - TaskViewModel.swift
import Foundation
import CoreLocation

@Observable
class TaskViewModel {
    var tasks: [TaskResponse] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var filterCategory: String? = nil

    var activeTasks: [TaskResponse] {
        let active = tasks.filter { $0.status == "Active" }
        if let filter = filterCategory {
            return active.filter { $0.category == filter }
        }
        return active
    }

    // MARK: - Fetch tasks for viewer's location
    func fetchTasks(location: CLLocation?) async {
        isLoading = true
        errorMessage = nil
        // Default to Jaipur if no location yet
        let lat = location?.coordinate.latitude ?? 26.9124
        let lon = location?.coordinate.longitude ?? 75.7873

        do {
            tasks = try await APIClient.shared.getTasks(
                lat: lat,
                lon: lon,
                category: filterCategory
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Post new task
    func addTask(
        title: String,
        category: String,
        description: String,
        budget: Int,
        isNegotiable: Bool,
        latitude: Double,
        longitude: Double,
        radiusMetres: Int
    ) async -> Bool {
        do {
            let request = TaskCreateRequest(
                title: title,
                category: category,
                description: description,
                budget: budget,
                isNegotiable: isNegotiable,
                latitude: latitude,
                longitude: longitude,
                radiusMetres: radiusMetres
            )
            let newTask = try await APIClient.shared.postTask(request)
            tasks.insert(newTask, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Accept task (unlocks chat)
    // ✅ FIXED: Now takes the full UserResponse to grab your correct ID
    func acceptTask(taskId: UUID, by user: UserResponse) async -> Bool {
        do {
            let response = try await APIClient.shared.acceptTask(taskId: taskId.uuidString)
            // Update local state to reflect accepted status
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                // TaskResponse is a struct so we rebuild it with updated status
                let old = tasks[index]
                tasks[index] = TaskResponse(
                    id: old.id, title: old.title, category: old.category,
                    description: old.description, budget: old.budget,
                    isNegotiable: old.isNegotiable, latitude: old.latitude,
                    longitude: old.longitude, radiusMetres: old.radiusMetres,
                    status: response.status, createdAt: old.createdAt,
                    creatorName: old.creatorName, creatorId: old.creatorId,
                    acceptedById: user.id // ✅ Correctly sets your User ID locally!
                )
            }
            return response.chatUnlocked
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Complete task (triggers payment flow)
    func completeTask(taskId: UUID) async -> Bool {
        do {
            let updated = try await APIClient.shared.completeTask(taskId: taskId.uuidString)
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[index] = updated
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func tasksPostedBy(userId: UUID) -> [TaskResponse] {
        tasks.filter { $0.creatorId == userId }
    }

    func tasksAcceptedBy(userId: UUID) -> [TaskResponse] {
        tasks.filter { $0.acceptedById == userId }
    }
}
