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
            Spacer()
            Text("Registrieren")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            
                TextField("Vorname", text: $name)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
            
                TextField("Nachname", text: $surname)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
            
                TextField("E-Mail", text: $email)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
            
                SecureField("Passwort", text: $password)
                    .onChange(of: password) { newValue, oldValue in
                        passwordStrength = analyzePassword(newValue)
                        if password.isEmpty {
                            passwordStrength = 0
                        }
                    }
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
            
                  
                SecureField("Passwort bestätigen", text: $confirmPassword)
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
            
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .frame(height: 6)
                            .foregroundColor(Color.gray.opacity(0.3))
                        
                        Capsule()
                            .frame(
                                width: geometry.size.width * CGFloat(passwordStrength) / 4,
                                height: 6
                            )
                            .foregroundColor(passwordStrengthColor())
                            .animation(.easeInOut(duration: 0.2), value: passwordStrength)
                    }
                }
                .frame(height: 6) // ← Höhe fixieren

                Text(passwordStrengthDescription())
                    .font(.caption)
                    .foregroundColor(passwordStrengthColor())
            }


            
            Button(action: {
                let currentStrength = analyzePassword(password) // Direkt prüfen
                
                guard currentStrength >= 3 else {
                    errorMessage = "Das Passwort ist nicht sicher genug."
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
    
    func passwordStrengthColor() -> Color {
        switch passwordStrength {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .green
        }
    }

    func passwordStrengthDescription() -> String {
        switch passwordStrength {
        case 0...1: return "Schwach"
        case 2: return "Mittel"
        case 3: return "Gut"
        default: return "Stark"
        }
    }

    
}




#Preview {
    RegisterView(loginRegisterViewModel: LoginRegisterViewModel())
}



