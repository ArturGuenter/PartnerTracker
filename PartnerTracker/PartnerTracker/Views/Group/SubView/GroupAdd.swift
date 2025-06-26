//
//  GroupAdd.swift
//  PartnerTracker
//
//  Created by Artur Günter on 24.06.25.
//

import SwiftUI

struct GroupAdd: View {
    @ObservedObject var groupViewModel: GroupViewModel
        @State private var groupName: String = ""
        @State private var errorMessage: String = ""
        @Environment(\.dismiss) var dismiss
        @State private var isLoading = false
    @State private var password: String = ""


        var body: some View {
            VStack(spacing: 24) {
                Text("Neue Gruppe erstellen")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Gruppenname", text: $groupName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
                SecureField("Passwort 4 Ziffern z.B. 1234", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )


                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button {
                    Task {
                        await createGroup()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(12)
                    } else {
                        Text("Gruppe erstellen")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .disabled(isLoading)

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }

    private func createGroup() async {
        errorMessage = ""
        isLoading = true

        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "Gruppenname darf nicht leer sein."
            isLoading = false
            return
        }

        // Passwort: Muss genau 4 Ziffern sein
        let passwordPattern = #"^\d{4}$"#
        if trimmedPassword.range(of: passwordPattern, options: .regularExpression) == nil {
            errorMessage = "Das Passwort muss aus genau 4 Ziffern bestehen."
            isLoading = false
            return
        }

        do {
            try await groupViewModel.createGroup(name: trimmedName, password: trimmedPassword)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    }

#Preview {
    GroupAdd(groupViewModel: GroupViewModel())
}
