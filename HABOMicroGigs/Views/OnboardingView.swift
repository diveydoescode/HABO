// MARK: - OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @Bindable var authViewModel: AuthViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    
    let accentColor = Color(red: 1.0, green: 0.45, blue: 0.0)
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            // ✅ Conditionally show Profile Setup vs Welcome Tour
            if authViewModel.isAuthenticated {
                // User is logged in but hasn't set up their profile yet
                ProfileSetupPage(authViewModel: authViewModel, onComplete: completeProfileSetup)
            } else {
                // User is not logged in. Show the Welcome Tour.
                welcomeTourView
            }
        }
        .animation(.easeInOut, value: currentPage)
    }
    
    // MARK: - Pre-Login Welcome Tour
    private var welcomeTourView: some View {
        VStack {
            // Skip Button
            HStack {
                Spacer()
                Button("Skip") {
                    finishWelcomeTour()
                }
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
                .padding()
            }
            
            TabView(selection: $currentPage) {
                OnboardingPage(
                    imageName: "map.circle.fill",
                    title: "Find help nearby",
                    description: "See micro-gigs and tasks posted by people in your local neighborhood right on the map.",
                    color: .blue
                ).tag(0)
                
                OnboardingPage(
                    imageName: "plus.circle.fill",
                    title: "Post what you need",
                    description: "Need a hand? Post a task, set your budget, and get help from verified locals in minutes.",
                    color: accentColor
                ).tag(1)
                
                OnboardingPage(
                    imageName: "indianrupeesign.circle.fill",
                    title: "Earn by helping",
                    description: "Accept tasks, complete them, and get paid securely right through the app.",
                    color: .green
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            // Bottom Navigation
            Button {
                if currentPage < 2 {
                    withAnimation { currentPage += 1 }
                } else {
                    finishWelcomeTour()
                }
            } label: {
                Text(currentPage == 2 ? "Get Started" : "Next")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accentColor)
                    .foregroundStyle(.white)
                    .clipShape(.capsule)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }
    
    // Action: Finish Tour & Go to Login
    private func finishWelcomeTour() {
        withAnimation(.spring(response: 0.5)) {
            hasSeenOnboarding = true
        }
    }
    
    // Action: Profile Saved, Go to Main App
    private func completeProfileSetup() {
        withAnimation(.spring(response: 0.5)) {
            hasSeenOnboarding = true
            authViewModel.needsOnboarding = false
        }
    }
}

// MARK: - Welcome Tour Page
struct OnboardingPage: View {
    let imageName: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                SwiftUI.Circle().fill(color.opacity(0.15)).frame(width: 160, height: 160)
                Image(systemName: imageName).font(.system(size: 80)).foregroundStyle(color)
            }
            .padding(.bottom, 20)
            
            Text(title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Redesigned Profile Setup Page
struct ProfileSetupPage: View {
    @Bindable var authViewModel: AuthViewModel
    let onComplete: () -> Void
    
    @State private var displayName: String = ""
    @State private var selectedSkills: [UserSkill] = []
    @State private var showSkillSelector = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    
    let availableSkills = [
        "Copywriting", "Roadside Help", "Coding", "Education",
        "Labor", "Cleaning", "Delivery", "Plumbing", "Electrical", "Design",
        "Photography", "Handyman", "Moving", "Cooking"
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Your Profile")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                    Text("Set up your display name and let the community know what you excel at.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Name Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Display Name")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundStyle(.secondary)
                        TextField("e.g. John D.", text: $displayName)
                            .textContentType(.name)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Skills Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Skills")
                                .font(.headline)
                            Text("Add up to 5 skills (\(selectedSkills.count)/5)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        if selectedSkills.count < 5 {
                            Button {
                                showSkillSelector = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                            }
                        }
                    }
                    
                    if selectedSkills.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "star.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(Color(.systemGray4))
                            Text("No skills added yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                    } else {
                        VStack(spacing: 16) {
                            ForEach($selectedSkills) { $skill in
                                SkillRowView(skill: $skill) {
                                    withAnimation {
                                        selectedSkills.removeAll(where: { $0.id == skill.id })
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 20)
                
                // ERROR DISPLAY
                if let err = errorMessage {
                    Text(err)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Save Button
                Button {
                    Task { await saveProfile() }
                } label: {
                    if isSaving {
                        ProgressView().tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text("Save Profile & Enter HABO")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .foregroundStyle(.white)
                .background(Color(red: 1.0, green: 0.45, blue: 0.0))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.0).opacity(0.3), radius: 8, y: 4)
                .disabled(displayName.isEmpty || isSaving)
                .opacity(displayName.isEmpty ? 0.5 : 1.0)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showSkillSelector) {
            SkillSelectionSheet(
                availableSkills: availableSkills.filter { name in !selectedSkills.contains(where: { $0.name == name }) }
            ) { newSkillName in
                withAnimation {
                    selectedSkills.append(UserSkill(name: newSkillName, proficiency: 3))
                }
            }
        }
        .onAppear {
            if let existingName = authViewModel.currentUser?.name, !existingName.isEmpty {
                displayName = existingName
            }
        }
    }
    
    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        
        do {
            let request = ProfileUpdateRequest(name: displayName, skills: selectedSkills)
            
            // ✅ Send the update to the restored /users/me endpoint
            let updatedUser = try await APIClient.shared.updateProfile(request: request)
            
            await MainActor.run {
                authViewModel.currentUser = updatedUser
                isSaving = false
                onComplete()
            }
        } catch {
            print("Failed to save profile: \(error)")
            await MainActor.run {
                // Display the actual error on screen if the request fails
                errorMessage = "Error: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

// MARK: - Redesigned Skill Row (Button based)
struct SkillRowView: View {
    @Binding var skill: UserSkill
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(skill.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color(.systemGray3))
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Proficiency Level")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                skill.proficiency = level
                            }
                        } label: {
                            Text("\(level)")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    skill.proficiency >= level
                                    ? Color(red: 1.0, green: 0.45, blue: 0.0)
                                    : Color(.systemGray5)
                                )
                                .foregroundStyle(skill.proficiency >= level ? .white : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                
                HStack {
                    Text("Beginner")
                    Spacer()
                    Text("Pro")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Skill Selection Sheet
struct SkillSelectionSheet: View {
    let availableSkills: [String]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var filteredSkills: [String] {
        if searchText.isEmpty { return availableSkills }
        return availableSkills.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredSkills, id: \.self) { skill in
                Button {
                    onSelect(skill)
                    dismiss()
                } label: {
                    HStack {
                        Text(skill)
                            .font(.system(.body, design: .rounded, weight: .medium))
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.0))
                    }
                }
                .foregroundStyle(.primary)
            }
            .searchable(text: $searchText, prompt: "Search skills")
            .navigationTitle("Select a Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
