//
//  LoginView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.06.25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var loginRegisterViewModel: LoginRegisterViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var navigateToMain = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Login")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .center)

                TextField("E-Mail", text: $email)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))

                SecureField("Passwort", text: $password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))

                Button(action: {
                    loginRegisterViewModel.login(email: email, password: password)
                }) {
                    Text("Einloggen")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }

                NavigationLink(destination: RegisterView(loginRegisterViewModel: loginRegisterViewModel)) {
                    Text("Registrieren")
                        .font(.callout)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationDestination(isPresented: $navigateToMain) {
                GroupView()
            }
            .onChange(of: loginRegisterViewModel.isLoggedIn) { isLoggedIn, oldvalue in
                if isLoggedIn {
                    navigateToMain = true
                }
            }
        }
    }
}



#Preview {
    LoginView(loginRegisterViewModel: LoginRegisterViewModel())
}
