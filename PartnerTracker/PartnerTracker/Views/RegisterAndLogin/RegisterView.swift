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
    @State private var passwordStrength: Int = 0

    
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
                    .onChange(of: password) { newValue, oldValue in
                        passwordStrength = analyzePassword(newValue)
                    }
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
    
    func analyzePassword(_ password: String) -> Int {
        var strength = 0
        let uppercase = NSPredicate(format: "SELF MATCHES %@", ".*[A-Z]+.*")
        let number = NSPredicate(format: "SELF MATCHES %@", ".*[0-9]+.*")
        let special = NSPredicate(format: "SELF MATCHES %@", ".*[!&^%$#@()/]+.*")

        if password.count >= 8 { strength += 1 }
        if uppercase.evaluate(with: password) { strength += 1 }
        if number.evaluate(with: password) { strength += 1 }
        if special.evaluate(with: password) { strength += 1 }

        return strength
    }
    
    
}




#Preview {
    RegisterView(loginRegisterViewModel: LoginRegisterViewModel())
}


#Preview {
    RegisterView(loginRegisterViewModel: LoginRegisterViewModel())
}
