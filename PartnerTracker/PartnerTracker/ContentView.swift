//
//  ContentView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 13.06.25.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var loginRegisterViewModel: LoginRegisterViewModel
    @Binding  var selection : Int
    
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
    ContentView(loginRegisterViewModel: LoginRegisterViewModel(), selection: .constant(1))
}
