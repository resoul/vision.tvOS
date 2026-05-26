import Foundation
import CoreData

final class CoreDataPlaybackStateRepository: PlaybackStateRepository {
    private let stack: CoreDataStack
    private let context: NSManagedObjectContext
    
    init(stack: CoreDataStack) {
        self.stack = stack
        self.context = stack.context
    }
    
    func getState(movieId: Int) async throws -> PlaybackState? {
        try await context.perform {
            let request = NSFetchRequest<CDPlaybackState>(entityName: "CDPlaybackState")
            request.predicate = NSPredicate(format: "movieId == %lld", Int64(movieId))
            request.fetchLimit = 1
            
            guard let entity = try self.context.fetch(request).first else { return nil }
            return self.mapToDomain(entity)
        }
    }
    
    func saveState(_ state: PlaybackState) async throws {
        try await context.perform {
            let request = NSFetchRequest<CDPlaybackState>(entityName: "CDPlaybackState")
            request.predicate = NSPredicate(format: "movieId == %lld", Int64(state.movieId))
            
            let entity: CDPlaybackState
            if let found = try self.context.fetch(request).first {
                entity = found
            } else {
                entity = NSEntityDescription.insertNewObject(forEntityName: "CDPlaybackState", into: self.context) as! CDPlaybackState
            }
            entity.movieId = Int64(state.movieId)
            entity.season = Int32(state.season)
            entity.episode = Int32(state.episode)
            entity.studio = state.studio
            entity.quality = state.quality
            entity.updatedAt = state.updatedAt
            
            try self.context.save()
        }
    }
    
    func clearState(movieId: Int) async throws {
        try await context.perform {
            let request = NSFetchRequest<CDPlaybackState>(entityName: "CDPlaybackState")
            request.predicate = NSPredicate(format: "movieId == %lld", Int64(movieId))
            
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
    
    private func mapToDomain(_ entity: CDPlaybackState) -> PlaybackState {
        return PlaybackState(
            movieId: Int(entity.movieId),
            season: Int(entity.season),
            episode: Int(entity.episode),
            studio: entity.studio ?? "",
            quality: entity.quality ?? "",
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}
