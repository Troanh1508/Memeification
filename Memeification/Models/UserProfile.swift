//
//  UserProfile.swift
//  Memeification
//

import Foundation

nonisolated struct UserProfile: Identifiable, Hashable, Sendable {
    let id: UUID
    var username: String
    var displayName: String
    var bio: String
    /// Placeholder avatar until real profile photos exist.
    var avatarEmoji: String
    var followers: Int
    var following: Int
    /// Accounts this user follows; their memes are prioritized on the Home feed.
    var followingIDs: Set<UserProfile.ID>
    /// Memes from other users that this user reposted, newest first.
    var repostedMemeIDs: [Meme.ID]

    init(
        id: UUID = UUID(),
        username: String,
        displayName: String,
        bio: String = "",
        avatarEmoji: String,
        followers: Int,
        following: Int,
        followingIDs: Set<UserProfile.ID> = [],
        repostedMemeIDs: [Meme.ID] = []
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.avatarEmoji = avatarEmoji
        self.followers = followers
        self.following = following
        self.followingIDs = followingIDs
        self.repostedMemeIDs = repostedMemeIDs
    }
}

extension UserProfile {
    /// All dummy accounts. Index 0 is the signed-in user; `Meme.samples` references these by index.
    static let sampleAccounts: [UserProfile] = [
        UserProfile(
            username: "meme.lord.dev",
            displayName: "Meme Lord",
            bio: "Professional meme curator 🧑‍🍳\nShipping bugs & memes since 2019\nDMs open for dank content",
            avatarEmoji: "😎",
            followers: 128_400,
            following: 312
        ),
        UserProfile(username: "daily.dank", displayName: "Daily Dank", avatarEmoji: "🔥", followers: 2_300_000, following: 120),
        UserProfile(username: "cat.content", displayName: "Cat Content", avatarEmoji: "🐱", followers: 845_000, following: 48),
        UserProfile(username: "dev.humor", displayName: "Dev Humor", avatarEmoji: "💻", followers: 410_000, following: 210),
        UserProfile(username: "doge.society", displayName: "Doge Society", avatarEmoji: "🐶", followers: 1_100_000, following: 12),
        UserProfile(username: "random.chaos", displayName: "Random Chaos", avatarEmoji: "🌀", followers: 96_000, following: 500),
        UserProfile(username: "monday.mood", displayName: "Monday Mood", avatarEmoji: "💀", followers: 57_000, following: 77),
    ]

    /// The signed-in user: follows daily.dank, cat.content and dev.humor, with a few reposts.
    static let sample: UserProfile = {
        let accounts = sampleAccounts
        let memes = Meme.samples
        var me = accounts[0]
        me.followingIDs = [accounts[1].id, accounts[2].id, accounts[3].id]
        me.repostedMemeIDs = [0, 3, 5, 15, 10].map { memes[$0].id }
        return me
    }()
}
