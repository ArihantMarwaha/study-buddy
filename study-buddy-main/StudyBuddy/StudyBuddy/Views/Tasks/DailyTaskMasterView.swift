//
//  DailyTaskMasterView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 13/07/25.
//

//
//  DailyTaskMasterView.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 13/07/25.
//

import Foundation
import SwiftUI

struct DailyTaskMasterView: View {
    @EnvironmentObject var goalManager: GoalManager
    @State private var selectedTab = 0
    @State private var showingCreateGoal = false
    @State private var showingSettings = false
    @State private var showingSearch = false
    @State private var searchText = ""
    // Selection state for GoalsListView
    @State private var isSelectionMode = false
    @State private var selectedGoals: Set<UUID> = []

    let tabItems = [
        (title: "Dashboard", icon: "square.grid.2x2", color: Color.blue),
        (title: "Goals", icon: "target", color: Color.green),
        (title: "Analytics", icon: "chart.bar.fill", color: Color.cyan)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Modern Header with Toolbar
            HeaderToolbar(
                selectedTab: $selectedTab,
                showingCreateGoal: $showingCreateGoal,
                showingSettings: $showingSettings,
                showingSearch: $showingSearch,
                searchText: $searchText,
                tabItems: tabItems,
                isSelectionMode: $isSelectionMode,
                selectedGoals: $selectedGoals,
                nonDefaultFilteredGoals: selectedTab == 1 ? goalManager.goals.filter { !$0.isDefault } : [],
                onDeleteSelectedGoals: deleteSelectedGoals
            )
            .environmentObject(goalManager)
            
            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    Group {
                        if selectedTab == 0 {
                            DashboardView()
                        } else if selectedTab == 1 {
                            GoalsListView(
                                isSelectionMode: $isSelectionMode,
                                selectedGoals: $selectedGoals
                            )
                        } else if selectedTab == 2 {
                            AnalyticsView()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.05),
                    Color.cyan.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showingCreateGoal) {
            CreateGoalView()
                .environmentObject(goalManager)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(goalManager)
        }
    }
    
    private func deleteSelectedGoals() {
        let goalsToDelete = goalManager.goals.filter { selectedGoals.contains($0.id) }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            for goal in goalsToDelete {
                goalManager.deleteGoal(goal)
            }
            selectedGoals.removeAll()
            isSelectionMode = false
        }
    }
}

// MARK: - Header Toolbar
struct HeaderToolbar: View {
    @EnvironmentObject var goalManager: GoalManager
    @Binding var selectedTab: Int
    @Binding var showingCreateGoal: Bool
    @Binding var showingSettings: Bool
    @Binding var showingSearch: Bool
    @Binding var searchText: String
    let tabItems: [(title: String, icon: String, color: Color)]
    // Selection state for capsule
    @Binding var isSelectionMode: Bool
    @Binding var selectedGoals: Set<UUID>
    let nonDefaultFilteredGoals: [Goal]
    let onDeleteSelectedGoals: () -> Void
    
