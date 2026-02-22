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
                    locationSection

                    if showValidationError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(validationMessage)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(.rect(cornerRadius: 12))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    publishButton
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
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
                    initialLocation: locationService.location
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Title")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("e.g., Help me move furniture", text: $title)
                .font(.body)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))

            Text("Category")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(TaskCategory.allCases) { cat in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            category = cat
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.title3)
                            Text(cat.rawValue)
                                .font(.caption2.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(category == cat ? categoryColor(cat).opacity(0.15) : Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(category == cat ? categoryColor(cat) : .secondary)
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(category == cat ? categoryColor(cat) : .clear, lineWidth: 2)
                        )
                    }
                    .sensoryFeedback(.selection, trigger: category)
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Describe what you need help with...", text: $description, axis: .vertical)
                .lineLimit(4...8)
                .font(.body)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("₹")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))

                    TextField("Amount", text: $budgetText)
                        .keyboardType(.numberPad)
                        .font(.title2.weight(.semibold))
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))

                Toggle(isOn: $isNegotiable) {
                    Text("Negotiable")
                        .font(.subheadline.weight(.medium))
                }
                .toggleStyle(.switch)
                .tint(Color(red: 1.0, green: 0.45, blue: 0.0))
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Button {
                showLocationPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: hasSetLocation ? "mappin.circle.fill" : "mappin.circle")
                        .font(.title2)
                        .foregroundStyle(hasSetLocation ? Color(red: 1.0, green: 0.45, blue: 0.0) : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(hasSetLocation ? "Location Set" : "Set Location")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(hasSetLocation ? "Tap to update pin" : "Drop a pin on the map")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private var publishButton: some View {
        Button {
            publishTask()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "paperplane.fill")
                Text("Publish Request")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isFormValid
                    ? LinearGradient(colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray4)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 16))
        }
        .disabled(!isFormValid)
        .sensoryFeedback(.success, trigger: taskViewModel.tasks.count)
        .padding(.top, 8)
    }

    private func publishTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDesc = description.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            showError("Please enter a task title")
            return
        }
        guard !trimmedDesc.isEmpty else {
            showError("Please add a description")
            return
        }
        guard let budget = Int(budgetText), budget > 0 else {
            showError("Please enter a valid budget amount")
            return
        }
        guard hasSetLocation else {
            showError("Please set a location for the task")
            return
        }

        let newTask = GigTask(
            title: trimmedTitle,
            category: category,
            description: trimmedDesc,
            budget: budget,
            isNegotiable: isNegotiable,
            latitude: taskLatitude,
            longitude: taskLongitude,
            creatorName: userName
        )
        taskViewModel.addTask(newTask)
        onDismiss()
    }

    private func showError(_ message: String) {
        validationMessage = message
        withAnimation(.spring(response: 0.3)) {
            showValidationError = true
        }
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

struct LocationPickerView: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var hasSetLocation: Bool
    let initialLocation: CLLocation?
    @Environment(\.dismiss) private var dismiss

    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                Map(position: $cameraPosition) {
                    if let pin = pinCoordinate {
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
                .onMapCameraChange(frequency: .onEnd) { context in
                    pinCoordinate = context.region.center
                }

                Image(systemName: "plus")
                    .font(.title3.weight(.light))
                    .foregroundStyle(.secondary)
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
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("Move the map to position the crosshair on your task location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
            }
            .onAppear {
                if let loc = initialLocation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                    pinCoordinate = loc.coordinate
                }
            }
        }
    }
}