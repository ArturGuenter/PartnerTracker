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

    var body: some View {
        let user = groupViewModel.userCache[memberId]
        let initial = user.map { String($0.name.prefix(1)).uppercased() } ?? "?"

        return Text(initial)
            .font(.caption)
            .frame(width: 28, height: 28)
            .background(completed ? Color.green : Color.gray.opacity(0.2))
            .foregroundColor(completed ? .white : .primary)
            .clipShape(Circle())
    }
}


#Preview {
    GroupMemberCircle(memberId: "2", completed: true, groupViewModel: GroupViewModel())
}
