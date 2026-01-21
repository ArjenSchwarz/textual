# Forked Changes

This document describes the changes made to Textual to support Prism's search highlighting feature.

## Overview

This fork of [Textual](https://github.com/nicklockwood/Textual) (v0.2.1) adds search highlighting infrastructure to enable Prism's in-document search feature. The changes implement a "search on rendered text" strategy that provides accurate word-level highlighting for markdown content.

## Changes

### New Components

#### SearchHighlightAttribute
**File:** `Sources/Textual/Attributes/SearchHighlightAttribute.swift`

A custom `AttributedString` attribute that marks search matches within text. Each attribute includes:
- `isCurrent: Bool` - Distinguishes the active/focused match from other matches

The attribute conforms to `CodableAttributedStringKey`, `MarkdownDecodableAttributedStringKey`, and is `Hashable`/`Equatable` for proper identity handling.

#### SearchHighlightProperty
**File:** `Sources/Textual/TextProperty/SearchHighlightProperty.swift`

A `TextProperty` implementation that applies background colors to text marked with `SearchHighlightAttribute`. Features:
- Reads highlight colors from the environment (`searchHighlightColor` and `currentSearchHighlightColor`)
- Applies distinct colors for current vs. other matches
- Integrates seamlessly with Textual's property-based styling system

#### SearchHighlightApplicator
**File:** `Sources/Textual/Highlight/SearchHighlightApplicator.swift`

A utility that searches the plaintext representation of an `AttributedString` and applies `SearchHighlightAttribute` to all matching ranges. Key features:
- Case-insensitive search (configurable)
- Diacritic-insensitive search (configurable)
- Properly handles matches spanning formatting boundaries
- Returns both the highlighted string and match count

#### SearchHighlightEnvironment
**File:** `Sources/Textual/SearchHighlightEnvironment.swift`

Environment values and view modifiers for configuring search highlight colors:
- `searchHighlightColor` - Background color for non-current matches
- `currentSearchHighlightColor` - Background color for the current/active match
- `.searchHighlightColors(match:current:)` - View modifier for easy configuration

### Environment Key Additions

Added to `TextEnvironmentValues.swift`:
- `searchHighlightColor: Color?` - Optional color for search match highlighting
- `currentSearchHighlightColor: Color?` - Optional color for current match highlighting

## Test Coverage

Unit tests cover:
- Attribute creation, equality, hashing, and Codable conformance
- Property application with current/non-current state
- Applicator search behavior including case/diacritic sensitivity
- Multiple occurrences and repeated word handling

Test files:
- `Tests/TextualTests/SearchHighlightAttributeTests.swift`
- `Tests/TextualTests/SearchHighlightPropertyTests.swift`
- `Tests/TextualTests/SearchHighlightApplicatorTests.swift`

## Usage Example

```swift
import Textual

// Apply search highlights to markdown content
let parser = AttributedStringMarkdownParser.inlineMarkdown()
let parsed = try parser.attributedString(for: "Hello world, hello everyone!")

let result = SearchHighlightApplicator.applyHighlights(
    to: parsed,
    query: "hello",
    currentMatchIndex: 0  // First match is "current"
)

// result.highlighted contains the attributed string with highlights
// result.matchCount is 2

// In your view, configure highlight colors:
InlineText(attributedString: result.highlighted)
    .searchHighlightColors(
        match: Color.yellow.opacity(0.3),
        current: Color.yellow.opacity(0.6)
    )
```

## Compatibility

- Requires iOS 17+ / macOS 14+
- Swift 6.0 compatible
- Maintains backward compatibility with existing Textual features
