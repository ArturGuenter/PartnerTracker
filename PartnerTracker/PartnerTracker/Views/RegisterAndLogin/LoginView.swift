//
//  LoginView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.06.25.
//

import SwiftUI

struct LoginView: View {
    
    @ObservedObject var loginRegisterViewModel: LoginRegisterViewModel
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    LoginView(loginRegisterViewModel: LoginRegisterViewModel())
}
