protocol ImageRepositoryProtocol {
    /// Applies memory limit for the image cache.
    func applyCacheLimit(bytes: Int)
    
    /// Returns disk cache size in bytes.
    func diskCacheSizeBytes() -> Int64
    
    /// Clears both memory and disk image cache.
    func clearDiskCache() throws
}
