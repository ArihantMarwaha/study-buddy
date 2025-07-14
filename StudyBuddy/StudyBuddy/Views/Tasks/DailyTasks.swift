//
//  DailyTasks.swift
//  StudyBuddy
//
//  Created by Arihant Marwaha on 13/07/25.
//

import Foundation
import SwiftUI
import AppIntents
import UserNotifications
internal import Combine
internal import UniformTypeIdentifiers
import Charts
import AppKit

struct DashboardView: View {
    @EnvironmentObject var goalManager: GoalManager
    @State private var animateProgress = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                HeaderSections()
                
                // Progress Overview
                ProgressOverviewCard()
                    .environmentObject(goalManager)
                
                // Today's Goals
                TodaysGoalsSection()
                    .environmentObject(goalManager)
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .overlay(
            FloatingAddGoalButton()
                .padding(32),
            alignment: .topTrailing
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Header Section
struct HeaderSections: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Good \(timeOfDay)!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Let's make today productive")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
    
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }
}

// MARK: - Progress Overview Card
struct ProgressOverviewCard: View {
    @EnvironmentObject var goalManager: GoalManager
    @State private var animateRing = false
    
    var completionRate: Double {
        guard !goalManager.goals.isEmpty else { return 0 }
        let completed = goalManager.goals.filter { $0.isCompletedToday }.count
        return Double(completed) / Double(goalManager.goals.count)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Progress")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(completionRate * 100))% Complete")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: animateRing ? completionRate : 0)
                        .stroke(
                            Color.primary,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: animateRing)
                    
                    Text("\(Int(completionRate * 100))%")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            
            HStack(spacing: 40) {
                StatItem(
                    title: "Total Goals",
                    value: "\(goalManager.goals.count)",
                    icon: "target",
                    color: .primary
                )
                
                StatItem(
                    title: "Completed",
                    value: "\(goalManager.goals.filter { $0.isCompletedToday }.count)",
                    icon: "checkmark.circle.fill",
                    color: .primary
                )
                
                StatItem(
                    title: "Streak",
                    value: "\(goalManager.currentStreak)",
                    icon: "flame.fill",
                    color: .primary
                )
            }
        }
        .padding(24)
        .background(
            GlassEffectView(cornerRadius: 16) {
                Color.clear
            }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                animateRing = true
            }
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Today's Goals Section
struct TodaysGoalsSection: View {
    @EnvironmentObject var goalManager: GoalManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Goals")
                    .font(.title2.bold())
                Spacer()
                // Remove View All button
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(goalManager.goals.prefix(4)) { goal in
                    GoalCard(goal: goal)
                        .environmentObject(goalManager)
                }
            }
        }
    }
}

