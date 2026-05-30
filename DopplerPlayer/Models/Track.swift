import Foundation
import UIKit

struct Track: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var fileURL: URL
    var trackNumber: Int?
    var artworkData: Data?
    /// 与音频同目录的 .lrc 文件名（如 `song.lrc`）
    var lyricsFileName: String?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String,
        duration: TimeInterval,
        fileURL: URL,
        trackNumber: Int? = nil,
        artworkData: Data? = nil,
        lyricsFileName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.fileURL = fileURL
        self.trackNumber = trackNumber
        self.artworkData = artworkData
        self.lyricsFileName = lyricsFileName
    }

    var hasLyrics: Bool { lyricsFileName != nil }

    var fileStem: String {
        fileURL.deletingPathExtension().lastPathComponent
    }

    var artworkImage: UIImage? {
        guard let artworkData else { return nil }
        return UIImage(data: artworkData)
    }

    var displayArtist: String {
        artist.isEmpty ? "未知艺术家" : artist
    }

    var displayAlbum: String {
        album.isEmpty ? "未知专辑" : album
    }
}

struct AlbumGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let tracks: [Track]

    var artworkImage: UIImage? {
        tracks.compactMap(\.artworkImage).first
    }

    var totalDuration: TimeInterval {
        tracks.reduce(0) { $0 + $1.duration }
    }
}

struct ArtistGroup: Identifiable, Hashable {
    let id: String
    let name: String
    let albums: [AlbumGroup]
    let trackCount: Int
}
