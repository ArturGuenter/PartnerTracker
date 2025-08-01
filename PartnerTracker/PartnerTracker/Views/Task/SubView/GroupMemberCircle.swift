//
//  GroupMemberCircle.swift
//  PartnerTracker
//
//  Created by Artur Günter on 21.07.25.
//

import SwiftUI

struct GroupMemberCircle: View {
    let memberId: String
    let completed: Bool
    @ObservedObject var groupViewModel: GroupViewModel

    @State private var showTooltip = false

    var body: some View {
        let user = groupViewModel.userCache[memberId]
        let initial = user?.name.first.map { String($0) } ?? "?"

        ZStack {
            Circle()
                .fill(completed ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(initial)
                        .font(.caption)
                        .foregroundColor(.white)
                )
                .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTooltip = pressing
                    }
                }, perform: {})

            if showTooltip {
                VStack(spacing: 4) {
                    Text(user?.name ?? "Unbekannt")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .zIndex(1)

                    Spacer().frame(height: 40)
                }
            }
        }
        .frame(height: 32 + 40)
    }
}




#Preview {
    GroupMemberCircle(memberId: "2", completed: true, groupViewModel: GroupViewModel())
}
