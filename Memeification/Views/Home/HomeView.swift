//
//  HomeView.swift
//  Memeification
//
//  Home tab: Instagram-style infinite feed. Followed accounts first,
//  then a "caught up" divider, then endless suggested memes.
//

import SwiftUI

struct HomeView: View {
    @Environment(MemeStore.self) private var store
    @State private var feed: HomeFeed

    init(feed: HomeFeed = HomeFeed()) {
        _feed = State(initialValue: feed)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    StoriesRow()
                        .padding(.vertical, 8)
                    Divider()

                    ForEach(feed.posts) { post in
                        if post.id == feed.firstSuggestedPostID {
                            CaughtUpDivider(hasFollowedPosts: post.id != feed.posts.first?.id)
                        }
                        HomePostView(post: post)
                            .task {
                                await feed.postDidAppear(post, store: store)
                            }
                    }

                    // Trailing loader; also kicks off the first page and covers short content.
                    ProgressView()
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                        .task(id: feed.posts.count) {
                            await feed.loadNextPage(from: store)
                        }
                }
            }
            .refreshable {
                await feed.refresh(from: store)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Text("Memeification")
                        .font(.title2.weight(.heavy))
                        .fixedSize()
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Activity", systemImage: "heart") {}
                    Button("Messages", systemImage: "paperplane") {}
                }
            }
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .memeActionHost()
    }
}

// MARK: - Stories

/// Horizontal avatar row of followed accounts, like Instagram stories.
private struct StoriesRow: View {
    @Environment(MemeStore.self) private var store

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                story(store.currentUser, title: "Your story")
                ForEach(store.followedAccounts) { account in
                    story(account, title: account.username)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private func story(_ user: UserProfile, title: String) -> some View {
        VStack(spacing: 4) {
            ProfileAvatar(emoji: user.avatarEmoji)
                .frame(width: 68, height: 68)
            Text(title)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 72)
        }
    }
}

// MARK: - Caught up

private struct CaughtUpDivider: View {
    /// `false` when the user follows nobody (or nobody has posted), so the copy shouldn't say "caught up".
    let hasFollowedPosts: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: hasFollowedPosts ? "checkmark.circle" : "person.2")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(
                    .linearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text(hasFollowedPosts ? "You're all caught up" : "Nothing from people you follow yet")
                .font(.headline)
            Text(hasFollowedPosts ? "You've seen all new memes from accounts you follow." : "Follow accounts to see their memes first.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Divider()
                .padding(.top, 16)
            Text("Suggested memes")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 28)
    }
}

// MARK: - Post

private struct HomePostView: View {
    let post: HomeFeed.Post
    @Environment(MemeStore.self) private var store
    @State private var showsLikeBurst = false

    private var meme: Meme { post.meme }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            media
            actionBar
            details
        }
        .padding(.bottom, 20)
    }

    private var header: some View {
        HStack(spacing: 10) {
            if let author = store.author(of: meme) {
                ProfileAvatar(emoji: author.avatarEmoji, ringWidth: 1.5)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text(author.username)
                        .font(.subheadline.weight(.semibold))
                    if post.source == .suggested {
                        Text("Suggested for you")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                if post.source == .suggested && author.id != store.currentUser.id {
                    Group {
                        if store.isFollowing(author) {
                            Button("Following") { store.toggleFollow(author) }
                                .buttonStyle(.glass)
                        } else {
                            Button("Follow") { store.toggleFollow(author) }
                                .buttonStyle(.glassProminent)
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    .controlSize(.small)
                }
            } else {
                Spacer(minLength: 0)
            }
            MemeActionMenuButton(meme: meme)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var media: some View {
        // Instagram clamps feed media between 4:5 portrait and 1.91:1 landscape.
        MemeThumbnail(meme: meme, aspectRatio: min(max(meme.aspectRatio, 0.8), 1.91), cornerRadius: 0)
            .overlay {
                Image(systemName: "heart.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)
                    .scaleEffect(showsLikeBurst ? 1 : 0.4)
                    .opacity(showsLikeBurst ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
            .onTapGesture(count: 2) {
                likeWithBurst()
            }
    }

    private var actionBar: some View {
        let isFavorite = store.isFavorite(meme)
        let isReposted = store.isReposted(meme)

        return HStack(spacing: 16) {
            Button(isFavorite ? "Unlike" : "Like", systemImage: isFavorite ? "heart.fill" : "heart") {
                store.toggleFavorite(meme)
            }
            .foregroundStyle(isFavorite ? .pink : .primary)
            .symbolEffect(.bounce, value: isFavorite)

            Button("Comment", systemImage: "bubble.right") {}

            Button(isReposted ? "Undo Repost" : "Repost", systemImage: "arrow.2.squarepath") {
                store.toggleRepost(meme)
            }
            .foregroundStyle(isReposted ? .green : .primary)

            ShareLink(
                item: MemeFile(meme: meme),
                preview: SharePreview(meme.title, image: Image(meme.imageName))
            ) {
                Label("Share", systemImage: "paperplane")
            }

            Spacer()

            if MemeActions.canSaveToPhotos {
                Button("Save to Photos", systemImage: "arrow.down.to.line") {
                    store.saveToPhotos(meme)
                }
            }
        }
        .labelStyle(.iconOnly)
        .font(.title3)
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var details: some View {
        let likes = meme.likes + (store.isFavorite(meme) ? 1 : 0)
        let username = store.author(of: meme)?.username ?? ""

        return VStack(alignment: .leading, spacing: 4) {
            Text("\(likes.formatted()) likes")
                .font(.subheadline.weight(.semibold))
            Text("\(Text(username).fontWeight(.semibold)) \(meme.title)")
                .font(.subheadline)
            Text(meme.tags.map { "#\($0)" }.joined(separator: " "))
                .font(.subheadline)
                .foregroundStyle(.tint)
            Text(meme.postedAt, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
    }

    /// Double-tap: like (never unlike, matching Instagram) and play the heart burst.
    private func likeWithBurst() {
        if !store.isFavorite(meme) {
            store.toggleFavorite(meme)
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showsLikeBurst = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.easeOut(duration: 0.25)) {
                showsLikeBurst = false
            }
        }
    }
}

#Preview("Home") {
    let store = MemeStore.sample
    return HomeView(feed: .preloaded(pages: 3, from: store))
        .environment(store)
}

#Preview("Home – Caught Up Divider") {
    // No followed posts, so the divider and suggestions (with Follow buttons) appear at the top.
    let store = MemeStore.sample
    store.currentUser.followingIDs = []
    return HomeView(feed: .preloaded(pages: 2, from: store))
        .environment(store)
}
