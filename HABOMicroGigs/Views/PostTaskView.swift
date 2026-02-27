// MARK: - PostTaskView.swift
import SwiftUI
import MapKit

struct PostTaskView: View {
    @Bindable var taskViewModel: TaskViewModel
    @Bindable var locationService: LocationService
    let userName: String
    let onDismiss: () -> Void

    @State private var title: String = ""
    @State private var category: TaskCategory = .custom
    @State private var description: String = ""
    @State private var budgetText: String = ""
    @State private var isNegotiable: Bool = false
    @State private var hasSetLocation: Bool = false
    @State private var taskLatitude: Double = 0
    @State private var taskLongitude: Double = 0
    @State private var showLocationPicker: Bool = false
    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""
    @State private var isPublishing: Bool = false
    @State private var radiusKm: Double = 10

    private let budgetPresets = [100, 500, 1000, 2000]

    private var suggestedTitles: [String] {
        switch category {
        case .academic: return ["Math Tutor", "Essay Review", "Physics Help", "Notes Needed"]
        case .roadsideHelp: return ["Jump Start", "Flat Tire", "Out of Gas", "Tow Needed"]
        case .labor: return ["Move Furniture", "Yard Work", "Heavy Lifting", "Cleaning"]
        case .custom: return ["Deliver Package", "Stand in Line", "Pet Sitting"]
        }
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Int(budgetText) ?? 0) > 0 &&
        hasSetLocation
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    detailsSection
                    budgetSection
                    radiusSection
                    locationSection

