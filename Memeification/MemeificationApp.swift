//
//  MemeificationApp.swift
//  Memeification
//
//  Created by Trung Anh on 9/10/26.
//

import SwiftUI

@main
struct MemeificationApp: App {
    @State private var store = MemeStore.sample

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
