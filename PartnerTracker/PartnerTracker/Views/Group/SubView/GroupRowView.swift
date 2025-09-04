//
//  GroupRowView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 04.09.25.
//

import SwiftUI

struct GroupRowView: View {
    let group: Group
    let showCopyButton: Bool
    let onCopy: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(group.name)
                    .font(.headline)

                if let createdAt = group.createdAt {
                    Text("Erstellt am \(createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Text("Mitgliederanzahl: \(group.memberIds.count)")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("ID: \(group.id)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.vertical, 6)

            Spacer()

            if showCopyButton, let onCopy = onCopy {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}

/*
#Preview {
    GroupRowView()
}
*/
