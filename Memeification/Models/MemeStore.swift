//
//  MemeStore.swift
//  Memeification
//

import Foundation
import Observation

/// Holds the meme collection, accounts, the signed-in user, and shared browse state.
@Observable
final class MemeStore {
    var memes: [Meme]
    var accounts: [UserProfile]
    var currentUser: UserProfile
    var searchText = ""
    /// `nil` means "All".
    var selectedCategory: MemeCategory?

    init(memes: [Meme], accounts: [UserProfile], currentUser: UserProfile) {
        self.memes = memes
        self.accounts = accounts
        self.currentUser = currentUser
    }

    /// Resolves meme IDs (e.g. a profile's reposts) to memes, preserving the given order.
    func memes(withIDs ids: [Meme.ID]) -> [Meme] {
        ids.compactMap { id in memes.first { $0.id == id } }
    }

    /// Memes matching the current search text and category filter.
    var filtered: [Meme] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return memes.filter { meme in
            let matchesCategory = selectedCategory == nil || meme.category == selectedCategory
            let matchesQuery = query.isEmpty
                || meme.title.localizedStandardContains(query)
                || meme.tags.contains { $0.localizedStandardContains(query) }
            return matchesCategory && matchesQuery
        }
    }

    // MARK: - Accounts

    func author(of meme: Meme) -> UserProfile? {
        accounts.first { $0.id == meme.authorID }
    }

    /// Memes uploaded by an account, newest first.
    func uploads(of user: UserProfile) -> [Meme] {
        memes
            .filter { $0.authorID == user.id }
            .sorted { $0.postedAt > $1.postedAt }
    }

    /// Accounts the signed-in user follows, in the order they appear in `accounts`.
    var followedAccounts: [UserProfile] {
        accounts.filter { currentUser.followingIDs.contains($0.id) }
    }

    func isFollowing(_ user: UserProfile) -> Bool {
        currentUser.followingIDs.contains(user.id)
    }

    func toggleFollow(_ user: UserProfile) {
        guard user.id != currentUser.id else { return }
        if currentUser.followingIDs.remove(user.id) == nil {
            currentUser.followingIDs.insert(user.id)
        }
    }

    func isReposted(_ meme: Meme) -> Bool {
        currentUser.repostedMemeIDs.contains(meme.id)
    }

    func toggleRepost(_ meme: Meme) {
        if let index = currentUser.repostedMemeIDs.firstIndex(of: meme.id) {
            currentUser.repostedMemeIDs.remove(at: index)
        } else {
            currentUser.repostedMemeIDs.insert(meme.id, at: 0)
            toastMessage = "Reposted to your profile"
        }
    }

    // MARK: - Home feed sources

    /// Memes from followed accounts, newest first. Shown before anything else on Home.
    var followingFeed: [Meme] {
        memes
            .filter { currentUser.followingIDs.contains($0.authorID) }
            .sorted { $0.postedAt > $1.postedAt }
    }

    /// Memes from accounts the user doesn't follow (excluding their own), used for discovery.
    /// Falls back to every meme so the feed never runs dry.
    var discoverPool: [Meme] {
        let pool = memes.filter {
            !currentUser.followingIDs.contains($0.authorID) && $0.authorID != currentUser.id
        }
        return pool.isEmpty ? memes : pool
    }

    // MARK: - Favorites

    func isFavorite(_ meme: Meme) -> Bool {
        memes.first { $0.id == meme.id }?.isFavorite ?? false
    }

    func toggleFavorite(_ meme: Meme) {
        guard let index = memes.firstIndex(where: { $0.id == meme.id }) else { return }
        memes[index].isFavorite.toggle()
    }

    // MARK: - Actions

    /// Set to present the file exporter for a meme (handled by `memeActionHost()`).
    var exportRequest: Meme?
    /// Short confirmation message shown as a toast (handled by `memeActionHost()`).
    var toastMessage: String?

    func copy(_ meme: Meme) {
        MemeActions.copyToClipboard(meme)
        toastMessage = "Copied to clipboard"
    }

    func saveToPhotos(_ meme: Meme) {
        MemeActions.saveToPhotos(meme)
        toastMessage = "Saved to Photos"
    }

    func export(_ meme: Meme) {
        exportRequest = meme
    }

    static var sample: MemeStore {
        MemeStore(memes: Meme.samples, accounts: UserProfile.sampleAccounts, currentUser: .sample)
    }
}
