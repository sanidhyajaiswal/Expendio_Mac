import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case expenses = "Expenses"
    case reports = "Reports"
    case categories = "Categories"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .expenses: return "list.bullet.rectangle.fill"
        case .reports: return "chart.bar.fill"
        case .categories: return "tag.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: SidebarItem = .dashboard
    @State private var hoveredItem: SidebarItem?
    @State private var showProfileSheet = false
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    @AppStorage("activeProfileId") private var activeProfileIdString: String = ""
    @State private var showDataTransferDialog = false
    // Computed directly (not from environment — ContentView is the source of truth)
    private var themeAccent: Color { Color(hex: activeProfile?.colorHex ?? "#7C3AED") }
    
    private var activeProfile: Profile? {
        guard let uuid = UUID(uuidString: activeProfileIdString) else { return profiles.first }
        return profiles.first { $0.id == uuid } ?? profiles.first
    }
    
    @State private var setupName = ""
    @State private var setupColor = "#7C3AED"
    
    private let setupColors = ["#7C3AED", "#FF6B6B", "#4ECDC4", "#F59E0B", "#3B82F6", "#EC4899", "#10B981", "#F97316"]
    
    var body: some View {
        return Group {
            if let profile = activeProfile {
                mainLayout(profileId: profile.id)
            } else {
                profileSetupView
            }
        }
        .themeAccent(themeAccent)
        .background(AppTheme.background)
        .onAppear {
            // Only auto-select if profiles exist but none is selected
            if !profiles.isEmpty, activeProfile == nil, let first = profiles.first {
                activeProfileIdString = first.id.uuidString
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileManagementView(activeProfileIdString: $activeProfileIdString)
        }
        .sheet(isPresented: $showDataTransferDialog) {
            DataTransferDialog()
        }
    }
    
    // MARK: - Profile Setup (first launch)
    private var profileSetupView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(Color(hex: setupColor))
                        .shadow(color: Color(hex: setupColor).opacity(0.3), radius: 12)
                    Text("Setup Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Let's set up your profile to get started")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Form
                VStack(spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill").font(.system(size: 12)).foregroundColor(Color(hex: setupColor))
                            Text("Your Name").font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                        }
                        TextField("Enter your name", text: $setupName)
                            .textFieldStyle(.plain).font(.system(size: 16)).foregroundColor(AppTheme.textPrimary)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceElevated)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border.opacity(0.5), lineWidth: 1))
                            )
                    }
                    
                    // Color Picker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "paintpalette.fill").font(.system(size: 12)).foregroundColor(Color(hex: setupColor))
                            Text("Profile Color").font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                        }
                        HStack(spacing: 10) {
                            ForEach(setupColors, id: \.self) { c in
                                Button { setupColor = c } label: {
                                    Circle().fill(Color(hex: c)).frame(width: 32, height: 32)
                                        .overlay(Circle().stroke(Color.white, lineWidth: setupColor == c ? 2.5 : 0))
                                        .scaleEffect(setupColor == c ? 1.15 : 1.0)
                                        .animation(.spring(response: 0.3), value: setupColor == c)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 20).fill(AppTheme.surface.opacity(0.5))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border.opacity(0.3), lineWidth: 1))
                )
                
                // Create Button
                Button {
                    createProfile()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill").font(.system(size: 16))
                        Text("Get Started").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: setupColor)))
                }
                .buttonStyle(.plain)
                .disabled(setupName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(setupName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
            .frame(maxWidth: 420)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Main Layout
    private func mainLayout(profileId: UUID) -> some View {
        ZStack(alignment: .bottomLeading) {
            HStack(spacing: 0) {
                sidebar(profileId: profileId)
                mainContent(profileId: profileId)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.dynamicBackground)
            }

            if showGearPanel || showProfileSwitcher {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showGearPanel = false
                            showProfileSwitcher = false
                        }
                    }
            }

            // Gear panel overlay (inside main content, bottom-left)
            if showGearPanel {
                profilePanel
                    .fixedSize()
                    .offset(x: 221, y: -8)
                    .transition(.opacity)
            }
            
            // Profile switcher overlay
            if showProfileSwitcher {
                profileSwitcherOverlay
                    .frame(width: 204)
                    .offset(x: 8, y: -64)
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Sidebar
    private func sidebar(profileId: UUID) -> some View {
        VStack(spacing: 0) {
            // Logo
            HStack(spacing: 10) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeAccent)
                
                Text("Expendio")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.top, 32)
            .padding(.bottom, 40)

            // Menu Items
            VStack(spacing: 4) {
                ForEach(SidebarItem.allCases) { item in
                    sidebarButton(item)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Profile card at bottom
            profileBottomCard
        }
        .frame(width: 220)
        .background(AppTheme.dynamicSurface) // Use dynamic surface for smooth contrast or blend natively
    }
    
    // MARK: - Profile Bottom Card
    @State private var showEditProfileSheet = false
    @State private var showAddProfileSheet = false
    @State private var editingProfileName = ""
    @State private var editingProfileColor = "#7C3AED"
    @State private var newProfileName = ""
    @State private var newProfileColor = "#7C3AED"
    private let profileColors = ["#7C3AED","#FF6B6B","#4ECDC4","#F59E0B","#3B82F6","#EC4899","#10B981","#F97316"]

    @State private var showProfileSwitcher = false
    @State private var showGearPanel = false
    @State private var showDeleteProfileAlert = false

    private var profileBottomCard: some View {
        let profile = activeProfile
        let color = Color(hex: profile?.colorHex ?? "#7C3AED")
        return HStack(spacing: 10) {
            // Avatar — click to show custom profile switcher popover (above)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showProfileSwitcher.toggle() }
            } label: {
                ZStack {
                    Circle().fill(color.opacity(0.2)).frame(width: 34, height: 34)
                    Text(String((profile?.name ?? "P").prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile?.name ?? "Profile")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                Text("View settings")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textMuted)
            }
            Spacer(minLength: 0)
            // Gear button
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { showGearPanel.toggle() }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
                    .frame(width: 26, height: 26)
                    .background(RoundedRectangle(cornerRadius: 7).fill(AppTheme.surfaceElevated.opacity(0.6)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .sheet(isPresented: $showEditProfileSheet) {
            ProfileDialogSheet(
                title: "Edit Profile",
                name: $editingProfileName,
                color: $editingProfileColor,
                colors: profileColors,
                buttonLabel: "Save Changes",
                onCommit: {
                    let trimmed = editingProfileName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    activeProfile?.name = trimmed
                    activeProfile?.colorHex = editingProfileColor
                    try? modelContext.save()
                    showEditProfileSheet = false
                },
                onCancel: { showEditProfileSheet = false }
            )
        }
        .sheet(isPresented: $showAddProfileSheet) {
            ProfileDialogSheet(
                title: "Add Profile",
                name: $newProfileName,
                color: $newProfileColor,
                colors: profileColors,
                buttonLabel: "Create Profile",
                onCommit: {
                    let trimmed = newProfileName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    let p = Profile(name: trimmed, colorHex: newProfileColor)
                    modelContext.insert(p)
                    for (n, i, c) in ExpenseCategory.defaults {
                        modelContext.insert(ExpenseCategory(name: n, icon: i, colorHex: c, profileId: p.id))
                    }
                    try? modelContext.save()
                    activeProfileIdString = p.id.uuidString
                    showAddProfileSheet = false
                },
                onCancel: { showAddProfileSheet = false }
            )
        }
        .alert("Delete \"\(activeProfile?.name ?? "Profile")?\" ", isPresented: $showDeleteProfileAlert) {
            Button("Delete", role: .destructive) { deleteActiveProfile() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the profile and all its expenses. This action cannot be undone.")
        }
    }

    // MARK: - Profile Switcher Overlay (inside sidebar, above profile card)
    private var profileSwitcherOverlay: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(profiles, id: \.id) { p in
                ProfileSwitcherButton(
                    profile: p,
                    isActive: p.id == activeProfile?.id,
                    themeAccent: themeAccent,
                    action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeProfileIdString = p.id.uuidString
                            showProfileSwitcher = false
                        }
                    }
                )
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.dynamicSurfaceElevated)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        )
    }

    // MARK: - Delete Profile
    private func deleteActiveProfile() {
        guard let profile = activeProfile, profiles.count > 1 else { return }
        // Switch to another profile first
        let remaining = profiles.filter { $0.id != profile.id }
        if let next = remaining.first {
            activeProfileIdString = next.id.uuidString
        }
        // Delete all expenses and categories belonging to this profile
        let pid = profile.id
        let expensesToDelete = (try? modelContext.fetch(FetchDescriptor<Expense>(predicate: #Predicate { $0.profileId == pid }))) ?? []
        let categoriesToDelete = (try? modelContext.fetch(FetchDescriptor<ExpenseCategory>(predicate: #Predicate { $0.profileId == pid }))) ?? []
        expensesToDelete.forEach { modelContext.delete($0) }
        categoriesToDelete.forEach { modelContext.delete($0) }
        modelContext.delete(profile)
        try? modelContext.save()
    }

    // MARK: - Compact Gear Panel (in-app overlay)
    private var profilePanel: some View {
        VStack(alignment: .leading, spacing: 2) {
            PanelActionButton(icon: "pencil", label: "Edit Profile") {
                editingProfileName = activeProfile?.name ?? ""
                editingProfileColor = activeProfile?.colorHex ?? "#7C3AED"
                withAnimation { showGearPanel = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { showEditProfileSheet = true }
            }
            PanelActionButton(icon: "person.badge.plus", label: "Add Profile") {
                newProfileName = ""
                newProfileColor = "#7C3AED"
                withAnimation { showGearPanel = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { showAddProfileSheet = true }
            }
            Divider().padding(.horizontal, 8).padding(.vertical, 2)
            PanelActionButton(icon: "arrow.triangle.2.circlepath", label: "Data Transfer") {
                withAnimation { showGearPanel = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { showDataTransferDialog = true }
            }
            if profiles.count > 1 {
                Divider().padding(.horizontal, 8).padding(.vertical, 2)
                PanelActionButton(icon: "trash", label: "Delete Profile", destructive: true) {
                    withAnimation { showGearPanel = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { showDeleteProfileAlert = true }
                }
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.dynamicSurfaceElevated)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 2, y: 2)
        )
    }


    
    @State private var expenseFilterCategory: ExpenseCategory? = nil
    @State private var expenseFilterDate: DateFilter = .allTime
    
    private func sidebarButton(_ item: SidebarItem) -> some View {
        Button {
            if item == .expenses {
                expenseFilterCategory = nil
                expenseFilterDate = .allTime
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedItem = item }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.icon).font(.system(size: 15, weight: .medium)).frame(width: 24)
                Text(item.rawValue).font(.system(size: 14, weight: selectedItem == item ? .semibold : .medium))
                Spacer()
            }
            .foregroundColor(selectedItem == item ? .white : AppTheme.textSecondary)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedItem == item ? themeAccent : (hoveredItem == item ? AppTheme.surfaceElevated : Color.clear))
                    .opacity(selectedItem == item ? 1 : 0.8)
            )
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hoveredItem = h ? item : nil } }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private func mainContent(profileId: UUID) -> some View {
        switch selectedItem {
        case .dashboard: 
            DashboardView(profileId: profileId, onCategorySelect: { cat, dateFilter in
                expenseFilterCategory = cat
                if let df = dateFilter { expenseFilterDate = df }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedItem = .expenses }
            })
        case .expenses: 
            ExpenseListView(profileId: profileId, initialCategory: expenseFilterCategory, initialDateFilter: expenseFilterDate)
        case .reports: 
            ReportsView(profileId: profileId, onCategorySelect: { cat, dateFilter in
                expenseFilterCategory = cat
                if let df = dateFilter { expenseFilterDate = df }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedItem = .expenses }
            })
        case .categories: 
            CategoryManagementView(profileId: profileId)
        }
    }
    
    // MARK: - Create Profile
    private func createProfile() {
        let name = setupName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let profile = Profile(name: name, colorHex: setupColor)
        modelContext.insert(profile)
        seedCategories(for: profile.id)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save profile: \(error)")
        }
        activeProfileIdString = profile.id.uuidString
    }
    
    // MARK: - Seed Categories
    private func seedCategories(for profileId: UUID) {
        for (name, icon, color) in ExpenseCategory.defaults {
            let category = ExpenseCategory(name: name, icon: icon, colorHex: color, profileId: profileId)
            modelContext.insert(category)
        }
    }
}

// MARK: - Profile Management Sheet
struct ProfileManagementView: View {
    @Binding var activeProfileIdString: String
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeAccent) private var themeAccent
    @Query private var profiles: [Profile]
    
    @State private var newName = ""
    @State private var newColor = "#7C3AED"
    @State private var editingProfile: Profile?
    
    private let colors = ["#7C3AED", "#FF6B6B", "#4ECDC4", "#F59E0B", "#3B82F6", "#EC4899", "#10B981", "#F97316"]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Manage Profiles").font(.system(size: 20, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button("Done") { dismiss() }.font(.system(size: 13, weight: .medium)).foregroundColor(themeAccent).buttonStyle(.plain)
            }
            .padding(20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(profiles, id: \.id) { profile in
                        profileRow(profile)
                    }
                    
                    // Add new profile
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add Profile").font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                        HStack(spacing: 10) {
                            TextField("Profile name", text: $newName)
                                .textFieldStyle(.plain).font(.system(size: 14)).foregroundColor(AppTheme.textPrimary)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.surfaceElevated)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border.opacity(0.5), lineWidth: 1)))
                            
                            ForEach(colors, id: \.self) { c in
                                Button { newColor = c } label: {
                                    Circle().fill(Color(hex: c)).frame(width: 22, height: 22)
                                        .overlay(Circle().stroke(Color.white, lineWidth: newColor == c ? 2 : 0))
                                }.buttonStyle(.plain)
                            }
                            
                            Button {
                                guard !newName.isEmpty else { return }
                                let p = Profile(name: newName, colorHex: newColor)
                                modelContext.insert(p)
                                // Seed default categories for new profile
                                for (name, icon, color) in ExpenseCategory.defaults {
                                    modelContext.insert(ExpenseCategory(name: name, icon: icon, colorHex: color, profileId: p.id))
                                }
                                try? modelContext.save()
                                newName = ""
                            } label: {
                                Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundColor(themeAccent)
                            }.buttonStyle(.plain).disabled(newName.isEmpty)
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 560, height: 400).background(AppTheme.background)
    }
    
    private func profileRow(_ profile: Profile) -> some View {
        HStack(spacing: 12) {
            Circle().fill(Color(hex: profile.colorHex).opacity(0.2)).frame(width: 36, height: 36)
                .overlay(Text(String(profile.name.prefix(1)).uppercased()).font(.system(size: 14, weight: .bold)).foregroundColor(Color(hex: profile.colorHex)))
            
            Text(profile.name).font(.system(size: 14, weight: .medium)).foregroundColor(AppTheme.textPrimary)
            
            if UUID(uuidString: activeProfileIdString) == profile.id {
                Text("Active").font(.system(size: 11, weight: .medium)).foregroundColor(themeAccent)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(themeAccent.opacity(0.15)))
            }
            
            Spacer()
            
            if profiles.count > 1 {
                Button {
                    if UUID(uuidString: activeProfileIdString) == profile.id {
                        if let other = profiles.first(where: { $0.id != profile.id }) {
                            activeProfileIdString = other.id.uuidString
                        }
                    }
                    modelContext.delete(profile); try? modelContext.save()
                } label: {
                    Image(systemName: "trash").font(.system(size: 12)).foregroundColor(AppTheme.danger)
                }.buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surface.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border.opacity(0.3), lineWidth: 1)))
    }
}

