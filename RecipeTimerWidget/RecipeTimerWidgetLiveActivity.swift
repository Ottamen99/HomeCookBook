//
//  RecipeTimerWidgetLiveActivity.swift
//  RecipeTimerWidget
//
//  Created by Ottavio Buonomo on 11.02.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RecipeTimerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RecipeTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecipeTimerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RecipeTimerWidgetAttributes {
    fileprivate static var preview: RecipeTimerWidgetAttributes {
        RecipeTimerWidgetAttributes(name: "World")
    }
}

extension RecipeTimerWidgetAttributes.ContentState {
    fileprivate static var smiley: RecipeTimerWidgetAttributes.ContentState {
        RecipeTimerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RecipeTimerWidgetAttributes.ContentState {
         RecipeTimerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RecipeTimerWidgetAttributes.preview) {
   RecipeTimerWidgetLiveActivity()
} contentStates: {
    RecipeTimerWidgetAttributes.ContentState.smiley
    RecipeTimerWidgetAttributes.ContentState.starEyes
}
