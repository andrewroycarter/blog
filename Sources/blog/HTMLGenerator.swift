import Foundation

public struct HTMLGenerationError: LocalizedError, Sendable {
    let message: String
    
    public var errorDescription: String? {
        message
    }
}

public struct HTMLGenerator: Sendable {
    private let outputDirectory: URL
    private let posts: [Post]
    
    public init(outputDirectory: URL, posts: [Post]) {
        self.outputDirectory = outputDirectory
        self.posts = posts
    }
    
    public func generate() async throws {
        // Create required directories
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputDirectory.appending(path: "posts"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputDirectory.appending(path: "categories"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputDirectory.appending(path: "tags"), withIntermediateDirectories: true)
        
        // Generate all content concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Generate individual post pages
            for post in posts {
                group.addTask {
                    try await self.generatePost(post)
                }
            }
            
            // Generate index pages
            group.addTask {
                try await self.generateHomePage()
            }
            
            group.addTask {
                try await self.generateCategoryPages()
            }
            
            group.addTask {
                try await self.generateTagPages()
            }
            
            group.addTask {
                try await self.generatePostsIndex()
            }
            
            // Wait for all tasks to complete
            try await group.waitForAll()
        }
    }
    
    private func generatePost(_ post: Post) async throws {
        let postDir = outputDirectory.appending(path: "posts").appending(path: post.slug)
        try FileManager.default.createDirectory(at: postDir, withIntermediateDirectories: true)
        
        let html = try generatePostHTML(post)
        try html.write(to: postDir.appending(path: "index.html"), atomically: true, encoding: .utf8)
    }
    
