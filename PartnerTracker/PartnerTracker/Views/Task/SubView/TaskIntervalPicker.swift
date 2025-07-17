//
//  TaskIntervalPicker.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.07.25.
//

import SwiftUI

struct TaskIntervalPicker: View {
    @Binding var selectedInterval: TaskResetInterval

    var body: some View {
        Picker("Wiederholen", selection: $selectedInterval) {
            ForEach(TaskResetInterval.allCases) { interval in
                Text(interval.rawValue.capitalized).tag(interval)
            }
        }
        .pickerStyle(.segmented)
    }
}


#Preview {
    TaskIntervalPicker()
}