    @State private var hoveredTab: Int? = nil
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Top Action Bar
            HStack {
                // App Title with Status
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .symbolEffect(.bounce, value: isAnimating)
                        
                        Text("Daily Goals")
                            .font(.title.bold())
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 16) {
                        StatusIndicator(
                            icon: "checkmark.circle.fill",
                            text: "\(goalManager.todayCompletedGoals) completed",
                            color: .green
                        )
                        
                        StatusIndicator(
                            icon: "flame.fill",
                            text: "\(goalManager.currentStreak) day streak",
                            color: .orange
                        )
                        
                        StatusIndicator(
                            icon: "chart.line.uptrend.xyaxis",
                            text: "\(Int(goalManager.averageCompletionRate * 100))% rate",
                            color: .blue
                        )
                    }
                }
                
                Spacer()
                
                // Capsule Action Bar (plus, edit/trash) for Goals tab only
                if selectedTab == 1 {
                    GlassEffectContainer {
                        HStack(spacing: 0) {
                            // Plus button (add goal)
                            Button(action: { showingCreateGoal = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .frame(width: 35, height: 35)
                                    .padding(.horizontal, 8)
                            }
                            .buttonStyle(.plain)
                            // Edit button (toggle selection mode)
                            Button(action: {
                                if !nonDefaultFilteredGoals.isEmpty {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        isSelectionMode.toggle()
                                        if (!isSelectionMode) {
                                            selectedGoals.removeAll()
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: isSelectionMode ? "xmark" : "square.and.pencil")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(isSelectionMode ? .red : .primary)
                                    .frame(width: 32, height: 32)
                                    .padding(.horizontal, 8)
                            }
                            .buttonStyle(.plain)
                            // Trash button (delete selected goals)
                            if isSelectionMode && !selectedGoals.isEmpty {
                                Button(action: onDeleteSelectedGoals) {
                                    Image(systemName: "trash.fill")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                        .frame(width: 35, height: 35)
                                        .padding(.horizontal, 8)
                                }
                                .buttonStyle(.plain)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                        .glassEffect(in: Capsule())
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelectionMode)
                    }
                }
            }
            
            // Search Bar (when active)
            if showingSearch {
                SearchBarView(searchText: $searchText)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            // Enhanced Tab Selector
            TabSelectorView(
                selectedTab: $selectedTab,
                hoveredTab: $hoveredTab,
                tabItems: tabItems
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            BlurView(style: .hudWindow)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Toolbar Button
struct ToolbarButton: View {
    let icon: String
    var isActive: Bool = false
    let color: Color
    var isPrimary: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: isPrimary ? 18 : 16, weight: .semibold))
                .foregroundColor(isActive || isPrimary ? .white : color)
                .frame(width: isPrimary ? 44 : 36, height: isPrimary ? 44 : 36)
                .background(
                    Circle()
                        .fill(
                            isActive || isPrimary ?
                                color.gradient :
                                color.opacity(isHovered ? 0.15 : 0.1).gradient
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            isActive || isPrimary ?
                                color.opacity(0.3) :
                                Color.clear,
                            lineWidth: 1
                        )
                )
                .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
                .shadow(
                    color: (isActive || isPrimary) ? color.opacity(0.3) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

// MARK: - Search Bar
struct SearchBarView: View {
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("Search goals, analytics, or sessions...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($isSearchFocused)
                .onSubmit {
                    // Handle search submission
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSearchFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            isSearchFocused = true
        }
    }
}

// MARK: - Tab Selector
struct TabSelectorView: View {
    @Binding var selectedTab: Int
    @Binding var hoveredTab: Int?
    let tabItems: [(title: String, icon: String, color: Color)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabItems.count, id: \.self) { index in
                let item = tabItems[index]
                let isSelected = selectedTab == index
                let isHovered = hoveredTab == index
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: item.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white : item.color)
                            .symbolEffect(
                                .bounce.down.byLayer,
                                value: isSelected
                            )
                        
                        Text(item.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                isSelected ?
                                    item.color.gradient :
                                    (isHovered ? item.color.opacity(0.1) : Color.clear).gradient
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? item.color.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .scaleEffect(isSelected ? 1.02 : 1.0)
                    .shadow(
                        color: isSelected ? item.color.opacity(0.25) : Color.clear,
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoveredTab = hovering ? index : nil
                }
                
                if index < tabItems.count - 1 {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Settings View Placeholder
struct SettingsView: View {
    @EnvironmentObject var goalManager: GoalManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title.bold())
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("Settings panel coming soon...")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

// MARK: - Press Events Extension
extension View {
    func pressEvents(onPress: @escaping () -> Void = {}, onRelease: @escaping () -> Void = {}) -> some View {
        self.onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                if pressing {
                    onPress()
                } else {
                    onRelease()
                }
            },
            perform: {}
        )
    }
}

