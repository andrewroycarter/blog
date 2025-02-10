import Foundation
import Markdown

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
        let htmlContent = try generatePostContentHTML(post: post)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        \(generateCommonHeadHTML(title: post.title))
        <body>
            \(generateNavigationHTML(links: [
                (href: "../../", text: "Home")
            ]))
            <main>
                <article>
                    <header>
                        <h1>\(post.title)</h1>
                        \(generateMetaHTML(post: post, basePath: "../.."))
                    </header>
                    <div class="content">
                        \(htmlContent)
                    </div>
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
        return "" // This function is no longer needed but kept for compatibility
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
        let postsHTML = try recentPosts.map { post in
            """
            <article class="post">
                <h2><a href="posts/\(post.slug)">\(post.title)</a></h2>
                \(generateMetaHTML(post: post, basePath: ""))
                <div class="content">
                    \(try generatePostContentHTML(post: post))
                </div>
            </article>
            """
        }.joined(separator: "\n")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        \(generateCommonHeadHTML(title: "Blog"))
        <body>
            \(generateNavigationHTML(links: [
                (href: "categories", text: "Categories"),
                (href: "tags", text: "Tags")
            ]))
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
        \(generateCommonHeadHTML(title: "Category: \(category)"))
        <body>
            \(generateNavigationHTML(links: [
                (href: "../../", text: "Home"),
                (href: "../", text: "Categories")
            ]))
            <h1>Posts in \(category)</h1>
            <ul class="post-list">
            \(posts.sorted { $0.date > $1.date }.map { post in
                """
                <li class="post-item">
                    <h2><a href="../../posts/\(post.slug)">\(post.title)</a></h2>
                    \(generateMetaHTML(post: post, basePath: "../.."))
                </li>
                """
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
        \(generateCommonHeadHTML(title: "Tag: \(tag)"))
        <body>
            \(generateNavigationHTML(links: [
                (href: "../../", text: "Home"),
                (href: "../", text: "Tags")
            ]))
            <h1>Posts tagged with \(tag)</h1>
            <ul class="post-list">
            \(posts.sorted { $0.date > $1.date }.map { post in
                """
                <li class="post-item">
                    <h2><a href="../../posts/\(post.slug)">\(post.title)</a></h2>
                    \(generateMetaHTML(post: post, basePath: "../.."))
                </li>
                """
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
        \(generateCommonHeadHTML(title: "Categories"))
        <body>
            \(generateNavigationHTML(links: [
                (href: "../", text: "Home")
            ]))
            <h1>Categories</h1>
            <ul class="category-list">
            \(categories.sorted().map { category in
                """
                <li class="category-item">
                    <a href="\(category)" class="category">\(category)</a>
                </li>
                """
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
        \(generateCommonHeadHTML(title: "Tags"))
        <body>
            \(generateNavigationHTML(links: [
                (href: "../", text: "Home")
            ]))
            <h1>Tags</h1>
            <ul class="tag-list">
            \(tags.sorted().map { tag in
                """
                <li class="tag-item">
                    <a href="\(tag)" class="tag">\(tag)</a>
                </li>
                """
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
        let document = Document(parsing: markdown)
        var html = ""
        var htmlVisitor = HTMLVisitor()
        htmlVisitor.visit(document)
        html = htmlVisitor.result
        return sanitizeHTML(html)
    }
    
    private func generatePostsIndex() async throws {
        let html = try generatePostsIndexHTML(posts: posts.sorted { $0.date > $1.date })
        try html.write(to: outputDirectory.appending(path: "posts/index.html"), atomically: true, encoding: .utf8)
    }
    
    private func generatePostsIndexHTML(posts: [Post]) throws -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        \(generateCommonHeadHTML(title: "All Posts"))
        <body>
            \(generateNavigationHTML(links: [
                (href: "../", text: "Home")
            ]))
            <main>
                <h1>All Posts</h1>
                <ul class="post-list">
                \(posts.map { post in
                    """
                    <li class="post-item">
                        <h2><a href="\(post.slug)">\(post.title)</a></h2>
                        \(generateMetaHTML(post: post, basePath: ".."))
                    </li>
                    """
                }.joined(separator: "\n"))
                </ul>
            </main>
            <footer>
                <p><small>Generated with Swift Blog Engine</small></p>
            </footer>
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
    
    // Helper functions for common HTML components
    private func generateNavigationHTML(links: [(href: String, text: String)]) -> String {
        return """
        <nav role="navigation" aria-label="Main navigation">
            \(links.map { "<a href=\"\($0.href)\">\($0.text)</a>" }.joined(separator: "\n            "))
        </nav>
        """
    }
    
    private func generateTagsHTML(tags: [String], basePath: String, inline: Bool = false) -> String {
        return """
        <div class="tags" role="list" style="display: \(inline ? "inline" : "inline-block")">
            \(tags.map { "<a href=\"\(basePath)/tags/\($0)\" class=\"tag\" role=\"listitem\">\($0)</a>" }.joined())
        </div>
        """
    }
    
    private func generateCategoriesHTML(categories: [String], basePath: String, inline: Bool = false) -> String {
        return """
        <div class="categories" role="list" style="display: \(inline ? "inline" : "inline-block")">
            \(categories.map { "<a href=\"\(basePath)/categories/\($0)\" class=\"category\" role=\"listitem\">\($0)</a>" }.joined())
        </div>
        """
    }
    
    private func generateUpdatesHTML(updates: [Update]) -> String {
        let sortedUpdates = updates.sorted { $0.date > $1.date }
        return """
        <div class="update-list">
            \(sortedUpdates.map { update in
                """
                <div class="update-item">Updated \(formatDate(update.date)): \(update.description)</div>
                """
            }.joined(separator: "\n"))
        </div>
        """
    }
    
    private func generateMetaHTML(post: Post, basePath: String) -> String {
        let hasUpdates = !post.updates.isEmpty
        return """
        <div class="meta">
            <div class="meta-item">
                <span class="meta-label">Published:</span>
                <time datetime="\(post.date.ISO8601Format())">\(formatDate(post.date))</time>
                \(hasUpdates ? generateUpdatesHTML(updates: post.updates) : "")
            </div>
            <div class="meta-item">
                <span class="meta-label">Categories:</span>
                \(generateCategoriesHTML(categories: post.categories, basePath: basePath, inline: true))
            </div>
            <div class="meta-item">
                <span class="meta-label">Tags:</span>
                \(generateTagsHTML(tags: post.tags, basePath: basePath, inline: true))
            </div>
        </div>
        """
    }
    
    private func generatePostContentHTML(post: Post) throws -> String {
        return try sanitizeHTML(markdownToHTML(post.content))
    }
    
    private func generateCommonCSS() -> String {
        return """
            :root {
                color-scheme: light dark;
            }
            body {
                font-family: system-ui, -apple-system, sans-serif;
                line-height: 1.6;
                max-width: 800px;
                margin: 0 auto;
                padding: 2rem;
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
            .update-list {
                margin: 0.5rem 0;
                font-size: 0.9rem;
                color: #666;
            }
            .update-item {
                margin: 0.25rem 0;
            }
            .post-list {
                list-style: none;
                padding: 0;
            }
            .post-item {
                margin-bottom: 2rem;
                padding-bottom: 2rem;
                border-bottom: 1px solid #eee;
            }
            .post-item:last-child {
                border-bottom: none;
            }
            .tags, .categories {
                margin-right: 1rem;
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
            .tag-list, .category-list {
                list-style: none;
                padding: 0;
            }
            .tag-item, .category-item {
                margin: 0.5rem 0;
            }
            nav {
                margin-bottom: 2rem;
            }
            nav a {
                margin-right: 1rem;
                padding: 0.5rem 0;
            }
            a {
                color: #0366d6;
                text-decoration: none;
            }
            a:hover {
                text-decoration: underline;
            }
            a:visited {
                color: #6f42c1;
            }
            pre {
                background: #f6f8fa;
                padding: 1rem;
                border-radius: 6px;
                overflow-x: auto;
                margin: 1.5rem 0;
            }
            code {
                font-family: ui-monospace, monospace;
                font-size: 0.9em;
                padding: 0.2em 0.4em;
                background: rgba(175, 184, 193, 0.2);
                border-radius: 3px;
            }
            pre code {
                padding: 0;
                background: none;
            }
            .content {
                margin-top: 2rem;
            }
            .content h1 {
                margin-top: 2rem;
                margin-bottom: 1rem;
                padding-bottom: 0.3rem;
                border-bottom: 1px solid #eee;
            }
            .content h2 {
                margin-top: 1.5rem;
                margin-bottom: 1rem;
            }
            .content h3, .content h4, .content h5, .content h6 {
                margin-top: 1.5rem;
                margin-bottom: 0.5rem;
            }
            .content ul, .content ol {
                padding-left: 2rem;
                margin: 1rem 0;
            }
            .content li {
                margin: 0.5rem 0;
            }
            .content ul ul, .content ol ol, .content ul ol, .content ol ul {
                margin: 0.5rem 0;
            }
            .content p {
                margin: 1rem 0;
            }
            .content blockquote {
                margin: 1rem 0;
                padding: 0.5rem 1rem;
                border-left: 0.25rem solid #ddd;
                color: #666;
                background: rgba(175, 184, 193, 0.1);
            }
            .content blockquote > :first-child {
                margin-top: 0;
            }
            .content blockquote > :last-child {
                margin-bottom: 0;
            }
            .update-badge {
                display: inline-block;
                padding: 0.2rem 0.5rem;
                margin: 0 0.5rem;
                background: #f0ad4e;
                color: #fff;
                border-radius: 3px;
                font-size: 0.8rem;
            }
            .content hr {
                height: 0.25rem;
                padding: 0;
                margin: 1.5rem 0;
                background-color: #e1e4e8;
                border: 0;
            }
            .content table {
                border-spacing: 0;
                border-collapse: collapse;
                margin: 1.5rem 0;
                width: 100%;
                font-size: 0.9rem;
            }
            .content table th {
                font-weight: 600;
                background-color: #f6f8fa;
                text-align: left;
                padding: 0.75rem 1rem;
                border: 1px solid #e1e4e8;
            }
            .content table td {
                padding: 0.75rem 1rem;
                border: 1px solid #e1e4e8;
                vertical-align: top;
            }
            .content table tr:nth-child(even) {
                background-color: #f8f9fa;
            }
            .content table tr:hover {
                background-color: #f1f2f3;
            }
            .content img {
                max-width: 100%;
                height: auto;
                margin: 1rem 0;
            }
            .content input[type="checkbox"] {
                margin-right: 0.5rem;
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
                .update-list {
                    color: #999;
                }
                .update-item {
                    color: #999;
                }
                .post-item {
                    border-bottom-color: #333;
                }
                pre {
                    background: #2d2d2d;
                }
                code {
                    background: rgba(110, 118, 129, 0.4);
                }
                pre code {
                    background: none;
                }
                .content h1 {
                    border-bottom-color: #333;
                }
                .content blockquote {
                    border-left-color: #444;
                    color: #999;
                    background: rgba(110, 118, 129, 0.1);
                }
                a {
                    color: #58a6ff;
                }
                a:visited {
                    color: #bc8cff;
                }
                .update-badge {
                    background: #b86e00;
                }
                .content hr {
                    background-color: #333;
                }
                .content table th {
                    background-color: #2d2d2d;
                    border-color: #404040;
                }
                .content table td {
                    border-color: #404040;
                }
                .content table tr:nth-child(even) {
                    background-color: #252525;
                }
                .content table tr:hover {
                    background-color: #303030;
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
                .content table {
                    display: block;
                    overflow-x: auto;
                    -webkit-overflow-scrolling: touch;
                }
            }
        """
    }
    
    private func generateCommonHeadHTML(title: String) -> String {
        return """
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(title)</title>
            <style>
                \(generateCommonCSS())
            </style>
        </head>
        """
    }
}

struct HTMLVisitor: MarkupWalker {
    private(set) var result = ""
    
    mutating func visitDocument(_ document: Document) {
        document.children.forEach { child in
            visit(child)
        }
    }
    
    mutating func visitHeading(_ heading: Heading) {
        result += "<h\(heading.level)>"
        heading.children.forEach { child in
            visit(child)
        }
        result += "</h\(heading.level)>"
    }
    
    mutating func visitParagraph(_ paragraph: Paragraph) {
        result += "<p>"
        paragraph.children.forEach { child in
            visit(child)
        }
        result += "</p>"
    }
    
    mutating func visitText(_ text: Text) {
        result += text.string
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += "<em>"
        emphasis.children.forEach { child in
            visit(child)
        }
        result += "</em>"
    }
    
    mutating func visitStrong(_ strong: Strong) {
        result += "<strong>"
        strong.children.forEach { child in
            visit(child)
        }
        result += "</strong>"
    }
    
    mutating func visitLink(_ link: Link) {
        result += "<a href=\"\(link.destination ?? "")\">"
        link.children.forEach { child in
            visit(child)
        }
        result += "</a>"
    }
    
    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += "<code>\(inlineCode.code)</code>"
    }
    
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let language = codeBlock.language ?? ""
        result += "<pre><code class=\"language-\(language)\">"
        result += codeBlock.code
        result += "</code></pre>"
    }
    
    mutating func visitListItem(_ listItem: ListItem) {
        result += "<li>"
        listItem.children.forEach { child in
            visit(child)
        }
        result += "</li>"
    }
    
    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        result += "<ul>"
        unorderedList.children.forEach { child in
            visit(child)
        }
        result += "</ul>"
    }
    
    mutating func visitOrderedList(_ orderedList: OrderedList) {
        result += "<ol>"
        orderedList.children.forEach { child in
            visit(child)
        }
        result += "</ol>"
    }
    
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result += "<blockquote>"
        blockQuote.children.forEach { child in
            visit(child)
        }
        result += "</blockquote>"
    }
    
    mutating func visitTable(_ table: Table) {
        result += "<table><thead><tr>"
        // Visit header cells
        for cell in table.head.cells {
            result += "<th>"
            cell.children.forEach { visit($0) }
            result += "</th>"
        }
        result += "</tr></thead><tbody>"
        
        // Visit body rows
        for row in table.body.rows {
            result += "<tr>"
            for cell in row.cells {
                result += "<td>"
                cell.children.forEach { visit($0) }
                result += "</td>"
            }
            result += "</tr>"
        }
        result += "</tbody></table>"
    }
    
    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "<hr>"
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < endIndex else { return nil }
        return self[index]
    }
} 