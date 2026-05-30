import Foundation
import Observation

@Observable
final class PlaylistStore {
    private(set) var playlists: [Playlist] = []
    private(set) var favoriteTrackIDs: [UUID] = []

    private let storeURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storeURL = docs.appendingPathComponent("playlists.json")
        load()
    }

    var favoritesCount: Int { favoriteTrackIDs.count }

    func isFavorite(_ track: Track) -> Bool {
        favoriteTrackIDs.contains(track.id)
    }

    @discardableResult
    func toggleFavorite(_ track: Track) -> Bool {
        if let index = favoriteTrackIDs.firstIndex(of: track.id) {
            favoriteTrackIDs.remove(at: index)
            save()
            return false
        }
        favoriteTrackIDs.insert(track.id, at: 0)
        save()
        return true
    }

    func favoriteTracks(from allTracks: [Track]) -> [Track] {
        resolveTracks(ids: favoriteTrackIDs, from: allTracks)
    }

    @discardableResult
    func createPlaylist(name: String) -> Playlist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let playlist = Playlist(name: trimmed.isEmpty ? "未命名播放列表" : trimmed)
        playlists.insert(playlist, at: 0)
        save()
        return playlist
    }

    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        save()
    }

    func renamePlaylist(_ playlist: Playlist, name: String) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        playlists[index].name = trimmed.isEmpty ? playlists[index].name : trimmed
        playlists[index].updatedAt = Date()
        save()
    }

    func playlist(id: UUID) -> Playlist? {
        playlists.first { $0.id == id }
    }

    func tracks(for playlist: Playlist, from allTracks: [Track]) -> [Track] {
        resolveTracks(ids: playlist.trackIDs, from: allTracks)
    }

    func contains(_ track: Track, in playlist: Playlist) -> Bool {
        playlist.trackIDs.contains(track.id)
    }

    func addTrack(_ track: Track, to playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        guard !playlists[index].trackIDs.contains(track.id) else { return }
        playlists[index].trackIDs.append(track.id)
        playlists[index].updatedAt = Date()
        save()
    }

    func removeTrack(_ track: Track, from playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].trackIDs.removeAll { $0 == track.id }
        playlists[index].updatedAt = Date()
        save()
    }

    func removeTracks(at offsets: IndexSet, from playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].trackIDs.remove(atOffsets: offsets)
        playlists[index].updatedAt = Date()
        save()
    }

    func moveTracks(from source: IndexSet, to destination: Int, in playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index].trackIDs.move(fromOffsets: source, toOffset: destination)
        playlists[index].updatedAt = Date()
        save()
    }

    func reorderFavorites(_ trackIDs: [UUID]) {
        favoriteTrackIDs = trackIDs
        save()
    }

    func removeTrackFromAll(_ trackId: UUID) {
        favoriteTrackIDs.removeAll { $0 == trackId }
        for i in playlists.indices {
            playlists[i].trackIDs.removeAll { $0 == trackId }
        }
        save()
    }

    func pruneInvalidTracks(validIDs: Set<UUID>) {
        favoriteTrackIDs.removeAll { !validIDs.contains($0) }
        for i in playlists.indices {
            playlists[i].trackIDs.removeAll { !validIDs.contains($0) }
        }
        save()
    }

    private func resolveTracks(ids: [UUID], from allTracks: [Track]) -> [Track] {
        let map = Dictionary(uniqueKeysWithValues: allTracks.map { ($0.id, $0) })
        return ids.compactMap { map[$0] }
    }

    private struct PersistedData: Codable {
        var playlists: [Playlist]
        var favoriteTrackIDs: [UUID]
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let saved = try? JSONDecoder().decode(PersistedData.self, from: data) else { return }
        playlists = saved.playlists
        favoriteTrackIDs = saved.favoriteTrackIDs
    }

    private func save() {
        let payload = PersistedData(playlists: playlists, favoriteTrackIDs: favoriteTrackIDs)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
}
