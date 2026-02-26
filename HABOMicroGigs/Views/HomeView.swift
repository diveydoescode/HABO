// MARK: - HomeView.swift
import SwiftUI
import MapKit

struct HomeView: View {
    @Bindable var taskViewModel: TaskViewModel
    @Bindable var locationService: LocationService
    let currentUser: UserResponse

    @State private var showMapView: Bool = true
    @State private var mapPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedTaskForDetail: TaskResponse?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if showMapView { mapContent } else { listContent }
                viewToggle.padding(.top, 8)
            }
            .navigationTitle("HABO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill").font(.caption).foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                        Text(locationService.placeName).font(.subheadline.weight(.medium))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All Categories") {
                            taskViewModel.filterCategory = nil
                            Task { await taskViewModel.fetchTasks(location: locationService.location) }
                        }
                        ForEach(TaskCategory.allCases) { category in
                            Button {
                                taskViewModel.filterCategory = category.rawValue
                                Task { await taskViewModel.fetchTasks(location: locationService.location) }
                            } label: {
                                Label(category.rawValue, systemImage: category.icon)
                            }
                        }
                    } label: {
                        Image(systemName: taskViewModel.filterCategory != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundStyle(taskViewModel.filterCategory != nil ? Color(red: 1.0, green: 0.45, blue: 0.0) : .primary)
                    }
                }
            }
            .sheet(item: $selectedTaskForDetail) { task in
                NavigationStack {
                    TaskDetailView(task: task, taskViewModel: taskViewModel, currentUser: currentUser)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .task { await taskViewModel.fetchTasks(location: locationService.location) }
            .refreshable { await taskViewModel.fetchTasks(location: locationService.location) }
        }
    }

    private var viewToggle: some View {
        HStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.35)) { showMapView = true } } label: {
                Label("Map", systemImage: "map.fill").font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(showMapView ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color(.secondarySystemBackground))
                    .foregroundStyle(showMapView ? .white : .secondary)
            }
            Button { withAnimation(.spring(response: 0.35)) { showMapView = false } } label: {
                Label("List", systemImage: "list.bullet").font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(!showMapView ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color(.secondarySystemBackground))
                    .foregroundStyle(!showMapView ? .white : .secondary)
            }
        }
        .clipShape(.capsule).shadow(color: .black.opacity(0.15), radius: 8, y: 4).zIndex(1)
        .sensoryFeedback(.selection, trigger: showMapView)
    }

    private var mapContent: some View {
        Map(position: $mapPosition) {
            UserAnnotation()
            ForEach(taskViewModel.activeTasks) { task in
                Annotation(task.title, coordinate: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude)) {
                    Button { selectedTaskForDetail = task } label: {
                        TaskMapPin(category: task.category)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls { MapUserLocationButton(); MapCompass() }
        .ignoresSafeArea(edges: .bottom)
    }

    private var listContent: some View {
        Group {
            if taskViewModel.isLoading {
                VStack { Spacer(); ProgressView().tint(Color(red: 1.0, green: 0.45, blue: 0.0)); Spacer() }
            } else if taskViewModel.activeTasks.isEmpty {
                ContentUnavailableView("No Tasks Nearby", systemImage: "mappin.slash",
                                        description: Text("No tasks exist within your area. Be the first to post one!"))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Color.clear.frame(height: 44)
                        ForEach(taskViewModel.activeTasks) { task in
                            Button { selectedTaskForDetail = task } label: {
                                TaskCardView(task: task)
                            }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Subviews

struct TaskMapPin: View {
    let category: String
    private var pinColor: Color {
        switch category {
        case "Academic": return .blue
        case "Roadside Help": return .red
        case "Labor": return .orange
        default: return .purple
        }
    }
    private var icon: String {
        switch category {
        case "Academic": return "book.fill"
        case "Roadside Help": return "car.fill"
        case "Labor": return "hammer.fill"
        default: return "star.fill"
        }
    }
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().fill(pinColor.gradient).frame(width: 40, height: 40).shadow(color: pinColor.opacity(0.4), radius: 6, y: 3)
                Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            }
            Image(systemName: "triangle.fill").font(.system(size: 10)).foregroundStyle(pinColor).rotationEffect(.degrees(180)).offset(y: -3)
        }
    }
}

struct TaskCardView: View {
    let task: TaskResponse
    private var categoryColor: Color {
        switch task.category {
        case "Academic": return .blue
        case "Roadside Help": return .red
        case "Labor": return .orange
        default: return .purple
        }
    }
    private var categoryIcon: String {
        switch task.category {
        case "Academic": return "book.fill"
        case "Roadside Help": return "car.fill"
        case "Labor": return "hammer.fill"
        default: return "star.fill"
        }
    }
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(categoryColor.opacity(0.12)).frame(width: 50, height: 50)
                Image(systemName: categoryIcon).font(.title3).foregroundStyle(categoryColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.headline).foregroundStyle(.primary).lineLimit(1)
                HStack(spacing: 6) {
                    Text(task.category).font(.caption.weight(.medium)).foregroundStyle(categoryColor)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(categoryColor.opacity(0.1)).clipShape(.capsule)
                    Text("by \(task.creatorName)").font(.caption).foregroundStyle(.secondary)
                }
                Text(task.createdAt.formatted(.relative(presentation: .named))).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(task.budget)").font(.title3.weight(.bold)).foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                if task.isNegotiable { Text("Negotiable").font(.caption2).foregroundStyle(.secondary) }
            }
        }
        .padding(14).background(Color(.secondarySystemBackground)).clipShape(.rect(cornerRadius: 16))
    }
}
