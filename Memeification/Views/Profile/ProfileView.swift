//
//  ProfileView.swift
//  Memeification
//
//  Instagram-style profile: avatar + stats header, bio, actions,
//  and a pinned tab bar switching between uploaded and reposted memes.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(MemeStore.self) private var store
    @State private var selectedTab: ProfileTab
    @State private var selectedMeme: Meme?
    @State private var uploadItem: PhotosPickerItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    init(initialTab: ProfileTab = .uploads) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        let user = store.currentUser

        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ProfileHeader(user: user, postCount: store.uploads(of: user).count)
                        .padding(.bottom, 12)

                    Section {
                        postsGrid
                    } header: {
                        ProfileTabBar(selection: $selectedTab)
                    }
                }
            }
            .navigationTitle(user.username)
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    PhotosPicker(selection: $uploadItem, matching: .any(of: [.images, .videos])) {
                        Label("Upload Meme", systemImage: "plus.app")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu("Settings", systemImage: "line.3.horizontal") {
                        Button("Saved", systemImage: "bookmark") {}
                        Button("Favorites", systemImage: "heart") {}
                        Button("Settings", systemImage: "gearshape") {}
                    }
                }
            }
            .onChange(of: uploadItem) {
                // Uploading isn't implemented yet; acknowledge the pick so the flow is visible.
                guard uploadItem != nil else { return }
                store.toastMessage = "Upload coming soon"
                uploadItem = nil
            }
            .sheet(item: $selectedMeme) { meme in
                MemeDetailView(meme: meme)
            }
        }
        .memeActionHost()
    }

    private var currentMemes: [Meme] {
        switch selectedTab {
        case .uploads: store.uploads(of: store.currentUser)
        case .reposts: store.memes(withIDs: store.currentUser.repostedMemeIDs)
        }
    }

    @ViewBuilder
    private var postsGrid: some View {
        let memes = currentMemes
        if memes.isEmpty {
            ContentUnavailableView(
                selectedTab.emptyTitle,
                systemImage: selectedTab.systemImage,
                description: Text(selectedTab.emptyMessage)
            )
            .padding(.top, 40)
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(memes) { meme in
                    Button {
                        selectedMeme = meme
                    } label: {
                        MemeThumbnail(meme: meme, aspectRatio: 3 / 4, cornerRadius: 0)
                            .overlay(alignment: .topLeading) {
                                if selectedTab == .reposts {
                                    Image(systemName: ProfileTab.reposts.systemImage)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 2)
                                        .padding(6)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        MemeActionMenuItems(meme: meme)
                    }
                }
            }
        }
    }
}

// MARK: - Tabs

enum ProfileTab: CaseIterable, Identifiable {
    case uploads
    case reposts

    var id: Self { self }

    var title: String {
        switch self {
        case .uploads: "Memes"
        case .reposts: "Reposts"
        }
    }

    var systemImage: String {
        switch self {
        case .uploads: "square.grid.3x3"
        case .reposts: "arrow.2.squarepath"
        }
    }

    var emptyTitle: String {
        switch self {
        case .uploads: "No Memes Yet"
        case .reposts: "No Reposts Yet"
        }
    }

    var emptyMessage: String {
        switch self {
        case .uploads: "Memes you upload will appear here."
        case .reposts: "Memes you repost will appear here."
        }
    }
}

/// Icon tab bar with a sliding underline, pinned above the grid while scrolling.
private struct ProfileTabBar: View {
    @Binding var selection: ProfileTab
    @Namespace private var underline

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases) { tab in
                Button {
                    withAnimation(.snappy) { selection = tab }
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: tab.systemImage)
                            .font(.title3)
                            .foregroundStyle(selection == tab ? .primary : .secondary)
                            .padding(.top, 10)
                        ZStack {
                            Rectangle().fill(.clear)
                            if selection == tab {
                                Rectangle()
                                    .fill(.primary)
                                    .matchedGeometryEffect(id: "underline", in: underline)
                            }
                        }
                        .frame(height: 1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .background(.background)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

// MARK: - Header

private struct ProfileHeader: View {
    let user: UserProfile
    let postCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 24) {
                ProfileAvatar(emoji: user.avatarEmoji)
                    .frame(width: 88, height: 88)

                HStack {
                    stat(postCount, label: "posts")
                    stat(user.followers, label: "followers")
                    stat(user.following, label: "following")
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(user.bio)
                    .font(.subheadline)
            }

            HStack(spacing: 8) {
                Button {} label: {
                    Text("Edit Profile")
                        .frame(maxWidth: .infinity)
                }
                ShareLink(item: "Check out @\(user.username) on Memeification!") {
                    Text("Share Profile")
                        .frame(maxWidth: .infinity)
                }
                Button("Discover People", systemImage: "person.badge.plus") {}
                    .labelStyle(.iconOnly)
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.glass)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func stat(_ value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value.formatted(.number.notation(.compactName)))
                .font(.headline)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Placeholder avatar: emoji on a gradient, wrapped in an Instagram-like story ring.
struct ProfileAvatar: View {
    let emoji: String
    var ringWidth: CGFloat = 3

    var body: some View {
        Circle()
            .fill(.linearGradient(
                colors: [.indigo, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay {
                // Oversized font scaled down so the emoji fits any avatar size.
                Text(emoji)
                    .font(.system(size: 200))
                    .minimumScaleFactor(0.01)
                    .padding(ringWidth * 4)
            }
            .padding(ringWidth + 1)
            .background {
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [.yellow, .orange, .pink, .purple, .yellow],
                            center: .center
                        ),
                        lineWidth: ringWidth
                    )
            }
            .accessibilityHidden(true)
    }
}

#Preview("Profile") {
    ProfileView()
        .environment(MemeStore.sample)
}

#Preview("Profile – Reposts") {
    ProfileView(initialTab: .reposts)
        .environment(MemeStore.sample)
}

#Preview("Profile – Reposts Empty") {
    let store = MemeStore.sample
    store.currentUser.repostedMemeIDs = []
    return ProfileView(initialTab: .reposts)
        .environment(store)
}
