import Foundation
import CoreData
import Combine

final class CoreDataFavoritesRepository: FavoritesRepository {
    private let stack: CoreDataStack
    private let context: NSManagedObjectContext
    
    private let favoritesSubject = CurrentValueSubject<[ContentItem], Never>([])
    var favoritesPublisher: AnyPublisher<[ContentItem], Never> { favoritesSubject.eraseToAnyPublisher() }
    
    init(stack: CoreDataStack) {
        self.stack = stack
        self.context = stack.context
        refresh()
    }
    
    func getAll() async throws -> [ContentItem] {
        try await context.perform {
            let request = NSFetchRequest<CDFavorite>(entityName: "CDFavorite")
            request.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: false)]
            let results = try self.context.fetch(request)
            return results.map { self.mapToDomain($0) }
        }
    }
    
    func isFavorite(id: Int) async throws -> Bool {
        try await context.perform {
            try self.fetchEntity(id: id) != nil
        }
    }
    
    func add(_ item: ContentItem) async throws {
        try await context.perform {
            if try self.fetchEntity(id: item.id) != nil { return }
            
            let entity = CDFavorite(context: self.context)
            self.fill(entity, from: item)
            entity.addedAt = Date()
            
            try self.context.save()
            self.refresh()
        }
    }
    
    func remove(id: Int) async throws {
        try await context.perform {
            if let entity = try self.fetchEntity(id: id) {
                self.context.delete(entity)
                try self.context.save()
                self.refresh()
            }
        }
    }
    
    // MARK: - Private
    
    private func fetchEntity(id: Int) throws -> CDFavorite? {
        let request = NSFetchRequest<CDFavorite>(entityName: "CDFavorite")
        request.predicate = NSPredicate(format: "id == %lld", Int64(id))
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    private func refresh() {
        Task {
            do {
                let items = try await getAll()
                favoritesSubject.send(items)
            } catch {
                print("Failed to refresh favorites: \(error)")
            }
        }
    }
    
    private func fill(_ entity: CDFavorite, from item: ContentItem) {
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
        entity.actorsJSON = (try? encoder.encode(item.actors)).flatMap { String(data: $0, encoding: String.Encoding.utf8) }
        entity.directorsJSON = (try? encoder.encode(item.directors)).flatMap { String(data: $0, encoding: String.Encoding.utf8) }
        entity.genreListJSON = (try? encoder.encode(item.genreList)).flatMap { String(data: $0, encoding: String.Encoding.utf8) }
    }
    
    private func mapToDomain(_ entity: CDFavorite) -> ContentItem {
        let decoder = JSONDecoder()
        let actors = entity.actorsJSON?.data(using: String.Encoding.utf8).flatMap { try? decoder.decode([String].self, from: $0) } ?? []
        let directors = entity.directorsJSON?.data(using: String.Encoding.utf8).flatMap { try? decoder.decode([String].self, from: $0) } ?? []
        let genreList = entity.genreListJSON?.data(using: String.Encoding.utf8).flatMap { try? decoder.decode([String].self, from: $0) } ?? []
        
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
