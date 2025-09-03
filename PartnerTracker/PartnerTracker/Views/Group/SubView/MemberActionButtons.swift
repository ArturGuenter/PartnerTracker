//
//  MemberActionButtons.swift
//  PartnerTracker
//
//  Created by Artur Günter on 03.09.25.
//

import SwiftUI

struct MemberActionButtons: View {
    let member: AppUser
    let onPromote: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPromote) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Button(action: onRemove) {
                Image(systemName: "person.fill.xmark")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

#Preview {
    MemberActionButtons(
        member: AppUser(id: "1", surname: "Mustermann", name: "Max", email: "max@example.com"),
        onPromote: {
            print("Promote gedrückt")
        },
        onRemove: {
            print("Remove gedrückt")
        }
    )
}

