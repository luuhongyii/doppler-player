import AVFoundation
import Foundation
import Observation
import UniformTypeIdentifiers

@Observable
final class LibraryManager {
    private(set) var tracks: [Track] = []
    private(set) var isScanning = false

    private let musicDirectory: URL
    private let indexURL: URL
    private var lyricsCache: [UUID: ParsedLyrics] = [:]

    private static let audioExtensions = ["mp3", "m4a", "aac", "flac", "wav", "aiff", "alac"]

    var tracksWithLyricsCount: Int {
        tracks.filter(\.hasLyrics).count
    }

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        musicDirectory = docs.appendingPathComponent("Music", isDirectory: true)
        indexURL = docs.appendingPathComponent("library.json")
        try? FileManager.default.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
        loadIndex()
        rescanLyricsAssociations()
    }

    var albums: [AlbumGroup] {
        let grouped = Dictionary(grouping: tracks) { "\($0.displayAlbum)|\($0.displayArtist)" }
        return grouped.map { key, items in
            let sorted = items.sorted {
                ($0.trackNumber ?? Int.max, $0.title) < ($1.trackNumber ?? Int.max, $1.title)
            }
            return AlbumGroup(
                id: key,
                title: sorted.first?.displayAlbum ?? "未知专辑",
                artist: sorted.first?.displayArtist ?? "未知艺术家",
                tracks: sorted
            )
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var artists: [ArtistGroup] {
        let byArtist = Dictionary(grouping: albums) { $0.artist }
        return byArtist.map { name, albumList in
            ArtistGroup(
                id: name,
                name: name,
                albums: albumList.sorted { $0.title < $1.title },
                trackCount: albumList.reduce(0) { $0 + $1.tracks.count }
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func importFiles(from urls: [URL]) async {
        isScanning = true
        defer { isScanning = false }

        var audioURLs: [URL] = []
        var lrcURLs: [URL] = []
        for url in urls {
            let ext = url.pathExtension.lowercased()
            if ext == "lrc" {
                lrcURLs.append(url)
            } else if Self.audioExtensions.contains(ext) {
                audioURLs.append(url)
            }
        }

        var imported: [Track] = []
        for source in audioURLs {
            guard let track = await copyAndParse(source: source) else { continue }
            if !tracks.contains(where: { $0.fileURL.lastPathComponent == track.fileURL.lastPathComponent }) {
                imported.append(track)
            }
        }
        if !imported.isEmpty {
            tracks.append(contentsOf: imported)
            tracks.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            saveIndex()
        }

        if !lrcURLs.isEmpty {
            await importLyricsFiles(from: lrcURLs)
        }
        rescanLyricsAssociations()
    }

    func importLyricsFiles(from urls: [URL]) async {
        for source in urls {
            let didAccess = source.startAccessingSecurityScopedResource()
            defer { if didAccess { source.stopAccessingSecurityScopedResource() } }

            let dest = musicDirectory.appendingPathComponent(source.lastPathComponent)
            if source != dest {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try? FileManager.default.removeItem(at: dest)
                }
                try? FileManager.default.copyItem(at: source, to: dest)
            }
            let stem = source.deletingPathExtension().lastPathComponent
            attachLyrics(stem: stem, fileName: dest.lastPathComponent)
        }
        saveIndex()
    }

    func loadLyrics(for track: Track) -> ParsedLyrics? {
        if let cached = lyricsCache[track.id] { return cached }
        guard let fileName = track.lyricsFileName else { return nil }
        let url = musicDirectory.appendingPathComponent(fileName)
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let parsed = LyricsParser.parse(content)
        lyricsCache[track.id] = parsed
        return parsed
    }

    func rescanLyricsAssociations() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: musicDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        for file in files where file.pathExtension.lowercased() == "lrc" {
            attachLyrics(stem: file.deletingPathExtension().lastPathComponent, fileName: file.lastPathComponent)
        }
        saveIndex()
    }

    func rescanMusicFolder() async {
        isScanning = true
        defer { isScanning = false }

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: musicDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        var rebuilt: [Track] = []
        for file in files {
            let ext = file.pathExtension.lowercased()
            guard Self.audioExtensions.contains(ext) else { continue }
            if let track = await parseTrack(at: file) {
                if let existing = tracks.first(where: { $0.fileURL.lastPathComponent == file.lastPathComponent }) {
                    var merged = track
                    merged = Track(
                        id: existing.id,
                        title: track.title,
                        artist: track.artist,
                        album: track.album,
                        duration: track.duration,
                        fileURL: track.fileURL,
                        trackNumber: track.trackNumber,
                        artworkData: track.artworkData ?? existing.artworkData,
                        lyricsFileName: existing.lyricsFileName
                    )
                    rebuilt.append(merged)
                } else {
                    rebuilt.append(track)
                }
            }
        }
        tracks = rebuilt.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        lyricsCache.removeAll()
        rescanLyricsAssociations()
    }

    private func attachLyrics(stem: String, fileName: String) {
        guard let index = tracks.firstIndex(where: { $0.fileStem == stem }) else { return }
        tracks[index].lyricsFileName = fileName
        lyricsCache.removeValue(forKey: tracks[index].id)
    }

    func removeTrack(_ track: Track) {
        tracks.removeAll { $0.id == track.id }
        try? FileManager.default.removeItem(at: track.fileURL)
        if let lrc = track.lyricsFileName {
            try? FileManager.default.removeItem(at: musicDirectory.appendingPathComponent(lrc))
        }
        lyricsCache.removeValue(forKey: track.id)
        saveIndex()
    }

    func removeAlbum(_ album: AlbumGroup) {
        for track in album.tracks {
            try? FileManager.default.removeItem(at: track.fileURL)
        }
        let ids = Set(album.tracks.map(\.id))
        tracks.removeAll { ids.contains($0.id) }
        saveIndex()
    }

    private func copyAndParse(source: URL) async -> Track? {
        let ext = source.pathExtension.lowercased()
        guard Self.audioExtensions.contains(ext) else {
            return nil
        }

        let didAccess = source.startAccessingSecurityScopedResource()
        defer { if didAccess { source.stopAccessingSecurityScopedResource() } }

        let dest = musicDirectory.appendingPathComponent(source.lastPathComponent)
        if source != dest {
            if FileManager.default.fileExists(atPath: dest.path) {
                try? FileManager.default.removeItem(at: dest)
            }
            do {
                try FileManager.default.copyItem(at: source, to: dest)
            } catch {
                return nil
            }
        }

        guard var track = await parseTrack(at: dest) else { return nil }
        let lrc = musicDirectory.appendingPathComponent(dest.deletingPathExtension().lastPathComponent + ".lrc")
        if FileManager.default.fileExists(atPath: lrc.path) {
            track.lyricsFileName = lrc.lastPathComponent
        }
        return track
    }

    private func parseTrack(at url: URL) async -> Track? {
        let asset = AVURLAsset(url: url)
        var title = url.deletingPathExtension().lastPathComponent
        var artist = ""
        var album = ""
        var trackNumber: Int?
        var artworkData: Data?

        let metadata = (try? await asset.load(.metadata)) ?? []
        for item in metadata {
            guard let key = item.commonKey else { continue }
            switch key {
            case .commonKeyTitle:
                if let v = try? await item.load(.stringValue) { title = v }
            case .commonKeyArtist:
                if let v = try? await item.load(.stringValue) { artist = v }
            case .commonKeyAlbumName:
                if let v = try? await item.load(.stringValue) { album = v }
            case .commonKeyArtwork:
                if let v = try? await item.load(.dataValue) { artworkData = v }
            default:
                break
            }
        }

        if let numItem = metadata.first(where: { $0.identifier == .id3MetadataTrackNumber ||
            $0.key as? String == "trackNumber" }) {
            if let n = try? await numItem.load(.numberValue) {
                trackNumber = n.intValue
            }
        }

        let duration: TimeInterval
        if let d = try? await asset.load(.duration) {
            duration = CMTimeGetSeconds(d)
        } else {
            duration = 0
        }

        return Track(
            title: title,
            artist: artist,
            album: album,
            duration: duration.isFinite ? duration : 0,
            fileURL: url,
            trackNumber: trackNumber,
            artworkData: artworkData
        )
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL),
              let saved = try? JSONDecoder().decode([Track].self, from: data) else { return }
        tracks = saved.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
    }

    private func saveIndex() {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}

extension UTType {
    static let audioImport: [UTType] = {
        var types: [UTType] = [
            .mp3, .mpeg4Audio, .wav, .aiff, .audio, .plainText,
            UTType(filenameExtension: "flac") ?? .audio,
            UTType(filenameExtension: "m4a") ?? .mpeg4Audio,
            UTType(filenameExtension: "lrc") ?? .plainText
        ]
        return types.uniqued()
    }()
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
