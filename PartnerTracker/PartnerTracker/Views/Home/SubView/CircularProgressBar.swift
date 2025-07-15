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
    var size: CGFloat = 150
    
    var progressColor: Color {
            switch progress {
            case 0..<0.33: return .red
            case 0.33..<0.66: return .orange
            default: return .green
            }
        }

        var body: some View {
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut, value: progress)

                    VStack {
                        Text("\(completed)/\(total)")
                            .font(.title2)
                            .bold()
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: size, height: size)
            }
        }
    }


#Preview {
    CircularProgressBar(progress: 1.0, title: "Alle", completed: 1, total: 3)
}
