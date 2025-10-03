//
//  PartnerTrackerWidgetLiveActivity.swift
//  PartnerTrackerWidget
//
//  Created by Artur Günter on 03.10.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PartnerTrackerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct PartnerTrackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PartnerTrackerWidgetAttributes.self) { context in
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

extension PartnerTrackerWidgetAttributes {
    fileprivate static var preview: PartnerTrackerWidgetAttributes {
        PartnerTrackerWidgetAttributes(name: "World")
    }
}

extension PartnerTrackerWidgetAttributes.ContentState {
    fileprivate static var smiley: PartnerTrackerWidgetAttributes.ContentState {
        PartnerTrackerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: PartnerTrackerWidgetAttributes.ContentState {
         PartnerTrackerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: PartnerTrackerWidgetAttributes.preview) {
   PartnerTrackerWidgetLiveActivity()
} contentStates: {
    PartnerTrackerWidgetAttributes.ContentState.smiley
    PartnerTrackerWidgetAttributes.ContentState.starEyes
}
