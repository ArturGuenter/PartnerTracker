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
    MemberActionButtons()
}
