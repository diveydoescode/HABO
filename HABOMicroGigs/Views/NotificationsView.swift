// MARK: - NotificationsView.swift
import SwiftUI

struct NotificationsView: View {
    // Mock data for the UI representation
    let mockNotifications = [
        ("checkmark.circle.fill", "Task Completed", "Arjun completed 'Move Furniture'. Payment released.", Color.green, "2m ago"),
        ("hand.raised.fill", "Task Accepted", "Priya accepted your 'Physics Help' request.", Color(red: 1.0, green: 0.45, blue: 0.0), "1h ago"),
        ("person.crop.circle.badge.plus", "New Follower", "Rahul started following you.", Color.blue, "3h ago")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(0..<mockNotifications.count, id: \.self) { index in
                        let notif = mockNotifications[index]
                        
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: notif.0)
                                .font(.title2)
                                .foregroundStyle(notif.3)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notif.1)
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                Text(notif.2)
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Text(notif.4)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}//
//  NotificationsView.swift
//  HABOMicroGigs
//
//  Created by Divey Pradhan on 27/02/26.
//

