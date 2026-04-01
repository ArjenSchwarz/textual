# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `SearchHighlightAttribute` - Custom AttributedString attribute for marking search match ranges with `isCurrent` flag to distinguish active match
- `SearchHighlightProperty` - TextProperty conforming type that applies search highlight background colors based on environment
- `SearchHighlightApplicator` - Utility to search rendered AttributedString content and apply highlight attributes to all matching ranges
- Search highlight environment extensions:
  - `searchMatchBackground` and `searchMatchCurrentBackground` environment values with dynamic light/dark colors
  - `searchHighlightColors(match:currentMatch:)` view modifier for customization
- Added `searchMatchBackground` and `searchMatchCurrentBackground` properties to `TextEnvironmentValues`
- Unit tests for all new search highlight functionality
- `FootnoteReferenceAttribute` - Custom AttributedString attribute for marking footnote reference ranges with `identifier`, `displayNumber`, and `hasSearchMatch` fields
- `FootnoteProperty` - TextProperty that applies pill-badge styling (background, foreground, baseline offset) for footnote references
- Footnote environment extensions:
  - `footnoteBadgeBackground` and `footnoteBadgeForeground` environment values with dynamic light/dark colors
  - `footnoteBadgeColors(background:foreground:)` view modifier for customization
- Added `footnoteBadgeBackground` and `footnoteBadgeForeground` properties to `TextEnvironmentValues`
- `footnoteReference` pattern and token type in `PatternTokenizer` for matching `[^identifier]` syntax
