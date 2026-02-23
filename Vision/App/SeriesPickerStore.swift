import Foundation
import CoreData

final class SeriesPickerStore {

    static let shared = SeriesPickerStore()
    private var ctx: NSManagedObjectContext { CoreDataStack.shared.context }

    private static let globalQualityKey = "globalPreferredStreamQuality"

    var globalPreferredQuality: String? {
        get { UserDefaults.standard.string(forKey: Self.globalQualityKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.globalQualityKey) }
    }

    private init() {}

    // MARK: - Public API

    func season(movieId: Int) -> Int {
        Int(fetch(movieId: movieId)?.season ?? 0)
    }

    func episode(movieId: Int) -> Int {
        Int(fetch(movieId: movieId)?.episode ?? 0)
    }

    func quality(movieId: Int) -> String? {
        fetch(movieId: movieId)?.quality
    }

    func studio(movieId: Int) -> String? {
        fetch(movieId: movieId)?.studio
    }

    func save(movieId: Int, season: Int, episode: Int, quality: String, studio: String) {
        let entry = fetch(movieId: movieId) ?? SeriesLastPlayed(context: ctx)
        entry.movieId   = Int64(movieId)
        entry.season    = Int32(season)
        entry.episode   = Int32(episode)
        entry.quality   = quality
        entry.studio    = studio
        entry.updatedAt = Date()
        CoreDataStack.shared.save()
    }

    // MARK: - Private

    private func fetch(movieId: Int) -> SeriesLastPlayed? {
        let req = NSFetchRequest<SeriesLastPlayed>(entityName: "SeriesLastPlayed")
        req.predicate  = NSPredicate(format: "movieId == %lld", Int64(movieId))
        req.fetchLimit = 1
        return try? ctx.fetch(req).first
    }
}