                    if showValidationError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                            Text(validationMessage).font(.subheadline.weight(.semibold)).foregroundStyle(.red)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    publishButton
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Post a Demand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    latitude: $taskLatitude,
                    longitude: $taskLongitude,
                    hasSetLocation: $hasSetLocation,
                    radiusKm: radiusKm, // Passing radius for live preview
                    initialLocation: locationService.location
                )
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Category Selection
            Text("Category").font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(TaskCategory.allCases) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3)) { category = cat }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: cat.icon).font(.title2)
                            Text(cat.rawValue).font(.caption.weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(category == cat ? categoryColor(cat) : Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(category == cat ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: category == cat ? categoryColor(cat).opacity(0.3) : .black.opacity(0.04), radius: 6, y: 3)
                    }
                    .sensoryFeedback(.selection, trigger: category)
                }
            }

            // Title
            Text("Task Title").font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
            TextField("e.g., Help me move furniture", text: $title)
                .font(.body).padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.03), radius: 5, y: 2)

            // Suggested Title Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestedTitles, id: \.self) { suggestion in
                        Button {
                            title = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(categoryColor(category))
                                .clipShape(.capsule)
                                .overlay(Capsule().strokeBorder(categoryColor(category).opacity(0.3), lineWidth: 1))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description").font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
            TextField("Describe what you need help with...", text: $description, axis: .vertical)
                .lineLimit(4...8).font(.body).padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
        }
    }

    // MARK: - Budget Section
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget").font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("₹").font(.title2.weight(.bold)).foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                    TextField("Amount", text: $budgetText)
                        .keyboardType(.numberPad).font(.title2.weight(.semibold))
                }
                .padding(16).frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.03), radius: 5, y: 2)

                Toggle(isOn: $isNegotiable) {
                    Text("Negotiable").font(.subheadline.weight(.bold))
                }
                .toggleStyle(.switch).tint(Color(red: 1.0, green: 0.45, blue: 0.0))
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
            }
            
            // Budget Quick Selects
            HStack(spacing: 10) {
                ForEach(budgetPresets, id: \.self) { amount in
                    Button {
                        budgetText = "\(amount)"
                    } label: {
                        Text("₹\(amount)")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    }
                }
            }
        }
    }

    // MARK: - Radius Section
    private var radiusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Visibility Radius")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(radiusKm)) km")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
            }
            Text("Only users within \(Int(radiusKm)) km of your pin can see this task")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Slider(value: $radiusKm, in: 5...50, step: 5)
                .tint(Color(red: 1.0, green: 0.45, blue: 0.0))

            HStack {
                Text("5 km").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                Spacer()
                Text("50 km").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location").font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
            Button { showLocationPicker = true } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(hasSetLocation ? Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.15) : Color(.systemGray5))
                            .frame(width: 44, height: 44)
                        Image(systemName: hasSetLocation ? "mappin.circle.fill" : "mappin.circle")
                            .font(.title2)
                            .foregroundStyle(hasSetLocation ? Color(red: 1.0, green: 0.45, blue: 0.0) : .secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hasSetLocation ? "Location Set" : "Set Location")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(hasSetLocation ? "Tap to update pin" : "Drop a pin on the map")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.subheadline.weight(.bold)).foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
            }
        }
    }

    // MARK: - Publish Button
    private var publishButton: some View {
        Button {
            Task { await publishTask() }
        } label: {
            HStack(spacing: 10) {
                if isPublishing {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Publish Request").font(.system(.headline, design: .rounded, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(
                isFormValid
                    ? LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray4)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(.white)
            .clipShape(.capsule)
            .shadow(color: isFormValid ? Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .disabled(!isFormValid || isPublishing)
        .padding(.top, 8)
    }

    // MARK: - Actions
    private func publishTask() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = description.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { showError("Please enter a task title"); return }
        guard !trimmedDesc.isEmpty else { showError("Please add a description"); return }
        guard let budget = Int(budgetText), budget > 0 else { showError("Please enter a valid budget amount"); return }
        guard hasSetLocation else { showError("Please set a location for the task"); return }

        isPublishing = true
        let success = await taskViewModel.addTask(
            title: trimmedTitle,
            category: category.rawValue,
            description: trimmedDesc,
            budget: budget,
            isNegotiable: isNegotiable,
            latitude: taskLatitude,
            longitude: taskLongitude,
            radiusMetres: Int(radiusKm) * 1000
        )
        isPublishing = false
        if success { onDismiss() } else if let err = taskViewModel.errorMessage { showError(err) }
    }

    private func showError(_ message: String) {
        validationMessage = message
        withAnimation(.spring(response: 0.3)) { showValidationError = true }
    }

    private func categoryColor(_ cat: TaskCategory) -> Color {
        switch cat {
        case .academic: return .blue
        case .roadsideHelp: return .red
        case .labor: return .orange
        case .custom: return .purple
        }
    }
}

// MARK: - LocationPickerView
struct LocationPickerView: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var hasSetLocation: Bool
    let radiusKm: Double
    let initialLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss

    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                Map(position: $cameraPosition) {
                    if let pin = pinCoordinate {
                        // Live Radius Preview!
                        MapCircle(center: pin, radius: radiusKm * 1000)
                            .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.15))
                            .stroke(Color(red: 1.0, green: 0.45, blue: 0.0), lineWidth: 2)
                        
                        Annotation("Task Location", coordinate: pin) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.45, blue: 0.0).gradient)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .orange.opacity(0.4), radius: 6, y: 3)
                                Image(systemName: "mappin")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    UserAnnotation()
                }
                .mapStyle(.standard)
                .onMapCameraChange(frequency: .continuous) { context in
                    pinCoordinate = context.region.center
                }

                // Crosshair fixed in the centre of the screen
                Image(systemName: "plus")
                    .font(.title.weight(.light))
                    .foregroundStyle(.black.opacity(0.6))
                    .shadow(radius: 2)
            }
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        if let pin = pinCoordinate {
                            latitude = pin.latitude
                            longitude = pin.longitude
                            hasSetLocation = true
                        }
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 4) {
                    Text("Move the map to position the crosshair.")
                        .font(.subheadline.weight(.bold))
                    Text("The circle shows your \(Int(radiusKm))km visibility radius.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .onAppear {
                if let loc = initialLocation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: loc.coordinate,
                        // Scale the initial zoom somewhat relative to the chosen radius
                        span: MKCoordinateSpan(latitudeDelta: radiusKm * 0.015, longitudeDelta: radiusKm * 0.015)
                    ))
                    pinCoordinate = loc.coordinate
                }
            }
        }
    }
}
