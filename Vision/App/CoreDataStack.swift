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

        // ── WatchedEpisode ─────────────────────────────────────────────────
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

        // ── MovieProgress ──────────────────────────────────────────────────
        let movieEntity = NSEntityDescription()
        movieEntity.name = "MovieProgress"
        movieEntity.managedObjectClassName = NSStringFromClass(MovieProgress.self)
        movieEntity.properties = [
            attr(.integer64AttributeType, name: "movieId"),
            attr(.doubleAttributeType,    name: "positionSeconds"),
            attr(.doubleAttributeType,    name: "durationSeconds"),
            attr(.stringAttributeType,    name: "studio",     optional: true),
            attr(.stringAttributeType,    name: "quality",    optional: true),
            attr(.stringAttributeType,    name: "streamURL",  optional: true),
            attr(.dateAttributeType,      name: "updatedAt",  optional: true),
        ]
        let movieIdx = NSFetchIndexDescription(name: "byMovieId", elements: [
            NSFetchIndexElementDescription(property: movieEntity.propertiesByName["movieId"]!, collationType: .binary),
        ])
        movieEntity.indexes = [movieIdx]

        model.entities = [episodeEntity, movieEntity]
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
    @NSManaged var movieId:          Int64
    @NSManaged var season:           Int32
    @NSManaged var episode:          Int32
    @NSManaged var watched:          Bool
    @NSManaged var positionSeconds:  Double
    @NSManaged var durationSeconds:  Double
    @NSManaged var updatedAt:        Date?
}

// MARK: - MovieProgress

@objc(MovieProgress)
final class MovieProgress: NSManagedObject {
    @NSManaged var movieId:          Int64
    @NSManaged var positionSeconds:  Double
    @NSManaged var durationSeconds:  Double
    @NSManaged var studio:           String?
    @NSManaged var quality:          String?
    @NSManaged var streamURL:        String?
    @NSManaged var updatedAt:        Date?
}
