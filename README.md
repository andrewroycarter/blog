# Swift Blog Engine

A static blog generator written in Swift that creates a clean, fast, and accessible blog with no JavaScript dependencies.

## Features

- 🚀 Fast, concurrent static site generation
- 📱 Responsive design that works on all devices
- 🌓 Automatic dark mode support
- ♿️ Accessibility-first approach with semantic HTML
- 🏷️ Support for categories and tags
- 📝 Full Markdown support
- 🔄 Post update tracking
- 🖥️ Cross-platform (macOS and Linux compatible)

## Requirements

- Swift 6.0 or later
- macOS 13+ or Linux

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/blog.git
cd blog
```

2. Build the project:
```bash
swift build
```

## Usage

### Running the Blog

1. Build and serve the blog locally:
```bash
./serve.sh
```

2. Or manually build the site:
```bash
swift run blog build
```

The static site will be generated in the `public` directory.

### Writing Posts

Each post consists of two files in a directory under `posts/`:

```
posts/
  my-post-slug/
    content.md    # The post content in Markdown
    meta.json     # Post metadata
```

#### Metadata Format (meta.json)

```json
{
    "title": "My Post Title",
    "date": "2024-02-10",  // YYYY-MM-DD or ISO8601 format
    "tags": ["swift", "programming"],
    "categories": ["development"],
    "updates": [  // Optional
        {
            "date": "2024-02-11T09:30:00Z",
            "description": "Added new section about feature X"
        }
    ]
}
```

#### Content Format (content.md)

The content file supports standard Markdown with all common features:

- Headers (# to ######)
- Bold and italic text
- Links and images
- Lists (ordered and unordered)
- Code blocks with language specification
- Tables
- Blockquotes
- Horizontal rules
- Task lists

Example:
```markdown
# My Post Title

This is a paragraph with **bold** and *italic* text.

## Code Example

\```swift
func hello() {
    print("Hello, World!")
}
\```

## Table Example

| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |
```

### Directory Structure

```
.
├── Package.swift           # Swift package definition
├── README.md              # This file
├── Sources/               # Source code
│   ├── blog/             # Core library
│   └── cli/              # Command-line interface
├── Tests/                # Test suite
├── posts/                # Blog posts
└── public/               # Generated static site
```

## Development

### Running Tests

```bash
swift test
```

### Project Structure

- `Sources/blog/`: Core library containing the blog engine
  - `Post.swift`: Post model and related types
  - `PostLoader.swift`: Handles loading and parsing posts
  - `HTMLGenerator.swift`: Generates static HTML files

- `Sources/cli/`: Command-line interface
  - `main.swift`: Entry point and command definitions

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 