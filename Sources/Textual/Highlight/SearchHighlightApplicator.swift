import Foundation

/// Searches rendered AttributedString and applies search highlight attributes.
///
/// This utility implements the "search on rendered text" strategy, searching the plaintext
/// representation of an AttributedString and applying highlight attributes directly to
/// the found ranges. This ensures correct highlight placement for repeated words and matches
/// spanning formatting boundaries.
///
/// ## Usage
///
/// ```swift
/// let content = try AttributedString(markdown: "**Hello** world, hello!")
/// let (highlighted, matches) = SearchHighlightApplicator.applyHighlights(
///     to: content,
///     query: "hello",
///     currentMatchIndex: 0
/// )
/// // matches.count == 2
/// // First "hello" (in bold) is marked as current
/// ```
public struct SearchHighlightApplicator: Sendable {

  /// Result of applying search highlights to an AttributedString.
  public struct Result: Sendable {
    /// The AttributedString with search highlights applied.
    public let highlighted: AttributedString

    /// The ranges of all matches found in the AttributedString.
    public let matches: [Range<AttributedString.Index>]

    /// The number of matches found.
    public var matchCount: Int { matches.count }
  }

  /// Search configuration options.
  public struct SearchOptions: Sendable, Hashable {
    /// Whether the search should be case-insensitive.
    public let caseInsensitive: Bool

    /// Whether the search should be diacritic-insensitive.
    public let diacriticInsensitive: Bool

    /// Default search options: case-insensitive and diacritic-insensitive.
    public static let `default` = SearchOptions(
      caseInsensitive: true,
      diacriticInsensitive: true
    )

    /// Creates search options.
    ///
    /// - Parameters:
    ///   - caseInsensitive: Whether to ignore case differences. Defaults to true.
    ///   - diacriticInsensitive: Whether to ignore diacritic differences. Defaults to true.
    public init(
      caseInsensitive: Bool = true,
      diacriticInsensitive: Bool = true
    ) {
      self.caseInsensitive = caseInsensitive
      self.diacriticInsensitive = diacriticInsensitive
    }

    /// Converts search options to String.CompareOptions.
    var stringCompareOptions: String.CompareOptions {
      var options: String.CompareOptions = []
      if caseInsensitive { options.insert(.caseInsensitive) }
      if diacriticInsensitive { options.insert(.diacriticInsensitive) }
      return options
    }
  }

  /// Applies search highlights to an AttributedString.
  ///
  /// This method searches the plaintext representation of the AttributedString for all
  /// occurrences of the query and applies `SearchHighlightAttribute` to each match.
  /// The `currentMatchIndex` parameter specifies which match should be marked as the
  /// "current" match (for navigation purposes).
  ///
  /// - Parameters:
  ///   - attributedString: The rendered AttributedString to search and highlight.
  ///   - query: The search query string. Empty query returns the original string with no matches.
  ///   - currentMatchIndex: Index of the currently selected match (0-based). Pass nil if no
  ///     match should be marked as current.
  ///   - options: Search options (case sensitivity, diacritics). Defaults to `.default`.
  /// - Returns: A `Result` containing the highlighted AttributedString and found match ranges.
  public static func applyHighlights(
    to attributedString: AttributedString,
    query: String,
    currentMatchIndex: Int? = nil,
    options: SearchOptions = .default
  ) -> Result {
    guard !query.isEmpty else {
      return Result(highlighted: attributedString, matches: [])
    }

    var result = attributedString
    let plainText = String(result.characters)

    // Find all occurrences in the plaintext
    var matches: [Range<AttributedString.Index>] = []
    var searchStartIndex = plainText.startIndex

    while searchStartIndex < plainText.endIndex {
      guard
        let stringRange = plainText.range(
          of: query,
          options: options.stringCompareOptions,
          range: searchStartIndex..<plainText.endIndex
        )
      else {
        break
      }

      // Convert String.Index to AttributedString.Index
      if let attrStartIndex = AttributedString.Index(stringRange.lowerBound, within: result),
        let attrEndIndex = AttributedString.Index(stringRange.upperBound, within: result)
      {
        let attrRange = attrStartIndex..<attrEndIndex
        matches.append(attrRange)

        // Apply highlight attribute using merging to preserve existing attributes
        let isCurrent = matches.count - 1 == currentMatchIndex
        var highlightContainer = AttributeContainer()
        highlightContainer.searchHighlight = SearchHighlightAttribute(isCurrent: isCurrent)
        result[attrRange].mergeAttributes(highlightContainer, mergePolicy: .keepNew)
      }

      // Move past this match for next search
      // Advance by at least one character to avoid infinite loop on empty matches
      if stringRange.lowerBound < stringRange.upperBound {
        searchStartIndex = stringRange.upperBound
      } else {
        searchStartIndex = plainText.index(after: stringRange.lowerBound)
      }
    }

    return Result(highlighted: result, matches: matches)
  }

}
