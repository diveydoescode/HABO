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

    // MARK: - Fetch tasks
    func fetchTasks(location: CLLocation?) async {
        isLoading = true
        errorMessage = nil
        let lat = location?.coordinate.latitude ?? 26.9124
        let lon = location?.coordinate.longitude ?? 75.7873

        do {
            let mapTasks = try await APIClient.shared.getTasks(lat: lat, lon: lon, category: filterCategory)
            let myTasks = try await APIClient.shared.getMyTasks()
            
            var mergedDict = [UUID: TaskResponse]()
            for t in mapTasks { mergedDict[t.id] = t }
            for t in myTasks { mergedDict[t.id] = t }
            
            self.tasks = mergedDict.values.sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Post new task
    func addTask(title: String, category: String, description: String, budget: Int, isNegotiable: Bool, latitude: Double, longitude: Double, radiusMetres: Int) async -> Bool {
        do {
            let request = TaskCreateRequest(title: title, category: category, description: description, budget: budget, isNegotiable: isNegotiable, latitude: latitude, longitude: longitude, radiusMetres: radiusMetres)
            let newTask = try await APIClient.shared.postTask(request)
            tasks.insert(newTask, at: 0)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Accept task
    func acceptTask(taskId: UUID, by user: UserResponse) async -> String? {
        do {
            let response = try await APIClient.shared.acceptTask(taskId: taskId.uuidString)
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                let old = tasks[index]
                tasks[index] = TaskResponse(
                    id: old.id, title: old.title, category: old.category,
                    description: old.description, budget: old.budget,
                    isNegotiable: old.isNegotiable, latitude: old.latitude,
                    longitude: old.longitude, radiusMetres: old.radiusMetres,
                    status: response.status,
                    completionCode: response.completionCode,
                    createdAt: old.createdAt,
                    creatorName: old.creatorName, creatorId: old.creatorId,
                    acceptedById: user.id
                )
            }
            return response.completionCode
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Complete task
    func completeTask(taskId: UUID, code: String) async -> Bool {
        do {
            let updated = try await APIClient.shared.completeTask(taskId: taskId.uuidString, code: code)
                
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks[index] = updated
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // ✅ NEW: Delete task
    func deleteTask(taskId: UUID) async -> Bool {
        do {
            try await APIClient.shared.deleteTask(taskId: taskId.uuidString)
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                tasks.remove(at: index)
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
