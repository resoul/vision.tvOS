import CoreData
import Foundation

final class CoreDataStack {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Vision", managedObjectModel: Self.makeModel())
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Favorite
        let favorite = NSEntityDescription()
        favorite.name = "CDFavorite"
        favorite.managedObjectClassName = NSStringFromClass(CDFavorite.self)
        favorite.properties = [
            attr(.dateAttributeType, name: "addedAt", optional: true),
            attr(.integer64AttributeType, name: "id"),
            attr(.stringAttributeType, name: "title", optional: true),
            attr(.stringAttributeType, name: "year", optional: true),
            attr(.stringAttributeType, name: "desc", optional: true),
            attr(.stringAttributeType, name: "genre", optional: true),
            attr(.stringAttributeType, name: "rating", optional: true),
            attr(.stringAttributeType, name: "duration", optional: true),
            attr(.booleanAttributeType, name: "isSeries"),
            attr(.stringAttributeType, name: "translate", optional: true),
            attr(.booleanAttributeType, name: "isAdIn"),
            attr(.stringAttributeType, name: "movieURL", optional: true),
            attr(.stringAttributeType, name: "posterURL", optional: true),
            attr(.stringAttributeType, name: "lastAdded", optional: true),
            attr(.stringAttributeType, name: "actorsJSON", optional: true),
            attr(.stringAttributeType, name: "directorsJSON", optional: true),
            attr(.stringAttributeType, name: "genreListJSON", optional: true)
        ]
        
        // History
        let history = NSEntityDescription()
        history.name = "CDHistory"
        history.managedObjectClassName = NSStringFromClass(CDHistory.self)
        history.properties = [
            attr(.dateAttributeType, name: "lastWatchedAt", optional: true),
            attr(.integer64AttributeType, name: "id"),
            attr(.stringAttributeType, name: "title", optional: true),
            attr(.stringAttributeType, name: "year", optional: true),
            attr(.stringAttributeType, name: "desc", optional: true),
            attr(.stringAttributeType, name: "genre", optional: true),
            attr(.stringAttributeType, name: "rating", optional: true),
            attr(.stringAttributeType, name: "duration", optional: true),
            attr(.booleanAttributeType, name: "isSeries"),
            attr(.stringAttributeType, name: "translate", optional: true),
            attr(.booleanAttributeType, name: "isAdIn"),
            attr(.stringAttributeType, name: "movieURL", optional: true),
            attr(.stringAttributeType, name: "posterURL", optional: true),
            attr(.stringAttributeType, name: "lastAdded", optional: true),
            attr(.stringAttributeType, name: "actorsJSON", optional: true),
            attr(.stringAttributeType, name: "directorsJSON", optional: true),
            attr(.stringAttributeType, name: "genreListJSON", optional: true)
        ]
        
        // Episode Progress
        let progress = NSEntityDescription()
        progress.name = "CDEpisodeProgress"
        progress.managedObjectClassName = NSStringFromClass(CDEpisodeProgress.self)
        progress.properties = [
            attr(.integer64AttributeType, name: "movieId"),
            attr(.stringAttributeType, name: "episodeId", optional: true),
            attr(.doubleAttributeType, name: "position"),
            attr(.booleanAttributeType, name: "watched"),
            attr(.dateAttributeType, name: "updatedAt", optional: true)
        ]
        
        // Playback State
        let playback = NSEntityDescription()
        playback.name = "CDPlaybackState"
        playback.managedObjectClassName = NSStringFromClass(CDPlaybackState.self)
        playback.properties = [
            attr(.integer64AttributeType, name: "movieId"),
            attr(.integer32AttributeType, name: "season"),
            attr(.integer32AttributeType, name: "episode"),
            attr(.stringAttributeType, name: "studio", optional: true),
            attr(.stringAttributeType, name: "quality", optional: true),
            attr(.dateAttributeType, name: "updatedAt", optional: true)
        ]
        
        model.entities = [favorite, history, progress, playback]
        return model
    }
    
    private static func attr(_ type: NSAttributeType, name: String, optional: Bool = false) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        return attr
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("CoreData save error: \(error)")
            }
        }
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}
