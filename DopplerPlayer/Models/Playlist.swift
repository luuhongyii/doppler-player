import Foundation
import UIKit

struct Playlist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var trackIDs: [UUID]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        trackIDs: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum PlaylistDestination: Hashable {
    case favorites
    case playlist(UUID)
}
