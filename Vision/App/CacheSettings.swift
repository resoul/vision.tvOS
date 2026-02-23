import Foundation

// MARK: - CacheSettings

final class CacheSettings {

    static let shared = CacheSettings()
    private init() {}

    // MARK: - Steps

    struct Step {
        let label: String       // "2 GB"
        let bytes: Int          // 0 = unlimited
    }

    static let steps: [Step] = [
        Step(label: "256 MB",   bytes: 256  * 1024 * 1024),
        Step(label: "512 MB",   bytes: 512  * 1024 * 1024),
        Step(label: "1 GB",     bytes: 1024 * 1024 * 1024),
        Step(label: "2 GB",     bytes: 2048 * 1024 * 1024),
        Step(label: "4 GB",     bytes: 4096 * 1024 * 1024),
        Step(label: "Без лимита", bytes: 0),
    ]

    static let defaultStepIndex = 3   // 2 GB

    // MARK: - Persistence

    private let key = "poster_cache_step_index"

    var stepIndex: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: key)
            // integer(forKey:) returns 0 when key absent; use a sentinel
            guard UserDefaults.standard.object(forKey: key) != nil else {
                return Self.defaultStepIndex
            }
            return max(0, min(v, Self.steps.count - 1))
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            apply()
        }
    }

    var currentStep: Step { Self.steps[stepIndex] }

    // MARK: - Apply to PosterCache

    func apply() {
        PosterCache.shared.applyMemoryLimit(bytes: currentStep.bytes)
    }
}
