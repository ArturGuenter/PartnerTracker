//
//  PartnerTrackerWidgetBundle.swift
//  PartnerTrackerWidget
//
//  Created by Artur Günter on 03.10.25.
//

import WidgetKit
import SwiftUI

@main
struct PartnerTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PartnerTrackerWidget()
        PartnerTrackerWidgetControl()
        PartnerTrackerWidgetLiveActivity()
    }
}
