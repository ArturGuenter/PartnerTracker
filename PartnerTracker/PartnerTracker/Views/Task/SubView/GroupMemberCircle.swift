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

    @State private var showPopover = false

    var body: some View {
        let user = groupViewModel.userCache[memberId]
        let initial = user?.name.first.map { String($0) } ?? "?"

        Circle()
            .fill(completed ? Color.green : Color.gray.opacity(0.4))
            .frame(width: 32, height: 32)
            .overlay(
                Text(initial)
                    .font(.caption)
                    .foregroundColor(.white)
            )
            .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
                withAnimation {
                    showPopover = pressing
                }
            }, perform: {})
            .popover(isPresented: $showPopover) {
                Text(user?.name ?? "Unbekannt")
                    .padding()
                    .frame(width: 150)
            }
    }
}



#Preview {
    GroupMemberCircle(memberId: "2", completed: true, groupViewModel: GroupViewModel())
}
