//
//  MemeDetailView.swift
//  Memeification
//

import SwiftUI

/// Full-size meme with metadata and a glass action bar. Shared by every layout.
struct MemeDetailView: View {
    let meme: Meme
    @Environment(MemeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    MemeThumbnail(meme: meme, aspectRatio: nil, cornerRadius: 20)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(meme.title)
                            .font(.title2.bold())
                        HStack(spacing: 12) {
                            Label(meme.category.rawValue, systemImage: meme.category.systemImage)
                            Label(meme.likes.formatted(.number.notation(.compactName)), systemImage: "heart.fill")
                            Label(meme.kind.label, systemImage: meme.kind.systemImage)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        Text(meme.tags.map { "#\($0)" }.joined(separator: " "))
                            .font(.subheadline)
                            .foregroundStyle(.tint)
                    }

                    actionBar
                }
                .padding()
            }
            .navigationTitle("Meme")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .memeActionHost()
    }

    private var actionBar: some View {
        GlassEffectContainer {
            HStack(spacing: 12) {
                ShareLink(
                    item: MemeFile(meme: meme),
                    preview: SharePreview(meme.title, image: Image(meme.imageName))
                ) {
                    actionLabel("Share", systemImage: "square.and.arrow.up")
                }
                Button { store.copy(meme) } label: {
                    actionLabel("Copy", systemImage: "doc.on.doc")
                }
                if MemeActions.canSaveToPhotos {
                    Button { store.saveToPhotos(meme) } label: {
                        actionLabel("Save", systemImage: "arrow.down.to.line")
                    }
                }
                Button { store.export(meme) } label: {
                    actionLabel("Export", systemImage: "square.and.arrow.up.on.square")
                }
                Button { store.toggleFavorite(meme) } label: {
                    actionLabel("Like", systemImage: store.isFavorite(meme) ? "heart.fill" : "heart")
                }
            }
            .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionLabel(_ title: String, systemImage: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title3)
            Text(title)
                .font(.caption2)
        }
        .frame(minWidth: 44)
    }
}

#Preview {
    MemeDetailView(meme: Meme.samples[1])
        .environment(MemeStore.sample)
}