    private func generatePostHTML(_ post: Post) throws -> String {
        let htmlContent = try sanitizeHTML(markdownToHTML(post.content))
        let updatesHTML = generateUpdatesHTML(post.updates)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="description" content="Article about \(post.title)">
            <title>\(post.title)</title>
            <style>
                :root {
                    color-scheme: light dark;
                }
                body {
                    font-family: system-ui, -apple-system, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 1rem;
                    font-size: 16px;
                }
                @media (min-width: 640px) {
                    body {
                        padding: 2rem;
                        font-size: 18px;
                    }
                }
                .meta {
                    color: #666;
                    margin-bottom: 2rem;
                }
                .meta-item {
                    margin: 0.5rem 0;
                }
                .meta-label {
                    display: inline-block;
                    min-width: 5rem;
                    color: #444;
                }
                .tags, .categories {
                    display: inline;
                }
                .tag, .category {
                    display: inline-block;
                    padding: 0.2rem 0.5rem;
                    margin: 0.2rem;
                    background: #eee;
                    border-radius: 3px;
                    font-size: 0.9rem;
                    transition: background-color 0.2s;
                }
                .tag:hover, .category:hover {
                    background: #ddd;
                }
                .updates {
                    margin-top: 3rem;
                    padding-top: 1rem;
                    border-top: 1px solid #eee;
                }
                .update-item {
                    margin: 1rem 0;
                }
                .update-date {
                    font-size: 0.9rem;
                    color: #666;
                }
                pre {
                    background: #f6f8fa;
                    padding: 1rem;
                    border-radius: 6px;
                    overflow-x: auto;
                    max-width: 100%;
                }
                code {
                    font-family: ui-monospace, monospace;
                    font-size: 0.9em;
                }
                img {
                    max-width: 100%;
                    height: auto;
                }
                a {
                    color: #0366d6;
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
                }
                nav {
                    margin-bottom: 2rem;
                }
                nav a {
                    margin-right: 1rem;
                    padding: 0.5rem 0;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #1a1a1a;
                        color: #e6e6e6;
                    }
                    .meta {
                        color: #999;
                    }
                    .meta-label {
                        color: #bbb;
                    }
                    .tag, .category {
                        background: #333;
                    }
                    .tag:hover, .category:hover {
                        background: #444;
                    }
                    pre {
                        background: #2d2d2d;
                    }
                    a {
                        color: #58a6ff;
                    }
                    .updates {
                        border-top-color: #333;
                    }
                    .update-date {
                        color: #999;
                    }
                }
                @media (max-width: 480px) {
                    .meta-item {
                        margin: 1rem 0;
                    }
                    .meta-label {
                        display: block;
                        margin-bottom: 0.25rem;
                    }
                }
            </style>
        </head>
        <body>
            <nav role="navigation" aria-label="Main navigation">
                <a href="../../" aria-label="Return to homepage">Home</a>
            </nav>
            <main>
                <article>
                    <header>
                        <h1>\(post.title)</h1>
                        <div class="meta">
                            <div class="meta-item">
                                <span class="meta-label">Published:</span>
                                <time datetime="\(post.date.ISO8601Format())">\(formatDate(post.date))</time>
                            </div>
                            <div class="meta-item">
                                <span class="meta-label">Categories:</span>
                                <div class="categories" role="list">
                                    \(post.categories.map { "<a href=\"../../categories/\($0)\" class=\"category\" role=\"listitem\">\($0)</a>" }.joined())
                                </div>
                            </div>
                            <div class="meta-item">
                                <span class="meta-label">Tags:</span>
                                <div class="tags" role="list">
                                    \(post.tags.map { "<a href=\"../../tags/\($0)\" class=\"tag\" role=\"listitem\">\($0)</a>" }.joined())
                                </div>
                            </div>
                        </div>
                    </header>
                    <div class="content">
                        \(htmlContent)
                    </div>
                    \(updatesHTML)
                </article>
            </main>
            <footer>
                <p><small>Generated with Swift Blog Engine</small></p>
            </footer>
        </body>
        </html>
        """
    }
    
    private func generateUpdatesHTML(_ updates: [Update]) -> String {
        guard !updates.isEmpty else { return "" }
        
        let sortedUpdates = updates.sorted { $0.date > $1.date }
        let updatesListHTML = sortedUpdates.map { update in
            """
            <div class="update-item">
                <time class="update-date" datetime="\(update.date.ISO8601Format())">\(formatDate(update.date))</time>
                <div class="update-description">\(update.description)</div>
            </div>
            """
        }.joined()
        
        return """
        <section class="updates">
            <h2>Updates</h2>
            \(updatesListHTML)
        </section>
        """
    }
    
    private func generatePostPreviewHTML(_ post: Post, showFullContent: Bool = false) throws -> String {
        let content = try sanitizeHTML(markdownToHTML(post.content))
        let hasUpdates = !post.updates.isEmpty
        let latestUpdate = post.updates.max(by: { $0.date < $1.date })
        
        return """
        <article class="post">
            <h2><a href="posts/\(post.slug)">\(post.title)</a></h2>
            <div class="meta">
                <time datetime="\(post.date.ISO8601Format())">\(formatDate(post.date))</time>
                \(hasUpdates ? "<span class=\"update-badge\" title=\"Last updated \(formatDate(latestUpdate!.date))\">Updated</span>" : "")
                <div class="categories">
                    \(post.categories.map { "<a href=\"categories/\($0)\" class=\"category\">\($0)</a>" }.joined())
                </div>
                <div class="tags">
                    \(post.tags.map { "<a href=\"tags/\($0)\" class=\"tag\">\($0)</a>" }.joined())
                </div>
            </div>
            <div class="content">
                \(showFullContent ? content : content.prefix(500) + "...")
            </div>
        </article>
        """
    }
    
    private func generateHomePage() async throws {
        let sortedPosts = posts.sorted { $0.date > $1.date }
        let recentPosts = Array(sortedPosts.prefix(3))
        
        let html = try generateHomePageHTML(recentPosts)
        try html.write(to: outputDirectory.appending(path: "index.html"), atomically: true, encoding: .utf8)
    }
    
    private func generateHomePageHTML(_ recentPosts: [Post]) throws -> String {
        let postsHTML = try recentPosts.map { post in """
            <article class="post">
                <h2><a href="posts/\(post.slug)">\(post.title)</a></h2>
                <div class="meta">
                    <time datetime="\(post.date.ISO8601Format())">\(formatDate(post.date))</time>
                    <div class="categories">
                        \(post.categories.map { "<a href=\"categories/\($0)\" class=\"category\">\($0)</a>" }.joined())
                    </div>
                    <div class="tags">
                        \(post.tags.map { "<a href=\"tags/\($0)\" class=\"tag\">\($0)</a>" }.joined())
                    </div>
                </div>
                <div class="content">
                    \(try sanitizeHTML(markdownToHTML(post.content)))
                </div>
            </article>
        """
        }.joined(separator: "\n")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Blog</title>
            <style>
                body {
                    font-family: system-ui, -apple-system, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 2rem;
                }
                .post {
                    margin-bottom: 4rem;
                    padding-bottom: 4rem;
                    border-bottom: 1px solid #eee;
                }
                .post:last-child {
                    border-bottom: none;
                }
                .meta {
                    color: #666;
                    margin-bottom: 2rem;
                }
                .tags, .categories {
                    display: inline-block;
                    margin-right: 1rem;
                }
                .tag, .category {
                    display: inline-block;
                    padding: 0.2rem 0.5rem;
                    margin: 0.2rem;
                    background: #eee;
                    border-radius: 3px;
                    font-size: 0.9rem;
                }
                nav {
                    margin-bottom: 2rem;
                }
                nav a {
                    margin-right: 1rem;
                }
                pre {
                    background: #f6f8fa;
                    padding: 1rem;
                    border-radius: 6px;
                    overflow-x: auto;
                }
                code {
                    font-family: ui-monospace, monospace;
                    font-size: 0.9em;
                }
            </style>
        </head>
        <body>
            <nav role="navigation" aria-label="Main navigation">
                <a href="categories">Categories</a>
                <a href="tags">Tags</a>
            </nav>
            <h1>Recent Posts</h1>
            \(postsHTML)
            <p><a href="posts">View all posts</a></p>
        </body>
        </html>
        """
    }
    
    private func generateCategoryPages() async throws {
        // Group posts by category
        var categorizedPosts: [String: [Post]] = [:]
        for post in posts {
            for category in post.categories {
                categorizedPosts[category, default: []].append(post)
            }
        }
        
        // Generate individual category pages
        for (category, posts) in categorizedPosts {
            let categoryDir = outputDirectory.appending(path: "categories").appending(path: category)
            try FileManager.default.createDirectory(at: categoryDir, withIntermediateDirectories: true)
            
            let html = try generateCategoryHTML(category: category, posts: posts)
            try html.write(to: categoryDir.appending(path: "index.html"), atomically: true, encoding: .utf8)
        }
        
        // Generate categories index
        let indexHTML = try generateCategoriesIndexHTML(categories: Array(categorizedPosts.keys))
        try indexHTML.write(to: outputDirectory.appending(path: "categories/index.html"), atomically: true, encoding: .utf8)
    }
    
    private func generateTagPages() async throws {
        // Group posts by tag
        var taggedPosts: [String: [Post]] = [:]
        for post in posts {
            for tag in post.tags {
                taggedPosts[tag, default: []].append(post)
            }
        }
        
        // Generate individual tag pages
        for (tag, posts) in taggedPosts {
            let tagDir = outputDirectory.appending(path: "tags").appending(path: tag)
            try FileManager.default.createDirectory(at: tagDir, withIntermediateDirectories: true)
            
            let html = try generateTagHTML(tag: tag, posts: posts)
            try html.write(to: tagDir.appending(path: "index.html"), atomically: true, encoding: .utf8)
        }
        
        // Generate tags index
        let indexHTML = try generateTagsIndexHTML(tags: Array(taggedPosts.keys))
        try indexHTML.write(to: outputDirectory.appending(path: "tags/index.html"), atomically: true, encoding: .utf8)
    }
    
    private func generateCategoryHTML(category: String, posts: [Post]) throws -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Category: \(category)</title>
            <style>
                body {
                    font-family: system-ui, -apple-system, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 2rem;
                }
            </style>
        </head>
        <body>
            <nav role="navigation" aria-label="Main navigation">
                <a href="../../">Home</a>
                <a href="../">Categories</a>
            </nav>
            <h1>Posts in \(category)</h1>
            <ul>
            \(posts.sorted { $0.date > $1.date }.map { post in
                "<li><a href=\"../../posts/\(post.slug)\">\(post.title)</a> - \(formatDate(post.date))</li>"
            }.joined(separator: "\n"))
            </ul>
        </body>
        </html>
        """
    }
    
    private func generateTagHTML(tag: String, posts: [Post]) throws -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Tag: \(tag)</title>
            <style>
                body {
                    font-family: system-ui, -apple-system, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 2rem;
                }
            </style>
        </head>
        <body>
            <nav role="navigation" aria-label="Main navigation">
                <a href="../../">Home</a>
                <a href="../">Tags</a>
            </nav>
            <h1>Posts tagged with \(tag)</h1>
            <ul>
            \(posts.sorted { $0.date > $1.date }.map { post in
                "<li><a href=\"../../posts/\(post.slug)\">\(post.title)</a> - \(formatDate(post.date))</li>"
            }.joined(separator: "\n"))
            </ul>
        </body>
        </html>
        """
    }
    
    private func generateCategoriesIndexHTML(categories: [String]) throws -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Categories</title>
            <style>
                body {
                    font-family: system-ui, -apple-system, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 2rem;
                }
            </style>
        </head>
        <body>
            <nav role="navigation" aria-label="Main navigation">
                <a href="../">Home</a>
            </nav>
            <h1>Categories</h1>
            <ul>
            \(categories.sorted().map { category in
                "<li><a href=\"\(category)\">\(category)</a></li>"
            }.joined(separator: "\n"))
            </ul>
        </body>
        </html>
        """
    }
    
    private func generateTagsIndexHTML(tags: [String]) throws -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Tags</title>
            <style>
                body {
                    font-family: system-ui, -apple-system, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 2rem;
                }
            </style>
        </head>
        <body>
            <nav role="navigation" aria-label="Main navigation">
                <a href="../">Home</a>
            </nav>
            <h1>Tags</h1>
            <ul>
            \(tags.sorted().map { tag in
                "<li><a href=\"\(tag)\">\(tag)</a></li>"
            }.joined(separator: "\n"))
            </ul>
        </body>
        </html>
        """
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func markdownToHTML(_ markdown: String) throws -> String {
        // For now, let's do some basic Markdown parsing
        // We'll replace this with a proper Markdown parser later
        var html = markdown
        
        // Process the text line by line for headers and lists
        var lines = html.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var inCodeBlock = false
        
        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    processedLines.append("</code></pre>")
                    inCodeBlock = false
                } else {
                    let language = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    processedLines.append("<pre><code class=\"language-\(language)\">")
                    inCodeBlock = true
                }
                continue
            }
            
            if inCodeBlock {
                processedLines.append(line)
                continue
            }
            
            // Headers
            if line.hasPrefix("# ") {
                processedLines.append("<h1>\(line.dropFirst(2))</h1>")
            } else if line.hasPrefix("## ") {
                processedLines.append("<h2>\(line.dropFirst(3))</h2>")
            } else if line.hasPrefix("### ") {
                processedLines.append("<h3>\(line.dropFirst(4))</h3>")
            }
            // Lists
            else if line.hasPrefix("- ") {
                processedLines.append("<li>\(line.dropFirst(2))</li>")
            } else if let match = line.firstMatch(of: /^[0-9]+\. (.+)$/) {
                processedLines.append("<li>\(match.1)</li>")
            } else {
                processedLines.append(line)
            }
        }
        
        html = processedLines.joined(separator: "\n")
        
        // Wrap lists
        lines = html.components(separatedBy: .newlines)
        var inList = false
        var listType = ""
        var result: [String] = []
        
        for line in lines {
            if line.starts(with: "<li>") {
                if !inList {
                    inList = true
                    listType = line.contains("<li>1") ? "ol" : "ul"
                    result.append("<\(listType)>")
                }
                result.append(line)
            } else {
                if inList {
                    inList = false
                    result.append("</\(listType)>")
                }
                result.append(line)
            }
        }
        
        if inList {
            result.append("</\(listType)>")
        }
        
        html = result.joined(separator: "\n")
        
        // Paragraphs
        html = html.components(separatedBy: "\n\n").map { para in
            let trimmed = para.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("<") {
                return "<p>\(para)</p>"
            }
            return para
        }.joined(separator: "\n\n")
        
        // Inline formatting
        html = html.replacingOccurrences(of: "`([^`]+)`", with: "<code>$1</code>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"\*\*([^\*]+)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        
        return html
    }
    
    private func generatePostsIndex() async throws {
        let html = try generatePostsIndexHTML(posts: posts.sorted { $0.date > $1.date })
        try html.write(to: outputDirectory.appending(path: "posts/index.html"), atomically: true, encoding: .utf8)
    }
    
    private func generatePostsIndexHTML(posts: [Post]) throws -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>All Posts</title>
            <style>
                body {
                    font-family: system-ui, -apple-system, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 2rem;
                }
                .post-list {
                    list-style: none;
                    padding: 0;
                }
                .post-item {
                    margin-bottom: 1.5rem;
                }
                .post-meta {
                    color: #666;
                    font-size: 0.9rem;
                    margin-top: 0.5rem;
                }
                .tags, .categories {
                    display: inline-block;
                    margin-right: 1rem;
                }
                .tag, .category {
                    display: inline-block;
                    padding: 0.2rem 0.5rem;
                    margin: 0.2rem;
                    background: #eee;
                    border-radius: 3px;
                    font-size: 0.9rem;
                }
                nav {
                    margin-bottom: 2rem;
                }
                nav a {
                    margin-right: 1rem;
                }
            </style>
        </head>
        <body>
            <nav>
                <a href="../">Home</a>
            </nav>
            <h1>All Posts</h1>
            <ul class="post-list">
            \(posts.map { post in """
                <li class="post-item">
                    <h2><a href="\(post.slug)">\(post.title)</a></h2>
                    <div class="post-meta">
                        <time datetime="\(post.date.ISO8601Format())">\(formatDate(post.date))</time>
                        <div class="categories">
                            \(post.categories.map { "<a href=\"../categories/\($0)\" class=\"category\">\($0)</a>" }.joined())
                        </div>
                        <div class="tags">
                            \(post.tags.map { "<a href=\"../tags/\($0)\" class=\"tag\">\($0)</a>" }.joined())
                        </div>
                    </div>
                </li>
            """
            }.joined(separator: "\n"))
            </ul>
        </body>
        </html>
        """
    }
    
    private func sanitizeHTML(_ html: String) -> String {
        // Basic HTML sanitization - remove script tags and their content
        let scriptPattern = "<script[^>]*>.*?</script>"
        let sanitized = html.replacingOccurrences(of: scriptPattern, with: "", options: [.regularExpression, .caseInsensitive])
        return sanitized
    }
} 