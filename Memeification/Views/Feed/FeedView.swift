//
//  FeedView.swift
//  Memeification
//
//  Feed tab: TikTok-style full-screen vertical feed with a glass action rail.
//

import SwiftUI

struct FeedView: View {
    @Environment(MemeStore.self) private var store

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                // Unfiltered on purpose: search state belongs to the Search tab.
                ForEach(store.memes) { meme in
                    FeedPage(meme: meme)
                        .containerRelativeFrame([.horizontal, .vertical])
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
        .background(.black)
        .overlay(alignment: .topLeading) {
            Text("Feed")
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)
                .shadow(radius: 4)
                .padding(.horizontal)
        }
        .memeActionHost()
    }
}

private struct FeedPage: View {
    let meme: Meme
    @Environment(MemeStore.self) private var store

    var body: some View {
        MemeThumbnail(meme: meme, aspectRatio: nil, cornerRadius: 0, showsBadge: false)
            .padding(.vertical, 140)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                // Blurred backdrop fills the page without influencing its size.
                Image(meme.imageName)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 40)
                    .opacity(0.6)
            }
            .clipped()
            .overlay(alignment: .bottomLeading) {
                caption
            }
            .overlay(alignment: .bottomTrailing) {
                actionRail
            }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let author = store.author(of: meme) {
                HStack(spacing: 8) {
                    ProfileAvatar(emoji: author.avatarEmoji, ringWidth: 1.5)
                        .frame(width: 32, height: 32)
                    Text(author.username)
                        .font(.subheadline.weight(.bold))
                }
            }
            Label(meme.kind.label, systemImage: meme.kind.systemImage)
                .font(.caption.weight(.bold))
            Text(meme.title)
                .font(.title3.bold())
            Text(meme.tags.map { "#\($0)" }.joined(separator: " "))
                .font(.subheadline)
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .shadow(radius: 4)
        .padding(.leading)
        .padding(.trailing, 90)
        .padding(.bottom, 48)
    }

    private var actionRail: some View {
        let isFavorite = store.isFavorite(meme)
        return GlassEffectContainer(spacing: 16) {
            VStack(spacing: 16) {
                railButton(
                    isFavorite ? "heart.fill" : "heart",
                    title: (meme.likes + (isFavorite ? 1 : 0)).formatted(.number.notation(.compactName)),
                    tint: isFavorite ? .pink : nil
                ) {
                    store.toggleFavorite(meme)
                }
                ShareLink(
                    item: MemeFile(meme: meme),
                    preview: SharePreview(meme.title, image: Image(meme.imageName))
                ) {
                    railLabel("arrowshape.turn.up.right.fill", title: "Share")
                }
                .buttonStyle(.plain)
                railButton("doc.on.doc.fill", title: "Copy") {
                    store.copy(meme)
                }
                if MemeActions.canSaveToPhotos {
                    railButton("arrow.down.circle.fill", title: "Save") {
                        store.saveToPhotos(meme)
                    }
                }
                Menu {
                    MemeActionMenuItems(meme: meme)
                } label: {
                    railLabel("ellipsis", title: "More")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.trailing, 12)
        .padding(.bottom, 48)
    }

    private func railButton(_ systemImage: String, title: String, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            railLabel(systemImage, title: title, tint: tint)
        }
        .buttonStyle(.plain)
    }

    private func railLabel(_ systemImage: String, title: String, tint: Color? = nil) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint ?? .white)
                .frame(width: 52, height: 52)
                .glassEffect(.clear.interactive(), in: .circle)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(radius: 2)
        }
    }
}

#Preview("Feed") {
    FeedView()
        .environment(MemeStore.sample)
}
