//
//  ContentView.swift
//  Memeification
//
//  Created by Eric Nguyen on 9/10/26.
//

import SwiftUI

enum AppTab: Hashable {
    case home, feed, profile, search
}

struct ContentView: View {
    @State private var selection: AppTab

    init(initialTab: AppTab = .home) {
        _selection = State(initialValue: initialTab)
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView()
            }
            Tab("Feed", systemImage: "play.rectangle.on.rectangle.fill", value: .feed) {
                FeedView()
            }
            Tab("Profile", systemImage: "person.crop.circle", value: .profile) {
                ProfileView()
            }
            // The search role pins this tab to the trailing edge and hosts the TabView's search field.
            Tab(value: .search, role: .search) {
                SearchView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(MemeStore.sample)
}

#Preview("On Search") {
    ContentView(initialTab: .search)
        .environment(MemeStore.sample)
}
