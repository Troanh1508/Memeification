//
//  HomeFeed.swift
//  Memeification
//

import Foundation
import Observation

/// Paginated, infinitely scrolling Home feed.
///
/// Ordering: every meme from followed accounts first (newest first), then an endless stream
/// of discovery posts. Discovery is random for now; swap `nextDiscoveryPage` for a
/// recommendation service later without touching the view.
@Observable
final class HomeFeed {
    enum Source {
        case following
        case suggested
    }

    /// A single row in the feed. Has its own identity because discovery can repeat memes.
    struct Post: Identifiable {
        let id = UUID()
        let meme: Meme
        let source: Source
    }

    private(set) var posts: [Post] = []
    private(set) var isLoading = false

    private let pageSize: Int
    private let latency: Duration
    private var followingCursor = 0

    /// - Parameters:
    ///   - pageSize: Posts appended per page.
    ///   - latency: Simulated network delay per page.
    init(pageSize: Int = 4, latency: Duration = .milliseconds(600)) {
        self.pageSize = pageSize
        self.latency = latency
    }

    /// The first discovery post, where the "You're all caught up" divider goes.
    var firstSuggestedPostID: Post.ID? {
        posts.first { $0.source == .suggested }?.id
    }

    /// Call when a post appears; loads more once the user nears the end.
    func postDidAppear(_ post: Post, store: MemeStore) async {
        let threshold = posts.suffix(2).map(\.id)
        guard threshold.contains(post.id) else { return }
        await loadNextPage(from: store)
    }

    func loadNextPage(from store: MemeStore) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(for: latency)
        appendNextPage(from: store)
    }

    /// Appends one page immediately: followed memes until exhausted, then discovery.
    func appendNextPage(from store: MemeStore) {
        let following = store.followingFeed
        if followingCursor < following.count {
            let page = following[followingCursor..<min(followingCursor + pageSize, following.count)]
            followingCursor += page.count
            posts.append(contentsOf: page.map { Post(meme: $0, source: .following) })
        } else {
            posts.append(contentsOf: nextDiscoveryPage(from: store.discoverPool).map {
                Post(meme: $0, source: .suggested)
            })
        }
    }

    /// A feed with pages already loaded, so previews render content without waiting.
    static func preloaded(pages: Int, from store: MemeStore) -> HomeFeed {
        let feed = HomeFeed()
        for _ in 0..<pages {
            feed.appendNextPage(from: store)
        }
        return feed
    }

    /// Pull-to-refresh: start over so newly followed accounts show up first.
    func refresh(from store: MemeStore) async {
        posts = []
        followingCursor = 0
        await loadNextPage(from: store)
    }

    /// Random discovery placeholder until recommendations exist.
    /// Avoids showing the same meme twice in a row across page boundaries.
    private func nextDiscoveryPage(from pool: [Meme]) -> [Meme] {
        var page: [Meme] = []
        var previousID = posts.last?.meme.id
        while page.count < pageSize {
            guard let next = pool.filter({ $0.id != previousID }).randomElement() ?? pool.first else { break }
            page.append(next)
            previousID = next.id
        }
        return page
    }
}
