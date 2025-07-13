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

    let tabItems = [
        (title: "Dashboard", icon: "square.grid.2x2"),
        (title: "Goals", icon: "target"),
        (title: "Analytics", icon: "chart.bar.fill")
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom glassy capsule tab bar
                HStack(spacing: 0) {
                    ForEach(0..<tabItems.count, id: \.self) { idx in
                        Button(action: { selectedTab = idx }) {
                            HStack(spacing: 8) {
                                Image(systemName: tabItems[idx].icon)
                                Text(tabItems[idx].title)
                            }
                            .font(.headline)
                            .foregroundColor(selectedTab == idx ? .white : .primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Group {
                                    if selectedTab == idx {
                                        BlurView(style: .hudWindow)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 12)
                .background(
                    BlurView(style: .hudWindow)
                        .clipShape(Capsule())
                        .opacity(0.7)
                )
                .padding(.horizontal, 32)

                // Main content
                GlassEffectContainerView(spacing: 16) {
                    VStack(spacing: 0) {
                        Group {
                            if selectedTab == 0 {
                                DashboardView()
                            } else if selectedTab == 1 {
                                GoalsListView()
                            } else if selectedTab == 2 {
                                AnalyticsView()
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingCreateGoal) {
            CreateGoalView()
                .environmentObject(goalManager)
        }
    }
}
