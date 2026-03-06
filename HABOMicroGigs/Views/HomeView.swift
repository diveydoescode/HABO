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
    
    // ✅ This namespace drives the fluid sliding animation for the filters
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if showMapView {
                    // ✅ NEW: ZStack added here to overlay the refresh button on the map
                    ZStack(alignment: .bottomTrailing) {
                        mapContent
                        
                        // Floating Refresh Button
                        Button {
                            Task {
                                await taskViewModel.fetchTasks(location: locationService.location)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(Color(red: 1.0, green: 0.45, blue: 0.0))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 40) // Keeps it from overlapping Apple's map controls
                        .opacity(taskViewModel.isLoading ? 0.5 : 1.0)
                        .disabled(taskViewModel.isLoading)
                    }
                } else {
                    listContent
                }
            }
            .navigationTitle("HABO")
            .navigationBarTitleDisplayMode(.inline)
            // ✅ Removed the bulky location toolbar item completely
            .safeAreaInset(edge: .top) {
                // Top controls (Categories + View Toggle) floating over map/list
                VStack(spacing: 12) {
                    categoryPills
                    viewToggle
                }
                .padding(.bottom, 12)
                .background(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
            }
            .sheet(item: $selectedTaskForDetail) { task in
                NavigationStack {
                    TaskDetailView(task: task, taskViewModel: taskViewModel, currentUser: currentUser)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .task { await taskViewModel.fetchTasks(location: locationService.location) }
        }
    }

    // MARK: - Category Pills (Fluid Animation)
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" Pill
                CategoryPillView(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    color: Color(red: 1.0, green: 0.45, blue: 0.0), // HABO Orange
                    count: taskViewModel.tasks.filter { $0.status == "Active" }.count,
                    isSelected: taskViewModel.filterCategory == nil,
                    animation: animation
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        taskViewModel.filterCategory = nil
                    }
                    Task { await taskViewModel.fetchTasks(location: locationService.location) }
                }

                // Dynamic Categories
                ForEach(TaskCategory.allCases) { category in
                    CategoryPillView(
                        title: category.rawValue,
                        icon: category.icon,
                        color: categoryColor(category.rawValue),
                        count: taskViewModel.tasks.filter { $0.status == "Active" && $0.category == category.rawValue }.count,
                        isSelected: taskViewModel.filterCategory == category.rawValue,
                        animation: animation
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            taskViewModel.filterCategory = category.rawValue
                        }
                        Task { await taskViewModel.fetchTasks(location: locationService.location) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Map / List Toggle
    private var viewToggle: some View {
        HStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.35)) { showMapView = true } } label: {
                Label("Map", systemImage: "map.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(showMapView ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color.clear)
                    .foregroundStyle(showMapView ? .white : .secondary)
            }
            Button { withAnimation(.spring(response: 0.35)) { showMapView = false } } label: {
                Label("List", systemImage: "list.bullet")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(!showMapView ? Color(red: 1.0, green: 0.45, blue: 0.0) : Color.clear)
                    .foregroundStyle(!showMapView ? .white : .secondary)
            }
        }
        .frame(width: 240)
        .background(Color(.secondarySystemBackground))
        .clipShape(.capsule)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .sensoryFeedback(.selection, trigger: showMapView)
    }

    // MARK: - Map Content
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
    }

    // MARK: - List Content
    private var listContent: some View {
        Group {
            if taskViewModel.isLoading {
                VStack { Spacer(); ProgressView().tint(Color(red: 1.0, green: 0.45, blue: 0.0)); Spacer() }
            } else if taskViewModel.activeTasks.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(taskViewModel.activeTasks) { task in
                            Button { selectedTaskForDetail = task } label: {
                                TaskCardView(task: task, currentLocation: locationService.location)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .refreshable { await taskViewModel.fetchTasks(location: locationService.location) }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.1)).frame(width: 120, height: 120)
                Image(systemName: "mappin.slash.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
            }
            VStack(spacing: 8) {
                Text("No tasks near you yet")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("Be the first to post a gig in your area and get help from locals.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                NotificationCenter.default.post(name: NSNotification.Name("SwitchToPostTab"), object: nil)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Post a Task")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color(red: 1.0, green: 0.45, blue: 0.0))
                .clipShape(.capsule)
                .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.3), radius: 8, y: 4)
            }
            .padding(.top, 12)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Academic": return .blue
        case "Roadside Help": return .red
        case "Labor": return .orange
        default: return .purple
        }
    }
}

// MARK: - Subviews

struct CategoryPillView: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int
    let isSelected: Bool
    let animation: Namespace.ID // ✅ Passed in for the slide effect
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).font(.system(.subheadline, design: .rounded, weight: .semibold))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? .white.opacity(0.2) : color.opacity(0.15))
                        .clipShape(.capsule)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : color)
            .background {
                // ✅ The magic sliding background
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(color)
                            .matchedGeometryEffect(id: "pillBackground", in: animation)
                            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
                    } else {
                        Capsule()
                            .fill(Color(.secondarySystemBackground))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

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
    let currentLocation: CLLocation?
    
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
    
    private var distanceString: String {
        guard let loc = currentLocation else { return "Nearby" }
        let taskLoc = CLLocation(latitude: task.latitude, longitude: task.longitude)
        let distance = loc.distance(from: taskLoc)
        if distance < 1000 {
            return "\(Int(distance))m away"
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(categoryColor.opacity(0.12))
                        .frame(width: 54, height: 54)
                    Image(systemName: categoryIcon)
                        .font(.title3)
                        .foregroundStyle(categoryColor)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text(task.title)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 6) {
                        Text(task.category)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(categoryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(categoryColor.opacity(0.1))
                            .clipShape(.capsule)
                        
                        Text("by \(task.creatorName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("₹\(task.budget)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                    
                    if task.isNegotiable {
                        Text("Negotiable")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .clipShape(.capsule)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Label(distanceString, systemImage: "location.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(task.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
