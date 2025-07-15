//
//  CircularProgressBar.swift
//  PartnerTracker
//
//  Created by Artur Günter on 15.07.25.
//

import SwiftUI

struct CircularProgressBar: View {
    var progress: Double
    var title: String
    var completed: Int
    var total: Int

    var progressColor: Color {
        switch progress {
        case 0..<0.33: return .red
        case 0.33..<0.66: return .orange
        default: return .green
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 20)

            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            VStack {
                Text("\(completed)/\(total)")
                    .font(.title2)
                    .bold()
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 150, height: 150)
    }
}


#Preview {
    CircularProgressBar(progress: 1.0, title: "Alle", completed: 1, total: 3)
}
