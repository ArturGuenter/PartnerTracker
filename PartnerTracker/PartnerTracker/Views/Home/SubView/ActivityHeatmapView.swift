//
//  ActivityHeatmapView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 06.08.25.
//

import SwiftUI

struct ActivityHeatmapView: View {
    let data: [Date: Int]
    let calendar = Calendar.current

    var body: some View {
        let today = calendar.startOfDay(for: Date())
        let last30Days = (0..<30).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.reversed()

        LazyVGrid(columns: Array(repeating: GridItem(.fixed(18), spacing: 4), count: 7), spacing: 4) {
            ForEach(last30Days, id: \.self) { day in
                let count = data[day] ?? 0
                Rectangle()
                    .fill(color(for: count))
                    .frame(width: 18, height: 18)
                    .cornerRadius(4)
                    .overlay(
                        Text(count > 0 ? "\(count)" : "")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                    )
            }
        }
        .padding()
    }

    func color(for count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.2)
        case 1: return Color.green.opacity(0.4)
        case 2: return Color.green.opacity(0.6)
        case 3...: return Color.green
        default: return Color.gray.opacity(0.2)
        }
    }
}

#Preview {
    ActivityHeatmapView(data: [Date() : 2])
}
