//
//  RegisterView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.06.25.
//

import SwiftUI

struct RegisterView: View {
    
    @ObservedObject var loginRegisterViewModel: LoginRegisterViewModel
    @State private var name = ""
    @State private var surname = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 24) {
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
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.top, -12)
            }
            
            Button(action: {
                guard password.count >= 8 else {
                    errorMessage = "Das Passwort muss mindestens 8 Zeichen lang sein."
                    return
                }
                
                guard password == confirmPassword else {
                    errorMessage = "Die Passwörter stimmen nicht überein."
                    return
                }
                
                errorMessage = ""
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


#Preview {
    RegisterView(loginRegisterViewModel: LoginRegisterViewModel())
}
