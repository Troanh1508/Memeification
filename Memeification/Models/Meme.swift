//
//  Meme.swift
//  Memeification
//

import Foundation

/// The media format of a meme. Dummy data reuses still images for every kind.
nonisolated enum MemeKind: String, CaseIterable, Identifiable, Sendable {
    case image
    case gif
    case video

    var id: Self { self }

    var label: String {
        switch self {
        case .image: "Image"
        case .gif: "GIF"
        case .video: "Video"
        }
    }

    var systemImage: String {
        switch self {
        case .image: "photo"
        case .gif: "sparkles"
        case .video: "play.fill"
        }
    }
}

nonisolated enum MemeCategory: String, CaseIterable, Identifiable, Sendable {
    case trending = "Trending"
    case reaction = "Reaction"
    case animals = "Animals"
    case coding = "Coding"
    case classic = "Classic"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .trending: "flame.fill"
        case .reaction: "face.smiling"
        case .animals: "pawprint.fill"
        case .coding: "chevron.left.forwardslash.chevron.right"
        case .classic: "star.fill"
        }
    }
}

nonisolated struct Meme: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var imageName: String
    var kind: MemeKind
    var category: MemeCategory
    var tags: [String]
    var likes: Int
    /// Width / height of the source image, used by layouts that respect natural proportions.
    var aspectRatio: CGFloat
    /// The account that uploaded this meme.
    var authorID: UserProfile.ID
    var postedAt: Date
    var isFavorite: Bool = false

    init(
        id: UUID = UUID(),
        title: String,
        imageName: String,
        kind: MemeKind = .image,
        category: MemeCategory,
        tags: [String],
        likes: Int,
        aspectRatio: CGFloat = 1,
        author: UserProfile,
        postedAt: Date
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.kind = kind
        self.category = category
        self.tags = tags
        self.likes = likes
        self.aspectRatio = aspectRatio
        self.authorID = author.id
        self.postedAt = postedAt
    }
}

extension Meme {
    static let samples: [Meme] = {
        let accounts = UserProfile.sampleAccounts
        let me = accounts[0], dank = accounts[1], cats = accounts[2], dev = accounts[3]
        let doge = accounts[4], chaos = accounts[5], monday = accounts[6]
        func hoursAgo(_ hours: Double) -> Date { .now.addingTimeInterval(-hours * 3600) }

        return [
            Meme(title: "Me at 3AM", imageName: "Meme01", category: .trending, tags: ["sleep", "netflix", "relatable"], likes: 12_400, author: dank, postedAt: hoursAgo(1)),
            Meme(title: "Compiles First Try", imageName: "Meme02", kind: .gif, category: .coding, tags: ["code", "celebrate", "rare"], likes: 8_930, aspectRatio: 0.8, author: me, postedAt: hoursAgo(5)),
            Meme(title: "I Has a Keyboard", imageName: "Meme03", category: .animals, tags: ["cat", "keyboard", "classic"], likes: 5_210, author: cats, postedAt: hoursAgo(3)),
            Meme(title: "This Is Fine", imageName: "Meme04", kind: .video, category: .classic, tags: ["fire", "fine", "chaos"], likes: 22_150, aspectRatio: 4.0 / 3.0, author: chaos, postedAt: hoursAgo(2)),
            Meme(title: "What If We Didn't", imageName: "Meme05", category: .reaction, tags: ["thinking", "lazy"], likes: 3_480, aspectRatio: 8.0 / 9.0, author: me, postedAt: hoursAgo(30)),
            Meme(title: "Such Meme, Much Wow", imageName: "Meme06", kind: .gif, category: .animals, tags: ["doge", "wow", "dog"], likes: 18_760, author: doge, postedAt: hoursAgo(4)),
            Meme(title: "Monday Again", imageName: "Meme07", category: .reaction, tags: ["monday", "work", "skull"], likes: 9_870, aspectRatio: 8.0 / 11.0, author: monday, postedAt: hoursAgo(9)),
            Meme(title: "Deployed on Friday", imageName: "Meme08", kind: .video, category: .coding, tags: ["deploy", "friday", "yolo"], likes: 6_640, aspectRatio: 8.0 / 7.0, author: me, postedAt: hoursAgo(52)),
            Meme(title: "Works on My Machine", imageName: "Meme09", category: .coding, tags: ["bug", "excuse", "dev"], likes: 14_320, author: dev, postedAt: hoursAgo(6)),
            Meme(title: "Rubber Duck Debugging", imageName: "Meme10", kind: .gif, category: .coding, tags: ["duck", "debug"], likes: 4_090, aspectRatio: 80.0 / 95.0, author: dev, postedAt: hoursAgo(20)),
            Meme(title: "Coffee Love Language", imageName: "Meme11", category: .trending, tags: ["coffee", "morning", "love"], likes: 11_050, author: dank, postedAt: hoursAgo(12)),
            Meme(title: "The Cloud Bill", imageName: "Meme12", kind: .video, category: .trending, tags: ["aws", "money", "shock"], likes: 7_720, aspectRatio: 80.0 / 65.0, author: me, postedAt: hoursAgo(75)),
            Meme(title: "Sleepy Reaction", imageName: "Meme01", kind: .gif, category: .reaction, tags: ["tired", "yawn"], likes: 2_310, author: me, postedAt: hoursAgo(100)),
            Meme(title: "Everything Is Fine", imageName: "Meme04", category: .classic, tags: ["fine", "denial"], likes: 16_480, aspectRatio: 4.0 / 3.0, author: chaos, postedAt: hoursAgo(26)),
            Meme(title: "Doge Classic", imageName: "Meme06", category: .classic, tags: ["doge", "shiba"], likes: 25_900, author: doge, postedAt: hoursAgo(48)),
            Meme(title: "Cat Typing Furiously", imageName: "Meme03", kind: .video, category: .animals, tags: ["cat", "typing", "work"], likes: 6_150, author: cats, postedAt: hoursAgo(15)),
        ]
    }()
}
