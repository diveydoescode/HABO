// MARK: - ApplicantRow.swift
import SwiftUI

struct ApplicantRow: View {
    let application: TaskApplicationResponse
    let onHire: () -> Void // ✅ Ensure this parameter exists
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Profile Avatar Placeholder
                ZStack {
                    SwiftUI.Circle()
                        .fill(Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.1))
                        .frame(width: 44, height: 44)
                    Text("B").fontWeight(.bold).foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Brother Applicant")
                        .font(.system(.headline, design: .rounded))
                    Text("Applied \(application.appliedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Badge
                Text(application.status.capitalized)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(application.status == "pending" ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
                    .foregroundColor(application.status == "pending" ? .orange : .green)
                    .clipShape(Capsule())
            }
            
            if let message = application.coverMessage, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button(action: onHire) {
                Text("Hire this Brother")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 5, y: 3)
    }
}
