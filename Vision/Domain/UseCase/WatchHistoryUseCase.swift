import Foundation
import Combine

protocol WatchHistoryUseCaseProtocol {
    func saveProgress(_ item: ContentItem, episodeId: String?, position: Double, watched: Bool) async throws
    func getInProgress() async throws -> [ContentItem]
    func getHistory() async throws -> [ContentItem]
    func touch(_ item: ContentItem) async throws
    func remove(id: Int) async throws
    func clearAll() async throws
    var historyPublisher: AnyPublisher<[ContentItem], Never> { get }
}

final class WatchHistoryUseCase: WatchHistoryUseCaseProtocol {
    private let repository: WatchHistoryRepository
    
    var historyPublisher: AnyPublisher<[ContentItem], Never> {
        repository.historyPublisher
    }
    
    init(repository: WatchHistoryRepository) {
        self.repository = repository
    }
    
    func getHistory() async throws -> [ContentItem] {
        try await repository.getHistory()
    }
    
    func getInProgress() async throws -> [ContentItem] {
        try await repository.getInProgress()
    }
    
    func saveProgress(_ item: ContentItem, episodeId: String? = nil, position: Double, watched: Bool) async throws {
        try await repository.saveProgress(item, episodeId: episodeId, position: position, watched: watched)
    }
    
    func touch(_ item: ContentItem) async throws {
        try await repository.touch(item)
    }
    
    func remove(id: Int) async throws {
        try await repository.remove(id: id)
    }
    
    func clearAll() async throws {
        try await repository.clearAll()
    }
}
