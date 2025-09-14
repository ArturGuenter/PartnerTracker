//
//  ContentView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 13.06.25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var loginRegisterViewModel: LoginRegisterViewModel
    @StateObject private var groupViewModel = GroupViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var selection = 1

    var body: some View {
        TabView(selection: $selection) {
            HomeView(selection: $selection, loginRegisterViewModel: loginRegisterViewModel, taskViewModel: taskViewModel, groupViewModel: groupViewModel)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(1)

            TaskView(taskViewModel: taskViewModel, groupViewModel: groupViewModel)
                .tabItem {
                    Label("Aufgaben", systemImage: "list.bullet")
                }
                .tag(2)

            GroupView(groupViewModel: groupViewModel, taskViewModel: taskViewModel)
                .tabItem {
                    Label("Gruppe", systemImage: "person.3.fill")
                }
                .tag(3)
        }
        .onAppear{
            taskViewModel.notificationViewModel = notificationViewModel
        }
    }
}


#Preview {
    ContentView(loginRegisterViewModel: LoginRegisterViewModel())
}
