//
//  GroupDetailView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 30.06.25.
//

import SwiftUI
import FirebaseFirestore

struct GroupDetailView: View {
    let group: Group
    @State private var members: [AppUser] = []
    @State private var isLoading = true
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Lade Mitglieder …")
                    .padding()
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if members.isEmpty {
                Text("Keine Mitglieder gefunden.")
                    .foregroundColor(.gray)
            } else {
                List(members) { member in
                    VStack(alignment: .leading) {
                        Text("\(member.name) \(member.surname)")
                            .font(.headline)
                        Text(member.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .onAppear {
            loadMembers()
        }
    }

    private func loadMembers() {
        let db = Firestore.firestore()
        let memberIds = group.memberIds

        guard !memberIds.isEmpty else {
            self.isLoading = false
            return
        }

        var fetchedUsers: [AppUser] = []

        let group = DispatchGroup()

        for id in memberIds {
            group.enter()
            db.collection("users").document(id).getDocument { snapshot, error in
                defer { group.leave() }

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                if let user = try? snapshot?.data(as: AppUser.self) {
                    fetchedUsers.append(user)
                }
            }
        }

        group.notify(queue: .main) {
            self.members = fetchedUsers.sorted { $0.name < $1.name }
            self.isLoading = false
        }
    }
}


#Preview {
    GroupDetailView(group: Group(name: "sdf", memberIds: ["sadfff"], password: "fsffff"))
}
