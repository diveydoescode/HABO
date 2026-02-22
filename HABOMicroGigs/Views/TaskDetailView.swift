import SwiftUI
import MapKit

struct TaskDetailView: View {
    let task: GigTask
    @Bindable var taskViewModel: TaskViewModel
    let userName: String
    @Environment(\.dismiss) private var dismiss
    @State private var showAcceptConfirmation: Bool = false
    @State private var hasAccepted: Bool = false

    private var categoryColor: Color {
        switch task.category {
        case .academic: return .blue
        case .roadsideHelp: return .red
        case .labor: return .orange
        case .custom: return .purple
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                mapPreview

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.title)
                                .font(.title2.weight(.bold))

                            HStack(spacing: 8) {
                                Label(task.category.rawValue, systemImage: task.category.icon)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(categoryColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(categoryColor.opacity(0.12))
                                    .clipShape(.capsule)

                                Label(task.status.rawValue, systemImage: task.status == .active ? "clock.fill" : "checkmark.circle.fill")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(task.status == .active ? .green : .secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("₹\(task.budget)")
                                .font(.title.weight(.bold))
                                .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))

                            if task.isNegotiable {
                                Text("Negotiable")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(task.description)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    Divider()

                    HStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Posted by")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(task.creatorName)
                                    .font(.subheadline.weight(.medium))
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Posted")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(task.createdAt.formatted(.relative(presentation: .named)))
                                .font(.subheadline.weight(.medium))
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("A 10–15% platform fee applies upon task completion.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 10))

                    if task.creatorName != userName && task.status == .active {
                        acceptButton
                    }

                    if hasAccepted {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("You've accepted this task!")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 14))
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    private var mapPreview: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: task.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))) {
            Annotation(task.title, coordinate: task.coordinate) {
                ZStack {
                    Circle()
                        .fill(categoryColor.gradient)
                        .frame(width: 36, height: 36)
                    Image(systemName: task.category.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .mapStyle(.standard)
        .frame(height: 200)
        .allowsHitTesting(false)
    }

    private var acceptButton: some View {
        Button {
            showAcceptConfirmation = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "hand.raised.fill")
                Text("Accept Task")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.45, blue: 0.0), Color(red: 1.0, green: 0.3, blue: 0.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 16))
        }
        .sensoryFeedback(.success, trigger: hasAccepted)
        .confirmationDialog("Accept this task?", isPresented: $showAcceptConfirmation) {
            Button("Accept Task") {
                withAnimation(.spring(response: 0.4)) {
                    taskViewModel.acceptTask(task.id, by: userName)
                    hasAccepted = true
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll be assigned to \"\(task.title)\" for ₹\(task.budget). A 10–15% platform fee applies on completion.")
        }
    }
}
