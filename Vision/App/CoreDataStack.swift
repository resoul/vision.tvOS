import CoreData

// MARK: - CoreDataStack

final class CoreDataStack {

    static let shared = CoreDataStack()
    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "VisionData",
                                              managedObjectModel: Self.makeModel())
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData load error: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    func save() {
        guard context.hasChanges else { return }
        try? context.save()
    }

    // MARK: - Programmatic model

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let episodeEntity = NSEntityDescription()
        episodeEntity.name = "WatchedEpisode"
        episodeEntity.managedObjectClassName = NSStringFromClass(WatchedEpisode.self)
        episodeEntity.properties = [
            attr(.integer64AttributeType, name: "movieId"),
            attr(.integer32AttributeType, name: "season"),
            attr(.integer32AttributeType, name: "episode"),
            attr(.booleanAttributeType,   name: "watched"),
            attr(.doubleAttributeType,    name: "positionSeconds",  optional: true),
            attr(.doubleAttributeType,    name: "durationSeconds",  optional: true),
            attr(.dateAttributeType,      name: "updatedAt",        optional: true),
        ]
        let episodeIdx = NSFetchIndexDescription(name: "byMovieSeasonEpisode", elements: [
            NSFetchIndexElementDescription(property: episodeEntity.propertiesByName["movieId"]!,  collationType: .binary),
            NSFetchIndexElementDescription(property: episodeEntity.propertiesByName["season"]!,   collationType: .binary),
            NSFetchIndexElementDescription(property: episodeEntity.propertiesByName["episode"]!,  collationType: .binary),
        ])
        episodeEntity.indexes = [episodeIdx]
        let movieEntity = NSEntityDescription()
        movieEntity.name = "MovieProgress"
        movieEntity.managedObjectClassName = NSStringFromClass(MovieProgress.self)
        movieEntity.properties = [
            attr(.integer64AttributeType, name: "movieId"),
            attr(.doubleAttributeType,    name: "positionSeconds"),
            attr(.doubleAttributeType,    name: "durationSeconds"),
            attr(.booleanAttributeType,   name: "watched"),          // NEW
            attr(.stringAttributeType,    name: "studio",     optional: true),
            attr(.stringAttributeType,    name: "quality",    optional: true),
            attr(.stringAttributeType,    name: "streamURL",  optional: true),
            attr(.dateAttributeType,      name: "updatedAt",  optional: true),
        ]
        let movieIdx = NSFetchIndexDescription(name: "byMovieId", elements: [
            NSFetchIndexElementDescription(property: movieEntity.propertiesByName["movieId"]!, collationType: .binary),
        ])
        movieEntity.indexes = [movieIdx]
        let seriesEntity = NSEntityDescription()
        seriesEntity.name = "SeriesLastPlayed"
        seriesEntity.managedObjectClassName = NSStringFromClass(SeriesLastPlayed.self)
        seriesEntity.properties = [
            attr(.integer64AttributeType, name: "movieId"),
            attr(.integer32AttributeType, name: "season"),
            attr(.integer32AttributeType, name: "episode"),
            attr(.stringAttributeType,    name: "quality",   optional: true),
            attr(.stringAttributeType,    name: "studio",    optional: true),
            attr(.dateAttributeType,      name: "updatedAt", optional: true),
        ]
        let seriesIdx = NSFetchIndexDescription(name: "byMovieIdSeries", elements: [
            NSFetchIndexElementDescription(property: seriesEntity.propertiesByName["movieId"]!, collationType: .binary),
        ])
        seriesEntity.indexes = [seriesIdx]
        let favoriteEntity = NSEntityDescription()
        favoriteEntity.name = "FavoriteMovie"
        favoriteEntity.managedObjectClassName = NSStringFromClass(FavoriteMovie.self)
        favoriteEntity.properties = [
            attr(.integer64AttributeType, name: "movieId"),
            attr(.stringAttributeType,    name: "title"),
            attr(.stringAttributeType,    name: "year",             optional: true),
            attr(.stringAttributeType,    name: "movieDescription", optional: true),
            attr(.stringAttributeType,    name: "imageName",        optional: true),
            attr(.stringAttributeType,    name: "genre",            optional: true),
            attr(.stringAttributeType,    name: "rating",           optional: true),
            attr(.stringAttributeType,    name: "duration",         optional: true),
            attr(.booleanAttributeType,   name: "isSeries"),
            attr(.stringAttributeType,    name: "translate",        optional: true),
            attr(.booleanAttributeType,   name: "isAdIn"),
            attr(.stringAttributeType,    name: "movieURL",         optional: true),
            attr(.stringAttributeType,    name: "posterURL",        optional: true),
            attr(.stringAttributeType,    name: "actorsJSON",       optional: true),
            attr(.stringAttributeType,    name: "directorsJSON",    optional: true),
            attr(.stringAttributeType,    name: "genreListJSON",    optional: true),
            attr(.stringAttributeType,    name: "lastAdded",        optional: true),
            attr(.dateAttributeType,      name: "addedAt",          optional: true),
        ]
        let favoriteIdx = NSFetchIndexDescription(name: "byMovieIdFavorite", elements: [
            NSFetchIndexElementDescription(property: favoriteEntity.propertiesByName["movieId"]!, collationType: .binary),
        ])
        favoriteEntity.indexes = [favoriteIdx]

        let historyEntity = NSEntityDescription()
        historyEntity.name = "WatchHistoryEntry"
        historyEntity.managedObjectClassName = NSStringFromClass(WatchHistoryEntry.self)
        historyEntity.properties = [
            attr(.integer64AttributeType, name: "movieId"),
            attr(.stringAttributeType,    name: "title"),
            attr(.stringAttributeType,    name: "year",             optional: true),
            attr(.stringAttributeType,    name: "movieDescription", optional: true),
            attr(.stringAttributeType,    name: "imageName",        optional: true),
            attr(.stringAttributeType,    name: "genre",            optional: true),
            attr(.stringAttributeType,    name: "rating",           optional: true),
            attr(.stringAttributeType,    name: "duration",         optional: true),
            attr(.booleanAttributeType,   name: "isSeries"),
            attr(.stringAttributeType,    name: "translate",        optional: true),
            attr(.booleanAttributeType,   name: "isAdIn"),
            attr(.stringAttributeType,    name: "movieURL",         optional: true),
            attr(.stringAttributeType,    name: "posterURL",        optional: true),
            attr(.stringAttributeType,    name: "actorsJSON",       optional: true),
            attr(.stringAttributeType,    name: "directorsJSON",    optional: true),
            attr(.stringAttributeType,    name: "genreListJSON",    optional: true),
            attr(.stringAttributeType,    name: "lastAdded",        optional: true),
            attr(.dateAttributeType,      name: "lastWatchedAt",    optional: true),
        ]
        let historyIdx = NSFetchIndexDescription(name: "byMovieIdHistory", elements: [
            NSFetchIndexElementDescription(property: historyEntity.propertiesByName["movieId"]!, collationType: .binary),
        ])
        historyEntity.indexes = [historyIdx]

        model.entities = [episodeEntity, movieEntity, seriesEntity, favoriteEntity, historyEntity]
        return model
    }

    private static func attr(_ type: NSAttributeType, name: String, optional: Bool = false) -> NSAttributeDescription {
        let d = NSAttributeDescription()
        d.name = name
        d.attributeType = type
        d.isOptional = optional
        return d
    }
}