// MARK: - Goal Card
struct GoalCard: View {
    @EnvironmentObject var goalManager: GoalManager
    let goal: Goal
    @State private var isHovered = false
    @State private var animateProgress = false
    @State private var showingEdit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: goal.icon)
                        .font(.title2)
                        .foregroundColor(goal.color)
                    
                    if goal.isDefault {
                        Text("Default")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue, in: Capsule())
                    }
                }
                
                Spacer()
                
                // Edit button (shows on hover)
                if isHovered {
                    Button(action: { showingEdit = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.primary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
                
                if goal.currentCount >= goal.targetCount {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.primary)
                        .font(.title3)
                } else if goal.currentCount > 0 {
                    Text("\(goal.currentCount)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(goal.color, in: Circle())
                }
            }
            
            Text(goal.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(goal.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            ProgressView(value: animateProgress ? goal.progress : 0)
                .progressViewStyle(LinearProgressViewStyle(tint: goal.color))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateProgress)
            
            HStack {
                Text("\(goal.currentCount)/\(goal.targetCount) Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if goal.currentCount < goal.targetCount {
                    Button(action: {
                        withAnimation(.spring(response: 0.4)) {
                            goalManager.markGoalCompleted(goal)
                        }
                    }) {
                        Text("Complete")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(goal.color, in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Completed!")
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(
            GlassEffectView(cornerRadius: 12, tintColor: isHovered ? goal.color.opacity(0.1) : nil) {
                Color.clear
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? goal.color.opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(Double.random(in: 0...0.3))) {
                animateProgress = true
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditGoalView(goal: goal)
                .environmentObject(goalManager)
        }
        .contextMenu {
            Button(action: { showingEdit = true }) {
                Label("Edit Goal", systemImage: "pencil")
            }
            Button(action: {
                goalManager.markGoalCompleted(goal)
            }) {
                Label("Mark Complete", systemImage: "checkmark")
            }
            if !goal.isDefault {
                Divider()
                Button(role: .destructive, action: {
                    goalManager.deleteGoal(goal)
                }) {
                    Label("Delete Goal", systemImage: "trash")
                }
            }
        }
    }
}



// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovered ? Color.primary.opacity(0.2) : .gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct GoalsListView: View {
    @EnvironmentObject var goalManager: GoalManager
    @State private var searchText = ""
    @Binding var isSelectionMode: Bool
    @Binding var selectedGoals: Set<UUID>
    @Namespace private var glassNamespace
    
    var filteredGoals: [Goal] {
        if searchText.isEmpty {
            return goalManager.goals
        } else {
            return goalManager.goals.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var nonDefaultFilteredGoals: [Goal] {
        filteredGoals.filter { !$0.isDefault }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Goals")
                    .font(.largeTitle.bold())
                Spacer()
            }
            .padding(.horizontal)

            // Selection Mode Header
            if isSelectionMode {
                HStack {
                    Text("\(selectedGoals.count) selected")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider()
                .padding(.vertical)

            // Goals List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredGoals) { goal in
                        GoalRowView(goal: goal, isSelectionMode: isSelectionMode, isSelected: selectedGoals.contains(goal.id)) { isSelected in
                            if isSelected {
                                selectedGoals.insert(goal.id)
                            } else {
                                selectedGoals.remove(goal.id)
                            }
                        }
                        .environmentObject(goalManager)
                    }
                }
                .padding()
            }
        }
        .searchable(text: $searchText)
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

// MARK: - Goal Row View
struct GoalRowView: View {
    @EnvironmentObject var goalManager: GoalManager
    let goal: Goal
    let isSelectionMode: Bool
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    @State private var isHovered = false
    @State private var showingEdit = false
    
    init(goal: Goal, isSelectionMode: Bool = false, isSelected: Bool = false, onSelectionChanged: @escaping (Bool) -> Void = { _ in }) {
        self.goal = goal
        self.isSelectionMode = isSelectionMode
        self.isSelected = isSelected
        self.onSelectionChanged = onSelectionChanged
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection Checkbox
            if isSelectionMode && !goal.isDefault {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onSelectionChanged(!isSelected)
                    }
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .gray)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                .buttonStyle(.plain)
            }
            
            // Goal Icon
            Image(systemName: goal.icon)
                .font(.title2)
                .foregroundColor(goal.color)
                .frame(width: 40, height: 40)
                .background(goal.color.opacity(0.1), in: Circle())
            
            // Goal Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if goal.isDefault {
                        Text("Default")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue, in: Capsule())
                    }
                }
                
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Progress
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(goal.currentCount)/\(goal.targetCount)")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: goal.color))
                    .frame(width: 100)
            }
            
            // Actions
            if isHovered && !isSelectionMode {
                HStack(spacing: 8) {
                    Button(action: { showingEdit = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    if goal.currentCount < goal.targetCount {
                        Button(action: {
                            withAnimation(.spring()) {
                                goalManager.markGoalCompleted(goal)
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(16)
        .background(
            GlassEffectView(cornerRadius: 12, tintColor: isHovered ? goal.color.opacity(0.1) : nil) {
                Color.clear
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? goal.color.opacity(0.3) : Color.white.opacity(0.2), lineWidth: 1)
        )
        .opacity(goal.isDefault && isSelectionMode ? 0.6 : 1.0)
        .onHover { hovering in
            if !isSelectionMode {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditGoalView(goal: goal)
                .environmentObject(goalManager)
        }
    }
}


// MARK: - Create Goal View
struct CreateGoalView: View {
    @EnvironmentObject var goalManager: GoalManager
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var selectedIcon = "target"
    @State private var selectedColor = Color.blue
    @State private var targetCount = 1
    @State private var reminderTime = Date()
    @State private var enableReminders = true
    
    let icons = ["target", "book.fill", "dumbbell.fill", "leaf.fill", "heart.fill", "brain.head.profile", "figure.walk"]
    let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .cyan]
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                // Header
                HStack {
                    Text("Create New Goal")
                        .font(.title.bold())
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                BlurView(style: .hudWindow)
                                    .clipShape(Capsule())
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Basic Info
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                Text("Basic Information")
                                    .font(.headline.bold())
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Goal Title")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                
                                TextField("Enter your goal title...", text: $title)
                                    .textFieldStyle(.plain)
                                    .padding(16)
                                    .background(
                                        BlurView(style: .hudWindow)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description (Optional)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                
                                TextField("Add a description for your goal...", text: $description, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .lineLimit(3...6)
                                    .padding(10)
                                    .background(
                                        BlurView(style: .hudWindow)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                    )
                            }
                        }
                        .padding(18)
                        .background(
                            BlurView(style: .hudWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icon")
                                .font(.headline)

                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                                ForEach(icons, id: \.self) { icon in
                                    Button(action: { selectedIcon = icon }) {
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(selectedIcon == icon ? .white : selectedColor)
                                            .frame(width: 40, height: 40)
                                            .background(selectedIcon == icon ? selectedColor : selectedColor.opacity(0.1), in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                ForEach(colors, id: \.self) { color in
                                    Button(action: { selectedColor = color }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                            )
                                            .shadow(radius: selectedColor == color ? 3 : 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Target & Reminders
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                Text("Target & Reminders")
                                    .font(.headline.bold())
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Daily Target")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 16) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            if targetCount > 1 {
                                                targetCount -= 1
                                            }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(targetCount > 1 ? .primary : .gray)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(targetCount <= 1)
                                    
                                    Spacer()
                                    
                                    Text("\(targetCount)")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                        .frame(minWidth: 60)
                                        .scaleEffect(targetCount > 0 ? 1.0 : 0.8)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: targetCount)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            if targetCount < 10 {
                                                targetCount += 1
                                            }
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(targetCount < 10 ? .primary : .gray)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(targetCount >= 10)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                                .background(
                                    BlurView(style: .hudWindow)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                )
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Reminders")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: 16) {
                                    Toggle("Enable reminders", isOn: $enableReminders)
                                        .toggleStyle(SwitchToggleStyle(tint: .primary))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            BlurView(style: .hudWindow)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                        )
                                    
                                    if enableReminders {
                                        DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(CompactDatePickerStyle())
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 16)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                BlurView(style: .hudWindow)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            BlurView(style: .hudWindow)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        
                        // Add bottom padding to ensure content doesn't get hidden behind floating button
                        Spacer(minLength: 80)
                    }
                }
            }
            
            // Floating Create Goal Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: createGoal) {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                GlassEffectView(cornerRadius: 28, tintColor: .blue.opacity(0.3)) {
                                    Color.clear
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.blue.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(title.isEmpty)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }
            }
        }
        .padding(16)
        .background(
            BlurView(style: .hudWindow)
                .clipShape(RoundedRectangle(cornerRadius: 27))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .frame(width: 500, height: 600)
    }
    
    private func createGoal() {
        // Validate input
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Show error or alert
            return
        }
        
        let goal = Goal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: selectedIcon,
            color: selectedColor,
            targetCount: targetCount,
            reminderTime: enableReminders ? reminderTime : nil
        )
        
        // Add goal and handle any errors
        goalManager.addGoal(goal)
        
        // Schedule notification if enabled
        if enableReminders {
            scheduleNotification(for: goal)
        }
        
        // Provide feedback
        HapticFeedback.shared.success()
        
        dismiss()
    }
    
    private func scheduleNotification(for goal: Goal) {
        guard let reminderTime = goal.reminderTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Goal Reminder"
        content.body = "Time to work on: \(goal.title)"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "goal_\(goal.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Edit Goal View
struct EditGoalView: View {
    @EnvironmentObject var goalManager: GoalManager
    @Environment(\.dismiss) private var dismiss
    let goal: Goal
    
    @State private var title: String
    @State private var description: String
    @State private var selectedIcon: String
    @State private var selectedColor: Color
    @State private var targetCount: Int
    @State private var reminderTime: Date
    @State private var enableReminders: Bool
    
    init(goal: Goal) {
        self.goal = goal
        _title = State(initialValue: goal.title)
        _description = State(initialValue: goal.description)
        _selectedIcon = State(initialValue: goal.icon)
        _selectedColor = State(initialValue: goal.color)
        _targetCount = State(initialValue: goal.targetCount)
        _reminderTime = State(initialValue: goal.reminderTime ?? Date())
        _enableReminders = State(initialValue: goal.reminderTime != nil)
    }
    
    let icons = ["target", "book.fill", "dumbbell.fill", "leaf.fill", "heart.fill", "brain.head.profile", "figure.walk"]
    let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .cyan]
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Edit Goal")
                    .font(.title.bold())
                
                Spacer()
                
                Button("Cancel") { dismiss() }
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Basic Information")
                            .font(.headline)
                        
                        TextField("Goal title", text: $title)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Description (optional)", text: $description, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    
                    // Icon Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .white : selectedColor)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? selectedColor : selectedColor.opacity(0.1), in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .shadow(radius: selectedColor == color ? 3 : 1)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Target & Reminders
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.circle.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                            Text("Target & Reminders")
                                .font(.headline.bold())
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Target")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 16) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        if targetCount > 1 {
                                            targetCount -= 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(targetCount > 1 ? .primary : .gray)
                                }
                                .buttonStyle(.plain)
                                .disabled(targetCount <= 1)
                                
                                Text("\(targetCount)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 60)
                                    .scaleEffect(targetCount > 0 ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: targetCount)
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        if targetCount < 10 {
                                            targetCount += 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(targetCount < 10 ? .primary : .gray)
                                }
                                .buttonStyle(.plain)
                                .disabled(targetCount >= 10)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                BlurView(style: .hudWindow)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 3)
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reminders")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 12) {
                                Toggle("Enable reminders", isOn: $enableReminders)
                                    .toggleStyle(SwitchToggleStyle(tint: .primary))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        BlurView(style: .hudWindow)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                    )
                                
                                if enableReminders {
                                    DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            BlurView(style: .hudWindow)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.5), lineWidth: 3)
                                        )
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(
                        BlurView(style: .hudWindow)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                if !goal.isDefault {
                    Button(action: deleteGoal) {
                        Text("Delete")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                
                HStack {
                    Spacer()
                    Button(action: saveGoal) {
                        Image(systemName: "checkmark")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                GlassEffectView(cornerRadius: 28, tintColor: .blue.opacity(0.3)) {
                                    Color.clear
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Color.blue.opacity(0.2), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(title.isEmpty)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }
            }
        }
        .padding(24)
        .frame(width: 500, height: 600)
    }
    
    private func saveGoal() {
        var updatedGoal = goal
        updatedGoal.title = title
        updatedGoal.description = description
        updatedGoal.icon = selectedIcon
        updatedGoal.color = selectedColor
        updatedGoal.targetCount = targetCount
        updatedGoal.reminderTime = enableReminders ? reminderTime : nil
        
        goalManager.updateGoal(updatedGoal)
        
        // Update notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["goal_\(goal.id)"])
        
        if enableReminders {
            scheduleNotification(for: updatedGoal)
        }
        
        dismiss()
    }
    
    private func deleteGoal() {
        goalManager.deleteGoal(goal)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["goal_\(goal.id)"])
        dismiss()
    }
    
    private func scheduleNotification(for goal: Goal) {
        guard let reminderTime = goal.reminderTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Goal Reminder"
        content.body = "Time to work on: \(goal.title)"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "goal_\(goal.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var goalManager: GoalManager
    @State private var selectedTimeRange = TimeRange.week
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    // Helper functions for time range styling
    private func colorForTimeRange(_ range: TimeRange) -> Color {
        switch range {
        case .week: return .blue
        case .month: return .purple
        case .year: return .orange
        }
    }
    
    private func iconForTimeRange(_ range: TimeRange) -> String {
        switch range {
        case .week: return "calendar.badge.clock"
        case .month: return "calendar"
        case .year: return "calendar.circle"
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analytics")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Track your progress and achievements")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Time Range Selector
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time Range")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Select your analysis period")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: { selectedTimeRange = range }) {
                                HStack(spacing: 6) {
                                    Image(systemName: iconForTimeRange(range))
                                        .font(.caption)
                                        .foregroundColor(selectedTimeRange == range ? .white : colorForTimeRange(range))
                                    
                                    Text(range.rawValue)
                                        .font(.subheadline.bold())
                                        .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    selectedTimeRange == range ?
                                        LinearGradient(
                                            colors: [colorForTimeRange(range), colorForTimeRange(range).opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.04)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedTimeRange == range ?
                                                colorForTimeRange(range).opacity(0.4) :
                                                Color.gray.opacity(0.15),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: selectedTimeRange == range ?
                                        colorForTimeRange(range).opacity(0.3) :
                                        Color.clear,
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(selectedTimeRange == range ? 1.05 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTimeRange)
                        }
                    }
                }
                .padding(16)
                .background(
                    BlurView(style: .hudWindow)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Chart
                    ProgressChartView(timeRange: selectedTimeRange)
                        .environmentObject(goalManager)
                    
                    // Goal Performance Chart
                    GoalPerformanceChart()
                        .environmentObject(goalManager)
                    
                    // Goal Statistics
                    GoalStatisticsView()
                        .environmentObject(goalManager)
                    
                    // Achievement Section
                    AchievementsView()
                        .environmentObject(goalManager)
                }
                .padding()
            }
        }
    }
}

