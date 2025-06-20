//
//  HomeView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 19.06.25.
//

import SwiftUI

struct HomeView: View {
    
    @Binding var selection: Int
    
    var body: some View {
        Text("Home")
    }
}

#Preview {
    HomeView(selection: .constant(1))
}
