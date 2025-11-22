//
//  CafeWidgets.swift
//  CafeWidgets
//
//  Widget bundle and main entry point for all Cafe widgets
//

import WidgetKit
import SwiftUI

@main
struct CafeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        TodaysTasksWidget()
        CalendarWidget()
        QuickAddWidget()

        // Lock Screen Widgets (iOS 16+)
        TaskCountWidget()
        TaskProgressWidget()
        NextEventWidget()
        CompletedTodayWidget()
    }
}
