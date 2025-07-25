//
//  GroupAddView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 28.06.25.
//

import SwiftUI

struct GroupAddView: View {
    
    @ObservedObject var groupViewModel: GroupViewModel
    @Environment(\.dismiss) var dismiss

    @State private var groupCode: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Gruppe beitreten")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Gruppen-ID", text: $groupCode)
                .keyboardType(.asciiCapable)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )

            SecureField("4-stelliges Gruppenpasswort", text: $password)
                .keyboardType(.numberPad)
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
                    await joinGroup()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                } else {
                    Text("Beitreten")
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

    private func joinGroup() async {
        errorMessage = ""
        isLoading = true

        let code = groupCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !code.isEmpty else {
            errorMessage = "Bitte gib die Gruppen-ID ein."
            isLoading = false
            return
        }

        guard trimmedPassword.count == 4,
              CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: trimmedPassword)) else {
            errorMessage = "Das Passwort muss genau 4 Ziffern enthalten."
            isLoading = false
            return
        }

        do {
            try await groupViewModel.joinGroup(groupId: code, password: trimmedPassword)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    GroupAddView(groupViewModel: GroupViewModel())
}
