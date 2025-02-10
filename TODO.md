# Personal Blog Platform Feature Roadmap

## MVP Iteration 1: Basic Static Site ✅

- [x] **Static Site Generation**
  - [x] Set up a basic Swift package structure for a command line tool
    - [x] Initialize a new Swift package using `swift package init --type executable`
    - [x] Define the main entry point for the command line tool
    - [x] Added ArgumentParser for clean CLI interface
    - [x] Created modular structure with separate `blog` library and `cli` executable
    - [x] Added initial test infrastructure with Swift Testing framework for Linux compatibility
    - [x] Modernized test suite to use latest Swift Testing patterns
      - [x] Migrated from XCTest to Swift Testing framework
      - [x] Updated test lifecycle management using class init/deinit
      - [x] Improved test cleanup and resource management
      - [x] Ensured proper async/await handling in tests
    - [x] Added post update tracking
      - [x] Added updates metadata to posts
      - [x] Display updates chronologically at bottom of posts
      - [x] Show update indicators in post lists
      - [x] Added tests for update functionality
    - [x] Improved Markdown support
      - [x] Added proper table support with responsive design
      - [x] Enhanced styling for all Markdown elements
      - [x] Added dark mode support for all elements
      - [x] Improved accessibility with semantic HTML

- [x] **Content Structure**
  - [x] Setup Swift tool to run pointed at a directory of posts
    - [x] The directory of posts contains more directories representing each post
    - [x] The directory name of the post is the slug
    - [x] The post directory contains a `content.md` file for the post content
    - [x] The post directory contains a `meta.json` file for the post metadata
        - [x] Created `Post` model with all required metadata fields:
            - [x] `title`: The title of the post
            - [x] `date`: The date of the post (supports both YYYY-MM-DD and ISO8601 formats)
            - [x] `tags`: The tags of the post
            - [x] `categories`: The category
            - [x] Added JSON encoding/decoding support for metadata
        - [x] Added robust error handling for missing or invalid files
        - [x] Implemented concurrent post loading for better performance
  - [x] When compiled to a static site, the tool should create a `posts/` directory with a subdirectory for each post
  - [x] When compiled to a static site, the tool should create a `categories/` directory with a subdirectory for each category
  - [x] When compiled to a static site, the tool should create a `tags/` directory with a subdirectory for each tag
  - [x] Both categories and tags pages should have an index as well as a page per category/tag
  - [x] When compiling a post to static HTML, the HTML should use no JavaScript or CSS frameworks

- [x] **Homepage**
  - [x] When compiled to a static site, the tool should create an `index.html` file in the root of the static site
  - [x] It should show the latest 3 posts on the homepage, divided by a divider
  - [x] Add a "more" link to navigate to a full index of posts
  - [x] It should have a header with a title and navigation to categories and tags

## MVP Iteration 2: Continuous Integration ✅

- [x] **GitHub Actions**
  - [x] Write a GitHub Action to build the static site as a zip artifact on PR creation
    - [x] Use a Linux runner for compatibility
    - [x] Ensure the action checks out the code and runs the Swift build
  - [x] Write a GitHub Action to build the static site as a zip artifact on a push to main
    - [x] Create GitHub release with the artifact
    - [x] Use the same Linux environment as PR checks
    - [x] Include automated testing in the pipeline

## Future Improvements

- [ ] **Testing Enhancements**
  - [ ] Add performance tests for concurrent post loading
  - [ ] Add more comprehensive accessibility tests
  - [ ] Consider adding snapshot tests for HTML output
  - [ ] Add test coverage reporting

- [ ] **Feature Enhancements**
  - [ ] Add RSS feed generation
  - [ ] Add sitemap.xml generation
  - [ ] Add code syntax highlighting
  - [ ] Add support for custom themes
  - [ ] Add support for draft posts
  - [ ] Add support for scheduled posts

## For all features

- [x] **Swift Compatibility**
  - [x] Ensure all Swift code is compatible with Linux
    - [x] Using standard Foundation types for cross-platform compatibility
    - [x] Avoiding platform-specific APIs
    - [x] Added platform requirement of macOS 13+ for modern Swift features
    - [x] Using Swift Testing framework for testing to ensure Linux compatibility

## Implementation Notes
- Using ArgumentParser for a clean, type-safe CLI interface
- Separated core blog engine logic into a library target for better testing and potential reuse
- Implemented concurrency-safe code from the start
- Using JSON for metadata for easy parsing and human readability
- Following Swift best practices with immutable properties where possible
- Added robust error handling for file operations
- Implemented concurrent post loading using Swift's structured concurrency
- Supporting flexible date formats (YYYY-MM-DD and ISO8601) for better user experience
- Using value types (structs) for thread safety and immutability
- All types conform to Sendable for concurrency safety
- HTML generation features:
  - Clean, responsive design with system fonts and no JavaScript
  - Concurrent generation of all pages for better performance
  - Proper HTML5 semantic markup
  - Organized directory structure with clean URLs
  - Category and tag pages with indexes
  - Recent posts on homepage with "View all" link
  - Proper metadata with dates in both human-readable and machine formats
  - Full Markdown support with proper styling
  - Dark mode support for all elements
  - Responsive design for mobile devices
  - Accessibility improvements with ARIA roles and semantic HTML
