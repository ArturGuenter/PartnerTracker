//
//  RegisterView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.06.25.
//

import SwiftUI

struct RegisterView: View {
    
    @ObservedObject var loginRegisterViewModel: LoginRegisterViewModel
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    @State private var name = ""
    @State private var surname = ""
    @State private var email = ""
    @State private var password = ""
    
    
    var body: some View {VStack(spacing: 24) {
        Text("Registrieren")
            .font(.largeTitle.bold())
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        
        Group {
            TextField("Vorname", text: $name)
            TextField("Nachname", text: $surname)
            TextField("E-Mail", text: $email)
            SecureField("Passwort", text: $password)
            SecureField("Passwort bestätigen", text: $confirmPassword)

        }
        .textFieldStyle(PlainTextFieldStyle())
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.4), lineWidth:1)
        )
        
        Button(action: {
            loginRegisterViewModel.register(email: email, password: password, name: name, surname: surname)
        }) {
            Text("Registrieren")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
        
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    RegisterView(loginRegisterViewModel: LoginRegisterViewModel())
}
