//
//  MemeActionViews.swift
//  Memeification
//

import SwiftUI
import UniformTypeIdentifiers

/// Share / copy / save / export / favorite items, usable inside `Menu` or `contextMenu`.
struct MemeActionMenuItems: View {
    let meme: Meme
    @Environment(MemeStore.self) private var store

    var body: some View {
        ShareLink(
            item: MemeFile(meme: meme),
            preview: SharePreview(meme.title, image: Image(meme.imageName))
        ) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        Button("Copy", systemImage: "doc.on.doc") {
            store.copy(meme)
        }
        if MemeActions.canSaveToPhotos {
            Button("Save to Photos", systemImage: "arrow.down.to.line") {
                store.saveToPhotos(meme)
            }
        }
        Button("Export…", systemImage: "square.and.arrow.up.on.square") {
            store.export(meme)
        }
        Divider()
        let isFavorite = store.isFavorite(meme)
        Button(
            isFavorite ? "Remove Favorite" : "Favorite",
            systemImage: isFavorite ? "heart.slash" : "heart"
        ) {
            store.toggleFavorite(meme)
        }
    }
}

/// A "•••" button that opens the action menu.
struct MemeActionMenuButton: View {
    let meme: Meme

    var body: some View {
        Menu {
            MemeActionMenuItems(meme: meme)
        } label: {
            Label("Actions", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
        }
    }
}

/// Hosts the file exporter and toast used by meme actions. Apply once near the root of a layout.
struct MemeActionHost: ViewModifier {
    @Environment(MemeStore.self) private var store

    func body(content: Content) -> some View {
        content
            .fileExporter(
                isPresented: Binding(
                    get: { store.exportRequest != nil },
                    set: { if !$0 { store.exportRequest = nil } }
                ),
                item: store.exportRequest.map(MemeFile.init),
                contentTypes: [.png],
                defaultFilename: store.exportRequest?.title
            ) { result in
                if case .success = result {
                    store.toastMessage = "Exported"
                }
            }
            .overlay(alignment: .bottom) {
                if let message = store.toastMessage {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect()
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring, value: store.toastMessage)
            .task(id: store.toastMessage) {
                guard store.toastMessage != nil else { return }
                try? await Task.sleep(for: .seconds(1.6))
                store.toastMessage = nil
            }
    }
}

extension View {
    func memeActionHost() -> some View {
        modifier(MemeActionHost())
    }
}

/// Horizontally scrolling "All + categories" filter chips bound to the store.
struct MemeCategoryChips: View {
    @Environment(MemeStore.self) private var store

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(title: "All", systemImage: "square.grid.2x2", category: nil)
                ForEach(MemeCategory.allCases) { category in
                    chip(title: category.rawValue, systemImage: category.systemImage, category: category)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(title: String, systemImage: String, category: MemeCategory?) -> some View {
        let isSelected = store.selectedCategory == category
        return Button {
            store.selectedCategory = category
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.glass(isSelected ? .regular.tint(.accentColor) : .regular))
    }
}
