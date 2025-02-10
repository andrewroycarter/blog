import Foundation

public struct PostLoadError: LocalizedError, Sendable {
    let message: String
    
    public var errorDescription: String? {
        message
    }
}

public struct PostMetadata: Codable, Sendable {
    let title: String
    let date: String
    let tags: [String]
    let categories: [String]
}

public struct PostLoader: Sendable {
    private let postsDirectory: URL
    
    public init(postsDirectory: URL) {
        self.postsDirectory = postsDirectory
    }
    
    private static func parseDate(_ dateString: String) throws -> Date {
        // Expected format: "YYYY-MM-DD" or "YYYY-MM-DDTHH:mm:ssZ"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if dateString.contains("T") {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
        }
        
        guard let date = formatter.date(from: dateString) else {
            throw PostLoadError(message: "Invalid date format. Expected YYYY-MM-DD or YYYY-MM-DDTHH:mm:ssZ")
        }
        
        return date
    }
    
    public func loadPosts() async throws -> [Post] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: postsDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        )
        
        return try await withThrowingTaskGroup(of: Post.self) { group in
            for url in contents {
                let isDirectory = try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false
                if isDirectory {
                    let urlCopy = url // Capture value type
                    group.addTask {
                        try await self.loadPost(from: urlCopy)
                    }
                }
            }
            
            var posts: [Post] = []
            for try await post in group {
                posts.append(post)
            }
            return posts
        }
    }
    
    private func loadPost(from directory: URL) async throws -> Post {
        let metadataURL = directory.appending(path: "meta.json")
        let contentURL = directory.appending(path: "content.md")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path()) else {
            throw PostLoadError(message: "Missing meta.json in \(directory.lastPathComponent)")
        }
        
        guard FileManager.default.fileExists(atPath: contentURL.path()) else {
            throw PostLoadError(message: "Missing content.md in \(directory.lastPathComponent)")
        }
        
        let metadataData = try Data(contentsOf: metadataURL)
        let metadata = try JSONDecoder().decode(PostMetadata.self, from: metadataData)
        
        let content = try String(contentsOf: contentURL, encoding: .utf8)
        let date = try Self.parseDate(metadata.date)
        
        return Post(
            title: metadata.title,
            date: date,
            tags: metadata.tags,
            categories: metadata.categories,
            slug: directory.lastPathComponent,
            content: content
        )
    }
} 