// MARK: - Progress Chart View
struct ProgressChartView: View {
    @EnvironmentObject var goalManager: GoalManager
    let timeRange: AnalyticsView.TimeRange
    @State private var animateChart = false
    
    var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .week:
            return (0..<7).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
                let progress = goalManager.getCompletionRate(for: date)
                return ChartDataPoint(date: date, progress: animateChart ? progress : 0)
            }.reversed()
            
        case .month:
            return (0..<30).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
                let progress = goalManager.getCompletionRate(for: date)
                return ChartDataPoint(date: date, progress: animateChart ? progress : 0)
            }.reversed()
            
        case .year:
            return (0..<12).map { monthOffset in
                let date = calendar.date(byAdding: .month, value: -monthOffset, to: now) ?? now
                let progress = goalManager.getMonthlyCompletionRate(for: date)
                return ChartDataPoint(date: date, progress: animateChart ? progress : 0)
            }.reversed()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Over Time")
                .font(.title2.bold())
            
            Chart(chartData) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Progress", dataPoint.progress)
                )
                .foregroundStyle(.primary)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Progress", dataPoint.progress)
                )
                .foregroundStyle(.primary.opacity(0.2))
            }
            .frame(height: 200)
            .chartYScale(domain: 0...1)
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange == .week ? .day : .month)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange == .week ? .dateTime.weekday(.abbreviated) : .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let progress = value.as(Double.self) {
                            Text("\(Int(progress * 100))%")
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            BlurView(style: .hudWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateChart = true
            }
        }
        .onChange(of: timeRange) { _ in
            animateChart = false
            withAnimation(.easeInOut(duration: 0.8)) {
                animateChart = true
            }
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let progress: Double
}

