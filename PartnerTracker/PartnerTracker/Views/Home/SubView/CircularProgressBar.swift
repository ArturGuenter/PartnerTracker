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
    var size: CGFloat
    var progressColor: Color = .blue

    var body: some View {
        ZStack {
            
            Circle()
                .stroke(lineWidth: 15)
                .foregroundColor(progressColor.opacity(0.2))

            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .foregroundColor(progressColor)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeOut, value: progress)

            VStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("\(completed)/\(total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}




#Preview {
    CircularProgressBar(progress: 1.0, title: "Alle", completed: 1, total: 3, size: 2.7)
}