// MARK: - Profile Dialog Sheet (shared for Edit & Add)
struct ProfileDialogSheet: View {
    let title: String
    @Binding var name: String
    @Binding var color: String
    let colors: [String]
    let buttonLabel: String
    let onCommit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                DialogCloseButton(action: onCancel)
            }
            .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 20) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: color))
                        Text("Name")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    TextField("Enter name", text: $name)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(AppTheme.surfaceElevated)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border.opacity(0.5), lineWidth: 1))
                        )
                }

                // Color picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: color))
                        Text("Color")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    HStack(spacing: 10) {
                        ForEach(colors, id: \.self) { c in
                            Button { color = c } label: {
                                Circle().fill(Color(hex: c)).frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color.white, lineWidth: color == c ? 2.5 : 0))
                                    .scaleEffect(color == c ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.25), value: color == c)
                            }.buttonStyle(.plain)
                        }
                    }
                }

                // Buttons
                HStack(spacing: 12) {
                    Button { onCancel() } label: {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surfaceElevated))
                    }.buttonStyle(.plain)

                    Button { onCommit() } label: {
                        Text(buttonLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: color)))
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                }
            }
            .padding(24)
        }
        .frame(width: 360)
        .background(AppTheme.background)
    }
}

// MARK: - Data Transfer Dialog
struct DataTransferDialog: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeAccent) private var themeAccent
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var alertMessage = ""
    @State private var generatedExportData: Data? = nil
    @State private var showFileExporter = false
    @State private var showFileImporter = false
    
    // For file exporter
    struct JSONDocument: FileDocument {
        static var readableContentTypes: [UTType] { [.json] }
        var data: Data
        init(data: Data) { self.data = data }
        init(configuration: ReadConfiguration) throws {
            guard let data = configuration.file.regularFileContents else {
                throw CocoaError(.fileReadCorruptFile)
            }
            self.data = data
        }
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            return FileWrapper(regularFileWithContents: data)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Data Transfer")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                DialogCloseButton(action: { dismiss() })
            }
            .padding(24)
            
            VStack(spacing: 24) {
                // Export Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill").foregroundColor(themeAccent)
                        Text("Export App Data").font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                    }
                    Text("Save all your profiles, categories, and expenses to a single JSON file. This file can be used to restore your data on another device.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Button {
                        exportData()
                    } label: {
                        HStack {
                            if isExporting {
                                ProgressView().controlSize(.small).padding(.trailing, 4)
                            }
                            Text("Export to File").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(themeAccent))
                    }
                    .buttonStyle(.plain)
                    .disabled(isExporting)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceElevated))
                
                // Import Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down.fill").foregroundColor(AppTheme.danger)
                        Text("Import App Data").font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                    }
                    Text("Restore data from a previously exported JSON file. Warning: This will completely replace all current profiles, categories, and expenses on this device.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Button {
                        showFileImporter = true
                    } label: {
                        HStack {
                            if isImporting {
                                ProgressView().controlSize(.small).padding(.trailing, 4)
                            }
                            Text("Import from File").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.danger)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.danger.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isImporting)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.surfaceElevated))
            }
            .padding(.horizontal, 24).padding(.bottom, 24)
        }
        .frame(width: 440)
        .background(AppTheme.background)
        .fileExporter(
            isPresented: $showFileExporter,
            document: JSONDocument(data: generatedExportData ?? Data()),
            contentType: .json,
            defaultFilename: "Expendio_Backup_\(Date().formatted(.iso8601.year().month().day().dateSeparator(.dash)))"
        ) { result in
            isExporting = false
            switch result {
            case .success:
                alertMessage = "Data exported successfully!"
                showSuccessAlert = true
                generatedExportData = nil
            case .failure(let error):
                alertMessage = "Export failed: \(error.localizedDescription)"
                showErrorAlert = true
                generatedExportData = nil
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importData(from: url)
            case .failure(let error):
                alertMessage = "Import failed: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportData() {
        isExporting = true
        do {
            generatedExportData = try DataTransferService.shared.exportData(from: modelContext)
            showFileExporter = true
        } catch {
            isExporting = false
            alertMessage = "Failed to generate export data: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func importData(from url: URL) {
        isImporting = true
        
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            try DataTransferService.shared.importData(from: data, into: modelContext)
            alertMessage = "Data imported successfully!"
            showSuccessAlert = true
            isImporting = false
        } catch {
            isImporting = false
            alertMessage = "Failed to import data: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

// MARK: - Reusable UI Components
struct DialogCloseButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button { action() } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(isHovered ? AppTheme.danger : AppTheme.textMuted)
                .background(Circle().fill(isHovered ? AppTheme.danger.opacity(0.15) : Color.clear))
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.1)) { isHovered = h } }
    }
}

// MARK: - Menu Button Structs
struct PanelActionButton: View {
    let icon: String
    let label: String
    var destructive: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        let tint = destructive ? AppTheme.danger : AppTheme.textSecondary
        Button { action() } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(tint)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(destructive ? AppTheme.danger : AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? AppTheme.textMuted.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

struct ProfileSwitcherButton: View {
    let profile: Profile
    let isActive: Bool
    let themeAccent: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button { action() } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color(hex: profile.colorHex).opacity(0.2)).frame(width: 26, height: 26)
                    Text(String(profile.name.prefix(1)).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: profile.colorHex))
                }
                Text(profile.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(themeAccent)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? themeAccent.opacity(0.1) : (isHovered ? AppTheme.textMuted.opacity(0.15) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}