// MARK: - Goal Performance Chart
struct GoalPerformanceChart: View {
    @EnvironmentObject var goalManager: GoalManager
    @State private var animateChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Performance")
                .font(.title2.bold())
            
            if goalManager.goals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No goals to display")
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            } else {
                Chart(goalManager.goals) { goal in
                    BarMark(
                        x: .value("Goal", goal.title),
                        y: .value("Completion Rate", animateChart ? goal.progress : 0)
                    )
                    .foregroundStyle(goal.color.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let progress = value.as(Double.self) {
                                Text("\(Int(progress * 100))%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let title = value.as(String.self) {
                                Text(title.prefix(8))
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            BlurView(style: .hudWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }
}

// MARK: - Goal Statistics View
struct GoalStatisticsView: View {
    @EnvironmentObject var goalManager: GoalManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.title2.bold())
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticCard(
                    title: "Completion Rate",
                    value: "\(Int(goalManager.averageCompletionRate * 100))%",
                    icon: "chart.pie.fill",
                    color: .primary
                )
                
                StatisticCard(
                    title: "Current Streak",
                    value: "\(goalManager.currentStreak)",
                    icon: "flame.fill",
                    color: .primary
                )
                
                StatisticCard(
                    title: "Best Streak",
                    value: "\(goalManager.bestStreak)",
                    icon: "trophy.fill",
                    color: .primary
                )
                
                StatisticCard(
                    title: "Today Completed",
                    value: "\(goalManager.todayCompletedGoals)/\(goalManager.goals.count)",
                    icon: "checkmark.circle.fill",
                    color: .primary
                )
                
                StatisticCard(
                    title: "Active Goals",
                    value: "\(goalManager.goals.count)",
                    icon: "target",
                    color: .primary
                )
                
                StatisticCard(
                    title: "Total Completions",
                    value: "\(goalManager.totalGoalCompletions)",
                    icon: "calendar",
                    color: .primary
                )
            }
        }
        .padding(20)
        .background(
            BlurView(style: .hudWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}

// MARK: - Statistic Card
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @State private var animateValue = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .scaleEffect(animateValue ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: animateValue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(Double.random(in: 0...0.5))) {
                animateValue = true
            }
        }
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @EnvironmentObject var goalManager: GoalManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.title2.bold())
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(goalManager.achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .padding(.leading,20)
        .background(
            BlurView(style: .hudWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                .scaleEffect(isHovered ? 1.2 : 1.0)
                .animation(.spring(response: 0.3), value: isHovered)
            
            Text(achievement.title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if achievement.isUnlocked {
                Text("Unlocked!")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            } else {
                ProgressView(value: achievement.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                Text("\(Int(achievement.progress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 160, height: 180)
        .background(
            achievement.isUnlocked ?
                LinearGradient(colors: [.yellow.opacity(0.2), .orange.opacity(0.1)], startPoint: .top, endPoint: .bottom) :
                LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.isUnlocked ? .yellow.opacity(0.5) : .gray.opacity(0.2), lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Settings View (COMMENTED OUT FOR FUTURE USE)
/*
struct SettingsView: View {
    @EnvironmentObject var goalManager: GoalManager
    @State private var enableNotifications = true
    @State private var darkMode = false
    @State private var autoStart = true
    @State private var soundEnabled = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Settings")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Customize your experience")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Notifications Section
                    SettingsGlassContainer(title: "Notifications", icon: "bell.fill") {
                        VStack(spacing: 16) {
                            SettingsToggleRow(
                                title: "Enable Notifications",
                                subtitle: "Get reminders for your goals",
                                icon: "bell.badge",
                                isOn: $enableNotifications
                            )
                            
                            if enableNotifications {
                                SettingsToggleRow(
                                    title: "Sound Alerts",
                                    subtitle: "Play sound with notifications",
                                    icon: "speaker.wave.2",
                                    isOn: $soundEnabled
                                )
                            }
                        }
                    }
                    
                    // Appearance Section
                    SettingsGlassContainer(title: "Appearance", icon: "paintbrush.fill") {
                        SettingsToggleRow(
                            title: "Dark Mode",
                            subtitle: "Use dark appearance",
                            icon: "moon.fill",
                            isOn: $darkMode
                        )
                    }
                    
                    // Behavior Section
                    SettingsGlassContainer(title: "Behavior", icon: "gear") {
                        SettingsToggleRow(
                            title: "Auto-start on Login",
                            subtitle: "Launch app when you log in",
                            icon: "power",
                            isOn: $autoStart
                        )
                    }
                    
                    // Data Management Section
                    SettingsGlassContainer(title: "Data Management", icon: "externaldrive.fill") {
                        VStack(spacing: 12) {
                            SettingsActionRow(
                                title: "Export Data",
                                subtitle: "Backup your goals and progress",
                                icon: "square.and.arrow.up",
                                color: .blue
                            ) {
                                exportData()
                            }
                            
                            SettingsActionRow(
                                title: "Reset All Data",
                                subtitle: "Permanently delete all data",
                                icon: "trash",
                                color: .red
                            ) {
                                resetData()
                            }
                        }
                    }
                    
                    // About Section
                    SettingsGlassContainer(title: "About", icon: "info.circle.fill") {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                Image(systemName: "target")
                                    .font(.title)
                                    .foregroundColor(.primary)
                                    .frame(width: 40, height: 40)
                                    .background(.primary.opacity(0.1), in: Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dailytasks")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Goal tracking made simple")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Version")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("1.0.0")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Built with")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("SwiftUI")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func exportData() {
        // Implement data export
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "goals_backup.json"
        
        if panel.runModal() == .OK {
            goalManager.exportData(to: panel.url)
        }
    }
    
    private func resetData() {
        let alert = NSAlert()
        alert.messageText = "Reset All Data"
        alert.informativeText = "This will permanently delete all your goals and progress. This action cannot be undone."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Reset")
        
        if alert.runModal() == .alertSecondButtonReturn {
            goalManager.resetAllData()
        }
    }
}
*/

// MARK: - Settings Glass Container (COMMENTED OUT FOR FUTURE USE)
/*
struct SettingsGlassContainer<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
                    .background(.primary.opacity(0.1), in: Circle())
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            content()
        }
        .padding(20)
        .background(
            BlurView(style: .hudWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
*/

// MARK: - Settings Toggle Row (COMMENTED OUT FOR FUTURE USE)
/*
struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primary)
                .frame(width: 28, height: 28)
                .background(.primary.opacity(0.1), in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .primary))
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .padding(16)
        .background(
            isHovered ? Color.gray.opacity(0.1) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
*/

// MARK: - Settings Action Row (COMMENTED OUT FOR FUTURE USE)
/*
struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.1), in: Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1.0 : 0.5)
            }
            .padding(16)
            .background(
                isHovered ? color.opacity(0.05) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
*/

// MARK: - Data Models
struct Goal: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var icon: String
    var color: Color
    var targetCount: Int
    var currentCount: Int = 0
    var reminderTime: Date?
    var createdAt: Date = Date()
    var completedDates: [Date] = []
    var isDefault: Bool = false // Flag to identify default goals
    
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return Double(currentCount) / Double(targetCount)
    }
    
    var isCompletedToday: Bool {
        let calendar = Calendar.current
        return completedDates.contains { calendar.isDate($0, inSameDayAs: Date()) }
    }
}

struct Achievement: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool = false
    var progress: Double = 0.0
    var unlockedAt: Date?
}

// MARK: - Goal Manager
@MainActor
class GoalManager: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var achievements: [Achievement] = []
    
    private let userDefaults = UserDefaults.standard
    private let goalsKey = "SavedGoals"
    private let achievementsKey = "SavedAchievements"
    
    init() {
        loadGoals()
        loadAchievements()
        createDefaultAchievements()
    }
    
    // MARK: - Goal Management
    func addGoal(_ goal: Goal) {
        print("Adding goal: \(goal.title)")
        goals.append(goal)
        print("Total goals after adding: \(goals.count)")
        saveGoals()
        updateAchievements()
        print("Goal added successfully")
    }
    
    func updateGoal(_ updatedGoal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) {
            goals[index] = updatedGoal
            saveGoals()
        }
    }
    
    func deleteGoal(_ goal: Goal) {
        // Prevent deletion of default goals
        if goal.isDefault {
            print("Cannot delete default goal: \(goal.title)")
            return
        }
        
        goals.removeAll { $0.id == goal.id }
        saveGoals()
    }
    
    func markGoalCompleted(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            // Increment the current count
            goals[index].currentCount = min(goals[index].currentCount + 1, goal.targetCount)
            
            // Add completion date if this is the first completion today
            if !goals[index].isCompletedToday {
                goals[index].completedDates.append(Date())
            }
            
            print("Goal '\(goal.title)' completed. Current count: \(goals[index].currentCount)/\(goal.targetCount)")
            
            saveGoals()
            updateAchievements()
            
            // Send completion notification only when fully completed
            if goals[index].currentCount >= goal.targetCount {
                sendCompletionNotification(for: goal)
            }
        }
    }
    
    func resetDailyProgress() {
        for index in goals.indices {
            goals[index].currentCount = 0
        }
        saveGoals()
    }
    
    // MARK: - Statistics
    var averageCompletionRate: Double {
        guard !goals.isEmpty else { return 0 }
        
        // Calculate completion rate based on today's progress
        let completedToday = goals.filter { $0.currentCount >= $0.targetCount }.count
        return Double(completedToday) / Double(goals.count)
    }
    
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let hasCompletionOnDate = goals.allSatisfy { goal in
                goal.completedDates.contains { calendar.isDate($0, inSameDayAs: currentDate) }
            }
            
            if hasCompletionOnDate && !goals.isEmpty {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    var bestStreak: Int {
        // Calculate best streak from historical data
        return max(currentStreak, userDefaults.integer(forKey: "BestStreak"))
    }
    
    var totalCompletedGoals: Int {
        goals.reduce(0) { $0 + $1.completedDates.count }
    }
    
    var totalGoalCompletions: Int {
        goals.reduce(0) { $0 + $1.completedDates.count }
    }
    
    var todayCompletedGoals: Int {
        goals.filter { $0.currentCount >= $0.targetCount }.count
    }
    
    var averageDailyGoals: Double {
        let calendar = Calendar.current
        let daysSinceStart = goals.compactMap { goal in
            calendar.dateComponents([.day], from: goal.createdAt, to: Date()).day
        }.max() ?? 1
        
        return Double(totalCompletedGoals) / Double(max(daysSinceStart, 1))
    }
    
    // MARK: - Analytics Data Methods
    func getCompletionRate(for date: Date) -> Double {
        guard !goals.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let completedGoals = goals.filter { goal in
            goal.completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
        }.count
        
        return Double(completedGoals) / Double(goals.count)
    }
    
    func getMonthlyCompletionRate(for date: Date) -> Double {
        guard !goals.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let monthEnd = calendar.dateInterval(of: .month, for: date)?.end ?? date
        
        var totalCompletions = 0
        var totalPossibleCompletions = 0
        
        for goal in goals {
            let completionsInMonth = goal.completedDates.filter { completionDate in
                completionDate >= monthStart && completionDate < monthEnd
            }.count
            
            let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
            totalCompletions += completionsInMonth
            totalPossibleCompletions += daysInMonth * goal.targetCount
        }
        
        return totalPossibleCompletions > 0 ? Double(totalCompletions) / Double(totalPossibleCompletions) : 0
    }
    
    func getGoalCompletionHistory(for goal: Goal, days: Int = 30) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<days).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            let wasCompleted = goal.completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
            return ChartDataPoint(date: date, progress: wasCompleted ? 1.0 : 0.0)
        }.reversed()
    }
    
    // MARK: - Data Persistence
    private func saveGoals() {
        do {
            let encoded = try JSONEncoder().encode(goals)
            userDefaults.set(encoded, forKey: goalsKey)
            print("Goals saved successfully: \(goals.count) goals")
        } catch {
            print("Error saving goals: \(error)")
        }
    }
    
    private func loadGoals() {
        if let data = userDefaults.data(forKey: goalsKey) {
            do {
                let decoded = try JSONDecoder().decode([Goal].self, from: data)
                goals = decoded
                print("Loaded \(goals.count) goals from storage")
            } catch {
                print("Error loading goals: \(error)")
                goals = []
            }
        } else {
            print("No saved goals found, creating default goals")
            createDefaultGoals()
        }
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
    }
    
    // MARK: - Default Goals
    private func createDefaultGoals() {
        let defaultGoals = [
            Goal(
                title: "Exercise",
                description: "30 minutes of physical activity",
                icon: "dumbbell.fill",
                color: .green,
                targetCount: 1,
                isDefault: true
            ),
            Goal(
                title: "Read",
                description: "Read for 20 minutes",
                icon: "book.fill",
                color: .blue,
                targetCount: 1,
                isDefault: true
            ),
            Goal(
                title: "Meditate",
                description: "10 minutes of mindfulness",
                icon: "leaf.fill",
                color: .purple,
                targetCount: 1,
                isDefault: true
            ),
            Goal(
                title: "Water",
                description: "Drink 8 glasses of water",
                icon: "drop.fill",
                color: .cyan,
                targetCount: 8,
                isDefault: true
            )
        ]
        
        goals = defaultGoals
        saveGoals()
        print("Created \(defaultGoals.count) default goals")
    }
    
    // MARK: - Achievements
    private func createDefaultAchievements() {
        let defaultAchievements = [
            Achievement(
                title: "First Goal",
                description: "Create your first goal",
                icon: "target"
            ),
            Achievement(
                title: "Streak Starter",
                description: "Complete goals for 3 days in a row",
                icon: "flame.fill"
            ),
            Achievement(
                title: "Week Warrior",
                description: "Complete goals for 7 days in a row",
                icon: "calendar"
            ),
            Achievement(
                title: "Goal Getter",
                description: "Complete 10 goals",
                icon: "trophy.fill"
            ),
            Achievement(
                title: "Consistency King",
                description: "Complete goals for 30 days in a row",
                icon: "crown.fill"
            )
        ]
        
        for defaultAchievement in defaultAchievements {
            if !achievements.contains(where: { $0.title == defaultAchievement.title }) {
                achievements.append(defaultAchievement)
            }
        }
        saveAchievements()
    }
    
    private func updateAchievements() {
        var updated = false
        
        // First Goal
        if let index = achievements.firstIndex(where: { $0.title == "First Goal" }) {
            if !achievements[index].isUnlocked && !goals.isEmpty {
                achievements[index].isUnlocked = true
                achievements[index].unlockedAt = Date()
                updated = true
            }
        }
        
        // Streak achievements
        let streak = currentStreak
        if let index = achievements.firstIndex(where: { $0.title == "Streak Starter" }) {
            achievements[index].progress = min(1.0, Double(streak) / 3.0)
            if !achievements[index].isUnlocked && streak >= 3 {
                achievements[index].isUnlocked = true
                achievements[index].unlockedAt = Date()
                updated = true
            }
        }
        
        if let index = achievements.firstIndex(where: { $0.title == "Week Warrior" }) {
            achievements[index].progress = min(1.0, Double(streak) / 7.0)
            if !achievements[index].isUnlocked && streak >= 7 {
                achievements[index].isUnlocked = true
                achievements[index].unlockedAt = Date()
                updated = true
            }
        }
        
        if let index = achievements.firstIndex(where: { $0.title == "Consistency King" }) {
            achievements[index].progress = min(1.0, Double(streak) / 30.0)
            if !achievements[index].isUnlocked && streak >= 30 {
                achievements[index].isUnlocked = true
                achievements[index].unlockedAt = Date()
                updated = true
            }
        }
        
        // Goal completion achievements
        let totalCompleted = totalCompletedGoals
        if let index = achievements.firstIndex(where: { $0.title == "Goal Getter" }) {
            achievements[index].progress = min(1.0, Double(totalCompleted) / 10.0)
            if !achievements[index].isUnlocked && totalCompleted >= 10 {
                achievements[index].isUnlocked = true
                achievements[index].unlockedAt = Date()
                updated = true
            }
        }
        
        if updated {
            saveAchievements()
        }
        
        // Update best streak
        if streak > bestStreak {
            userDefaults.set(streak, forKey: "BestStreak")
        }
    }
    
    // MARK: - Notifications
    private func sendCompletionNotification(for goal: Goal) {
        let content = UNMutableNotificationContent()
        content.title = "Goal Completed! 🎉"
        content.body = "Great job completing: \(goal.title)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "completion_\(goal.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Data Export/Import
    func exportData(to url: URL?) {
        guard let url = url else { return }
        
        let exportData = [
            "goals": goals,
            "achievements": achievements,
            "exportDate": Date()
        ] as [String: Any]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
            try? jsonData.write(to: url)
        }
    }
    
    func resetAllData() {
        goals.removeAll()
        achievements.removeAll()
        userDefaults.removeObject(forKey: goalsKey)
        userDefaults.removeObject(forKey: achievementsKey)
        userDefaults.removeObject(forKey: "BestStreak")
        
        // Remove all notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        createDefaultAchievements()
    }
}

// MARK: - App Intents (Commented out due to compatibility issues)
/*
struct CompleteGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Goal"
    static var description = IntentDescription("Mark a goal as completed for today")
    
    @Parameter(title: "Goal")
    var goal: GoalEntity
    
    func perform() async throws -> some IntentResult {
        // Implementation would connect to the goal manager
        return .result()
    }
}

struct GoalEntity: AppEntity, Identifiable, Sendable {
    let id: UUID
    let title: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Goal"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
    
    static var defaultQuery = GoalQuery()
    
    // MARK: - AppEntity conformance
    static var typeDisplayName: LocalizedStringResource = "Goal"
    
    var displayName: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: title)
    }
}

struct GoalQuery: EntityQuery, Sendable {
    func entities(for identifiers: [UUID]) async throws -> [GoalEntity] {
        // Implementation would fetch goals by ID
        return []
    }
    
    func suggestedEntities() async throws -> [GoalEntity] {
        // Implementation would return all available goals
        return []
    }
}

struct AddGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Goal"
    static var description = IntentDescription("Create a new goal")
    
    @Parameter(title: "Goal Title")
    var title: String
    
    @Parameter(title: "Description")
    var description: String?
    
    func perform() async throws -> some IntentResult {
        // Implementation would create a new goal
        return .result()
    }
}
*/

// MARK: - Color Codable Extension
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let nsColor = NSColor(self)
        let colorSpace = NSColorSpace.sRGB
        let convertedColor = nsColor.usingColorSpace(colorSpace) ?? nsColor
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        convertedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .alpha)
    }
}

