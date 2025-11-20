//
//  CafeWidgets.swift
//  CafeWidgets
//
//  Widget bundle and main entry point
//

import WidgetKit
import SwiftUI

@main
struct CafeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodaysTasksWidget()
        CalendarWidget()
        QuickAddWidget()
        TaskCountWidget()
        NextEventWidget()
        CompletedTodayWidget()
    }
}
