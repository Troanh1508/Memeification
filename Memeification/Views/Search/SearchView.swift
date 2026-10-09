//
//  SearchView.swift
//  Memeification
//
//  Search tab: uniform grid with category chips and search.
//

import SwiftUI

struct SearchView: View {
    @Environment(MemeStore.self) private var store
    @State private var selectedMeme: Meme?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 4)]

    private var searchFieldPlacement: SearchFieldPlacement {
        #if os(macOS)
        .automatic
        #else
        .navigationBarDrawer(displayMode: .always)
        #endif
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ScrollView {
                MemeCategoryChips()
                    .padding(.vertical, 8)

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(store.filtered) { meme in
                        Button {
                            selectedMeme = meme
                        } label: {
                            MemeThumbnail(meme: meme, cornerRadius: 4)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            MemeActionMenuItems(meme: meme)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .overlay {
                if store.filtered.isEmpty {
                    ContentUnavailableView.search(text: store.searchText)
                }
            }
            .navigationTitle("Search")
            // Always-visible field under the title: shown as soon as the tab opens,
            // but only focused (keyboard up) when the user taps it.
            .searchable(
                text: $store.searchText,
                placement: searchFieldPlacement,
                prompt: "Search memes, tags…"
            )
            .sheet(item: $selectedMeme) { meme in
                MemeDetailView(meme: meme)
            }
        }
        .memeActionHost()
    }
}

#Preview("Search") {
    // Shown inside the app's TabView, which owns the search field.
    ContentView(initialTab: .search)
        .environment(MemeStore.sample)
}
