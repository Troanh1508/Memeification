//
//  MemeActions.swift
//  Memeification
//

import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A shareable/exportable PNG representation of a meme, used by `ShareLink` and `fileExporter`.
struct MemeFile: Transferable {
    let meme: Meme

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { file in
            guard let data = MemeActions.pngData(for: file.meme) else {
                throw CocoaError(.fileReadUnknown)
            }
            return data
        }
        .suggestedFileName { $0.meme.title }
    }
}

/// Platform-specific helpers for copying, saving and encoding meme images.
enum MemeActions {
    /// Nonisolated so `MemeFile`'s transfer representation can encode off the main actor.
    nonisolated static func pngData(for meme: Meme) -> Data? {
        #if canImport(UIKit)
        return UIImage(named: meme.imageName)?.pngData()
        #elseif canImport(AppKit)
        guard let tiff = NSImage(named: meme.imageName)?.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }

    static func copyToClipboard(_ meme: Meme) {
        #if canImport(UIKit)
        UIPasteboard.general.image = UIImage(named: meme.imageName)
        #elseif canImport(AppKit)
        guard let image = NSImage(named: meme.imageName) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        #endif
    }

    /// Whether "Save to Photos" is available on this platform.
    static var canSaveToPhotos: Bool {
        #if canImport(UIKit)
        true
        #else
        false
        #endif
    }

    static func saveToPhotos(_ meme: Meme) {
        #if canImport(UIKit)
        guard let image = UIImage(named: meme.imageName) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        #endif
    }
}
