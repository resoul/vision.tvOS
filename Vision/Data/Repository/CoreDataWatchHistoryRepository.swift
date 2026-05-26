import Foundation
import CoreData
import Combine

final class CoreDataWatchHistoryRepository: WatchHistoryRepository {
    private let stack: CoreDataStack
    private let context: NSManagedObjectContext

    private let historySubject = CurrentValueSubject<[ContentItem], Never>([])
    var historyPublisher: AnyPublisher<[ContentItem], Never> { historySubject.eraseToAnyPublisher() }

    init(stack: CoreDataStack) {
        self.stack = stack
        self.context = stack.context
        refresh()
    }

    func getHistory() async throws -> [ContentItem] {
        try await context.perform {
            let request = NSFetchRequest<CDHistory>(entityName: "CDHistory")
            request.sortDescriptors = [NSSortDescriptor(key: "lastWatchedAt", ascending: false)]
            let results = try self.context.fetch(request)
            return results.map { self.mapToDomain($0) }
        }
    }

    func getInProgress() async throws -> [ContentItem] {
        try await getHistory()
    }

    func saveProgress(_ item: ContentItem, episodeId: String?, position: Double, watched: Bool) async throws {
        try await context.perform {
            let request = NSFetchRequest<CDEpisodeProgress>(entityName: "CDEpisodeProgress")
            if let epId = episodeId {
                request.predicate = NSPredicate(format: "movieId == %lld AND episodeId == %@", Int64(item.id), epId)
            } else {
                request.predicate = NSPredicate(format: "movieId == %lld AND episodeId == nil", Int64(item.id))
            }

            let progress: CDEpisodeProgress
            if let found = try self.context.fetch(request).first {
                progress = found
            } else {
                progress = NSEntityDescription.insertNewObject(forEntityName: "CDEpisodeProgress", into: self.context) as! CDEpisodeProgress
            }
            progress.movieId = Int64(item.id)
            progress.episodeId = episodeId
            progress.position = position
            progress.watched = watched
            progress.updatedAt = Date()

            try self.touchInternal(item)
            try self.context.save()
        }
        
        refresh()
    }

    func touch(_ item: ContentItem) async throws {
        try await context.perform {
            try self.touchInternal(item)
            try self.context.save()
        }
        refresh()
    }

    func remove(id: Int) async throws {
        try await context.perform {
            let request = NSFetchRequest<CDHistory>(entityName: "CDHistory")
            request.predicate = NSPredicate(format: "id == %lld", Int64(id))
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
        refresh()
    }

    func clearAll() async throws {
        try await context.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDHistory")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try self.context.execute(deleteRequest)
            try self.context.save()
        }
        refresh()
    }

    // MARK: - Private

    private func touchInternal(_ item: ContentItem) throws {
        let request = NSFetchRequest<CDHistory>(entityName: "CDHistory")
        request.predicate = NSPredicate(format: "id == %lld", Int64(item.id))

        let entity: CDHistory
        if let found = try context.fetch(request).first {
            entity = found
        } else {
            entity = NSEntityDescription.insertNewObject(forEntityName: "CDHistory", into: context) as! CDHistory
        }

        fill(entity, from: item)
        entity.lastWatchedAt = Date()
    }

    private func refresh() {
        Task {
            do {
                let items = try await getHistory()
                await MainActor.run {
                    self.historySubject.send(items)
                }
            } catch {
                print("Failed to refresh history: \(error)")
            }
        }
    }

    private func fill(_ entity: CDHistory, from item: ContentItem) {
        entity.id = Int64(item.id)
        entity.title = item.title
        entity.year = item.year
        entity.desc = item.description
        entity.genre = item.genre
        entity.rating = item.rating
        entity.duration = item.duration
        entity.isSeries = item.type.isSeries
        entity.translate = item.translate
        entity.isAdIn = item.isAdIn
        entity.movieURL = item.movieURL
        entity.posterURL = item.posterURL
        entity.lastAdded = item.lastAdded

        let encoder = JSONEncoder()
        entity.actorsJSON = (try? encoder.encode(item.actors)).flatMap { String(data: $0, encoding: .utf8) }
        entity.directorsJSON = (try? encoder.encode(item.directors)).flatMap { String(data: $0, encoding: .utf8) }
        entity.genreListJSON = (try? encoder.encode(item.genreList)).flatMap { String(data: $0, encoding: .utf8) }
    }

    private func mapToDomain(_ entity: CDHistory) -> ContentItem {
        let decoder = JSONDecoder()
        let actors = entity.actorsJSON?.data(using: .utf8).flatMap { try? decoder.decode([String].self, from: $0) } ?? []
        let directors = entity.directorsJSON?.data(using: .utf8).flatMap { try? decoder.decode([String].self, from: $0) } ?? []
        let genreList = entity.genreListJSON?.data(using: .utf8).flatMap { try? decoder.decode([String].self, from: $0) } ?? []

        return ContentItem(
            id: Int(entity.id),
            title: entity.title ?? "",
            year: entity.year ?? "",
            description: entity.desc ?? "",
            genre: entity.genre ?? "",
            rating: entity.rating ?? "",
            duration: entity.duration ?? "",
            type: entity.isSeries ? .series(seasons: []) : .movie,
            translate: entity.translate ?? "",
            isAdIn: entity.isAdIn,
            movieURL: entity.movieURL ?? "",
            posterURL: entity.posterURL ?? "",
            actors: actors,
            directors: directors,
            genreList: genreList,
            lastAdded: entity.lastAdded
        )
    }
}
