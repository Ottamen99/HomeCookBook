//
//  RecipeTimerWidgetBundle.swift
//  RecipeTimerWidget
//
//  Created by Ottavio Buonomo on 11.02.2025.
//

import WidgetKit
import SwiftUI

@main
struct RecipeTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            TimerLiveActivity()
        }
    }
}
