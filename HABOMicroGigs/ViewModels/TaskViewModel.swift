import Foundation
import CoreLocation

@Observable
class TaskViewModel {
    var tasks: [GigTask] = []
    var selectedTask: GigTask?
    var filterCategory: TaskCategory?

    var activeTasks: [GigTask] {
        let active = tasks.filter { $0.status == .active }
        if let filter = filterCategory {
            return active.filter { $0.category == filter }
        }
        return active
    }

    func addTask(_ task: GigTask) {
        tasks.insert(task, at: 0)
    }

    func acceptTask(_ taskId: UUID, by userName: String) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].status = .accepted
        tasks[index].acceptedBy = userName
    }

    func cancelTask(_ taskId: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].status = .cancelled
    }

    func tasksPostedBy(_ name: String) -> [GigTask] {
        tasks.filter { $0.creatorName == name }
    }

    func tasksAcceptedBy(_ name: String) -> [GigTask] {
        tasks.filter { $0.acceptedBy == name }
    }
}
