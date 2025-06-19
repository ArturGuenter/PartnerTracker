//
//  ContentView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 13.06.25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var loginRegisterViewModel = LoginRegisterViewModel()
    @State private var selection = 1
    
    var body: some View {
        
        TabView(selection: $selection){
            HomeView(selection: $selection)
            .tabItem{
                        Label("Home", systemImage: "house")
                            }
            .tag(1)
            
            TaskView()
                            .tabItem {
                                Label("Tasks", systemImage: "list.bullet")
                            }
                            .tag(2)
                    
                    FamilyView()
                            .tabItem {
                                Image(systemName: "person.3.fill")
                                Text("Familie")
                            }
                            .tag(3)
            
        }
        
        
        
            
            
        
    }
}

#Preview {
    ContentView()
}