// MARK: - App Delegate for Menu Bar
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var goalManager: GoalManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "target", accessibilityDescription: "GoalTracker")
            button.action = #selector(menuBarItemClicked)
            button.target = self
        }
        
        // Setup menu
        setupMenu()
        
        // Schedule daily reset
        scheduleDailyReset()
    }
    
    @objc func menuBarItemClicked() {
        guard let statusItem = statusItem else { return }
        
        if let menu = statusItem.menu {
            statusItem.popUpMenu(menu)
        }
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Quick add goal
        let addGoalItem = NSMenuItem(title: "Quick Add Goal", action: #selector(quickAddGoal), keyEquivalent: "n")
        addGoalItem.target = self
        menu.addItem(addGoalItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Today's goals (will be populated dynamically)
        updateMenuWithGoals(menu: menu)
        
        menu.addItem(NSMenuItem.separator())
        
        // Show main window
        let showWindowItem = NSMenuItem(title: "Show GoalTracker", action: #selector(showMainWindow), keyEquivalent: "")
        showWindowItem.target = self
        menu.addItem(showWindowItem)
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit GoalTracker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func updateMenuWithGoals(menu: NSMenu) {
        // This would be called to update the menu with current goals
        // Implementation would integrate with GoalManager
    }
    
    @objc func quickAddGoal() {
        // Show quick add goal dialog
        let alert = NSAlert()
        alert.messageText = "Quick Add Goal"
        alert.informativeText = "Enter a goal title:"
        alert.alertStyle = .informational
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "Goal title..."
        alert.accessoryView = textField
        
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn && !textField.stringValue.isEmpty {
            // Create goal with default settings
            let goal = Goal(
                title: textField.stringValue,
                description: "",
                icon: "target",
                color: .blue,
                targetCount: 1
            )
            goalManager?.addGoal(goal)
        }
    }
    
    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func showSettings() {
        // Implementation to show settings
        showMainWindow()
    }
    
    private func scheduleDailyReset() {
        let calendar = Calendar.current
        let now = Date()
        
        // Schedule for midnight
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.day! += 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        if let midnight = calendar.date(from: components) {
            let timer = Timer(fireAt: midnight, interval: 24 * 60 * 60, target: self, selector: #selector(performDailyReset), userInfo: nil, repeats: true)
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    @objc func performDailyReset() {
        goalManager?.resetDailyProgress()
    }
}

// MARK: - Animated Background View
struct AnimatedBackgroundView: View {
    @State private var phase: Double = 0
    
    var body: some View {
        Canvas { context, size in
            let gradient = Gradient(colors: [
                .blue.opacity(0.4),
                .pink.opacity(0.05),
                .clear
            ])
            
            // Create animated gradient circles
            for i in 0..<5 {
                let offset = Double(i) * 0.2
                let x = size.width * 0.5 + cos(phase + offset) * size.width * 0.3
                let y = size.height * 0.5 + sin(phase + offset * 1.5) * size.height * 0.2
                let radius = 100 + sin(phase + offset) * 50
                
                let circle = Path { path in
                    path.addEllipse(in: CGRect(
                        x: x - radius,
                        y: y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                }
                
                context.fill(circle, with: .radialGradient(
                    gradient,
                    center: CGPoint(x: x, y: y),
                    startRadius: 0,
                    endRadius: radius
                ))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let action: () -> Void
    @State private var isHovered = false
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Color.primary,
                    in: Circle()
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .scaleEffect(isPulsing ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.easeInOut(duration: 1).repeatForever(), value: isPulsing)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Goal Progress Ring
struct GoalProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.5), color, color.opacity(0.5)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Confetti Effect
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                RoundedRectangle(cornerRadius: 2)
                    .fill(particle.color)
                    .frame(width: particle.size.width, height: particle.size.height)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        particles = []
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                position: CGPoint(x: Double.random(in: 0...400), y: -10),
                velocity: CGPoint(x: Double.random(in: -50...50), y: Double.random(in: 100...200)),
                color: [.blue, .green, .orange, .purple, .red, .pink].randomElement() ?? .blue,
                size: CGSize(width: Double.random(in: 4...8), height: Double.random(in: 4...8)),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            particles.append(particle)
        }
    }
    
    private func animateParticles() {
        withAnimation(.linear(duration: 3)) {
            for i in particles.indices {
                particles[i].position.y += particles[i].velocity.y * 3
                particles[i].position.x += particles[i].velocity.x * 3
                particles[i].rotation += 360
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let velocity: CGPoint
    let color: Color
    let size: CGSize
    var rotation: Double
    var opacity: Double
}

// MARK: - Haptic Feedback
class HapticFeedback {
    static let shared = HapticFeedback()
    
    func success() {
        NSSound.beep()
    }
    
    func impact() {
        NSSound.beep()
    }
    
    func warning() {
        NSSound.beep()
    }
}

// MARK: - Keyboard Shortcuts
struct KeyboardShortcutsView: ViewModifier {
    @EnvironmentObject var goalManager: GoalManager
    @State private var showingQuickAdd = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    handleKeyboardShortcut(event)
                    return event
                }
            }
            .sheet(isPresented: $showingQuickAdd) {
                CreateGoalView()
                    .environmentObject(goalManager)
            }
    }
    
    private func handleKeyboardShortcut(_ event: NSEvent) {
        // Cmd+N for new goal
        if event.modifierFlags.contains(.command) && event.keyCode == 45 {
            showingQuickAdd = true
        }
        
        // Cmd+R for refresh
        if event.modifierFlags.contains(.command) && event.keyCode == 15 {
            goalManager.objectWillChange.send()
        }
    }
}

// MARK: - Window Management
extension NSApplication {
    func setupWindowAppearance() {
        if let window = windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            
            // Set minimum size
            window.minSize = NSSize(width: 800, height: 600)
            
            // Center window
            window.center()
        }
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
                            .background(
                    Color.primary,
                    in: RoundedRectangle(cornerRadius: 8)
                )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom View Modifiers
struct CardStyle: ViewModifier {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    init(backgroundColor: Color = Color(.controlBackgroundColor), cornerRadius: CGFloat = 12) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.gray.opacity(0.1), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(backgroundColor: Color = Color(.controlBackgroundColor), cornerRadius: CGFloat = 12) -> some View {
        modifier(CardStyle(backgroundColor: backgroundColor, cornerRadius: cornerRadius))
    }
    
    func keyboardShortcuts() -> some View {
        modifier(KeyboardShortcutsView())
    }
}

// MARK: - Preview Support
#if DEBUG
extension GoalManager {
    static var preview: GoalManager {
        let manager = GoalManager()
        manager.goals = [
            Goal(title: "Exercise", description: "30 minutes of physical activity", icon: "dumbbell.fill", color: .green, targetCount: 1),
            Goal(title: "Read", description: "Read for 20 minutes", icon: "book.fill", color: .blue, targetCount: 1),
            Goal(title: "Meditate", description: "10 minutes of mindfulness", icon: "leaf.fill", color: .purple, targetCount: 1),
            Goal(title: "Water", description: "Drink 8 glasses of water", icon: "drop.fill", color: .cyan, targetCount: 8)
        ]
        return manager
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GoalManager.preview)
            .frame(width: 800, height: 600)
    }
}

struct CreateGoalView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGoalView()
            .environmentObject(GoalManager.preview)
            .frame(width: 500, height: 600)
    }
}


#endif

struct FloatingAddGoalButton: View {
    @EnvironmentObject var goalManager: GoalManager
    @State private var showingCreateGoal = false
    
    var body: some View {
        Button(action: { showingCreateGoal = true }) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                Text("Add Goal")
                    .font(.headline.bold())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                BlurView(style: .hudWindow)
                    .clipShape(Capsule())
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingCreateGoal) {
            CreateGoalView()
                .environmentObject(goalManager)
        }
    }
}

struct BlurView: NSViewRepresentable {
    let style: NSVisualEffectView.Material
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = style
        view.blendingMode = .withinWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Glass Effect Views
@MainActor
class NSGlassEffectView: NSView {
    var contentView: NSView? {
        didSet {
            if let oldView = oldValue {
                oldView.removeFromSuperview()
            }
            if let newView = contentView {
                addSubview(newView)
                newView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newView.topAnchor.constraint(equalTo: topAnchor),
                    newView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    newView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    newView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            }
        }
    }
    
    var cornerRadius: CGFloat = 12.0 {
        didSet {
            layer?.cornerRadius = cornerRadius
        }
    }
    
    var tintColor: NSColor? {
        didSet {
            layer?.backgroundColor = tintColor?.cgColor
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupGlassEffect()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGlassEffect()
    }
    
    private func setupGlassEffect() {
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true
        
        // Create glass effect using visual effect view
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .withinWindow
        visualEffectView.state = .active
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(visualEffectView)
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Send visual effect view to back
        visualEffectView.layer?.zPosition = -1
    }
}

@MainActor
class NSGlassEffectContainerView: NSView {
    var contentView: NSView? {
        didSet {
            if let oldView = oldValue {
                oldView.removeFromSuperview()
            }
            if let newView = contentView {
                addSubview(newView)
                newView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newView.topAnchor.constraint(equalTo: topAnchor),
                    newView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    newView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    newView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            }
        }
    }
    
    var spacing: CGFloat = 20.0 {
        didSet {
            // Update spacing for glass effect merging
            needsLayout = true
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupContainer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupContainer()
    }
    
    private func setupContainer() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func layout() {
        super.layout()
        // Handle glass effect merging logic here
        mergeNearbyGlassEffects()
    }
    
    private func mergeNearbyGlassEffects() {
        // Find all NSGlassEffectView descendants within spacing proximity
        let glassViews = findGlassEffectViews(in: self)
        
        for (index, glassView) in glassViews.enumerated() {
            for otherGlassView in glassViews.dropFirst(index + 1) {
                if shouldMerge(glassView, with: otherGlassView) {
                    // Merge glass effects
                    mergeGlassEffects(glassView, with: otherGlassView)
                }
            }
        }
    }
    
    private func findGlassEffectViews(in view: NSView) -> [NSGlassEffectView] {
        var glassViews: [NSGlassEffectView] = []
        
        if let glassView = view as? NSGlassEffectView {
            glassViews.append(glassView)
        }
        
        for subview in view.subviews {
            glassViews.append(contentsOf: findGlassEffectViews(in: subview))
        }
        
        return glassViews
    }
    
    private func shouldMerge(_ view1: NSGlassEffectView, with view2: NSGlassEffectView) -> Bool {
        let frame1 = view1.convert(view1.bounds, to: self)
        let frame2 = view2.convert(view2.bounds, to: self)
        
        let distance = calculateDistance(between: frame1, and: frame2)
        return distance <= spacing
    }
    
    private func calculateDistance(between frame1: NSRect, and frame2: NSRect) -> CGFloat {
        let center1 = NSPoint(x: frame1.midX, y: frame1.midY)
        let center2 = NSPoint(x: frame2.midX, y: frame2.midY)
        
        let dx = center2.x - center1.x
        let dy = center2.y - center1.y
        
        return sqrt(dx * dx + dy * dy)
    }
    
    private func mergeGlassEffects(_ view1: NSGlassEffectView, with view2: NSGlassEffectView) {
        // Create a merged glass effect view that encompasses both views
        let mergedFrame = view1.frame.union(view2.frame)
        
        let mergedGlassView = NSGlassEffectView(frame: mergedFrame)
        mergedGlassView.cornerRadius = max(view1.cornerRadius, view2.cornerRadius)
        
        // Add merged view to container
        addSubview(mergedGlassView)
        mergedGlassView.layer?.zPosition = -1
        
        // Hide original views
        view1.isHidden = true
        view2.isHidden = true
    }
}

// SwiftUI wrapper for NSGlassEffectView
struct GlassEffectView: NSViewRepresentable {
    let cornerRadius: CGFloat
    let tintColor: Color?
    let content: () -> AnyView
    
    init(cornerRadius: CGFloat = 12.0, tintColor: Color? = nil, @ViewBuilder content: @escaping () -> some View) {
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.content = { AnyView(content()) }
    }
    
    func makeNSView(context: Context) -> NSGlassEffectView {
        let glassView = NSGlassEffectView()
        glassView.cornerRadius = cornerRadius
        glassView.tintColor = tintColor.map { NSColor($0) }
        
        // Create SwiftUI content view
        let hostingView = NSHostingView(rootView: content())
        glassView.contentView = hostingView
        
        return glassView
    }
    
    func updateNSView(_ nsView: NSGlassEffectView, context: Context) {
        nsView.cornerRadius = cornerRadius
        nsView.tintColor = tintColor.map { NSColor($0) }
        
        // Update content if needed
        if let hostingView = nsView.contentView as? NSHostingView<AnyView> {
            hostingView.rootView = content()
        }
    }
}

// SwiftUI wrapper for NSGlassEffectContainerView
struct GlassEffectContainerView: NSViewRepresentable {
    let spacing: CGFloat
    let content: () -> AnyView
    
    init(spacing: CGFloat = 20.0, @ViewBuilder content: @escaping () -> some View) {
        self.spacing = spacing
        self.content = { AnyView(content()) }
    }
    
    func makeNSView(context: Context) -> NSGlassEffectContainerView {
        let containerView = NSGlassEffectContainerView()
        containerView.spacing = spacing
        
        // Create SwiftUI content view
        let hostingView = NSHostingView(rootView: content())
        containerView.contentView = hostingView
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSGlassEffectContainerView, context: Context) {
        nsView.spacing = spacing
        
        // Update content if needed
        if let hostingView = nsView.contentView as? NSHostingView<AnyView> {
            hostingView.rootView = content()
        }
    }
}