// MARK: - WatchedEpisode

@objc(WatchedEpisode)
final class WatchedEpisode: NSManagedObject {
    @NSManaged var movieId:         Int64
    @NSManaged var season:          Int32
    @NSManaged var episode:         Int32
    @NSManaged var watched:         Bool
    @NSManaged var positionSeconds: Double
    @NSManaged var durationSeconds: Double
    @NSManaged var updatedAt:       Date?
}

// MARK: - MovieProgress

@objc(MovieProgress)
final class MovieProgress: NSManagedObject {
    @NSManaged var movieId:         Int64
    @NSManaged var positionSeconds: Double
    @NSManaged var durationSeconds: Double
    @NSManaged var watched:         Bool
    @NSManaged var studio:          String?
    @NSManaged var quality:         String?
    @NSManaged var streamURL:       String?
    @NSManaged var updatedAt:       Date?
}

// MARK: - SeriesLastPlayed

@objc(SeriesLastPlayed)
final class SeriesLastPlayed: NSManagedObject {
    @NSManaged var movieId:   Int64
    @NSManaged var season:    Int32
    @NSManaged var episode:   Int32
    @NSManaged var quality:   String?
    @NSManaged var studio:    String?
    @NSManaged var updatedAt: Date?
}

// MARK: - FavoriteMovie

@objc(FavoriteMovie)
final class FavoriteMovie: NSManagedObject {
    @NSManaged var movieId:          Int64
    @NSManaged var title:            String
    @NSManaged var year:             String?
    @NSManaged var movieDescription: String?
    @NSManaged var imageName:        String?
    @NSManaged var genre:            String?
    @NSManaged var rating:           String?
    @NSManaged var duration:         String?
    @NSManaged var isSeries:         Bool
    @NSManaged var translate:        String?
    @NSManaged var isAdIn:           Bool
    @NSManaged var movieURL:         String?
    @NSManaged var posterURL:        String?
    @NSManaged var actorsJSON:       String?
    @NSManaged var directorsJSON:    String?
    @NSManaged var genreListJSON:    String?
    @NSManaged var lastAdded:        String?
    @NSManaged var addedAt:          Date?
}

// MARK: - WatchHistoryEntry

@objc(WatchHistoryEntry)
final class WatchHistoryEntry: NSManagedObject {
    @NSManaged var movieId:          Int64
    @NSManaged var title:            String
    @NSManaged var year:             String?
    @NSManaged var movieDescription: String?
    @NSManaged var imageName:        String?
    @NSManaged var genre:            String?
    @NSManaged var rating:           String?
    @NSManaged var duration:         String?
    @NSManaged var isSeries:         Bool
    @NSManaged var translate:        String?
    @NSManaged var isAdIn:           Bool
    @NSManaged var movieURL:         String?
    @NSManaged var posterURL:        String?
    @NSManaged var actorsJSON:       String?
    @NSManaged var directorsJSON:    String?
    @NSManaged var genreListJSON:    String?
    @NSManaged var lastAdded:        String?
    @NSManaged var lastWatchedAt:    Date?
}
