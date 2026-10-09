//
//  MemeThumbnail.swift
//  Memeification
//

import SwiftUI

/// Displays a meme image cropped to a given aspect ratio, with an optional kind badge.
/// GIFs get a gentle looping zoom animation so motion is visible in placeholders.
struct MemeThumbnail: View {
    let meme: Meme
    /// `nil` uses the meme's natural aspect ratio.
    var aspectRatio: CGFloat? = 1
    var cornerRadius: CGFloat = 12
    var showsBadge = true

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio ?? meme.aspectRatio, contentMode: .fit)
            .overlay {
                artwork
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay(alignment: .topTrailing) {
                if showsBadge && meme.kind != .image {
                    MemeKindBadge(kind: meme.kind)
                        .padding(6)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(meme.title)
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private var artwork: some View {
        let image = Image(meme.imageName)
            .resizable()
            .scaledToFill()

        if meme.kind == .gif {
            image.phaseAnimator([false, true]) { content, phase in
                content
                    .scaleEffect(phase ? 1.08 : 1)
            } animation: { _ in
                .easeInOut(duration: 1.2)
            }
        } else {
            image
        }
    }
}

/// Small capsule showing "GIF" or a play glyph for videos.
struct MemeKindBadge: View {
    let kind: MemeKind

    var body: some View {
        Group {
            if kind == .video {
                Image(systemName: kind.systemImage)
            } else {
                Text(kind.label)
            }
        }
        .font(.caption2.weight(.heavy))
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.black.opacity(0.55), in: .capsule)
    }
}

#Preview {
    HStack {
        ForEach(Meme.samples.prefix(4)) { meme in
            MemeThumbnail(meme: meme)
        }
    }
    .padding()
}
