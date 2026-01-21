import Foundation

/// Custom attribute for marking search highlight ranges in text.
///
/// This attribute is used by Prism's search highlighting feature to identify
/// text ranges that match search queries. The `isCurrent` property distinguishes
/// the currently selected match from other matches.
///
/// ## Usage
///
/// ```swift
/// var attributedString = AttributedString("Hello world")
/// if let range = attributedString.range(of: "world") {
///     attributedString[range].searchHighlight = SearchHighlightAttribute(isCurrent: true)
/// }
/// ```
public struct SearchHighlightAttribute: Hashable, Sendable, Codable {
  /// Whether this is the currently selected search match.
  ///
  /// When `true`, this match should be rendered with a more prominent highlight color
  /// (typically `searchMatchCurrentBackground`). When `false`, the standard match
  /// highlight color (`searchMatchBackground`) is used.
  public let isCurrent: Bool

  /// Creates a search highlight attribute.
  ///
  /// - Parameter isCurrent: True if this is the active/selected match, false for other matches.
  public init(isCurrent: Bool) {
    self.isCurrent = isCurrent
  }
}

// MARK: - AttributeScope Extension

extension AttributeScopes {
  /// Attribute scope for Textual search-related attributes.
  public struct TextualSearchAttributes: AttributeScope {
    public let searchHighlight: SearchHighlightAttributeKey
  }

  /// Access to Textual search attributes scope.
  public var textualSearch: TextualSearchAttributes.Type {
    TextualSearchAttributes.self
  }
}

/// Attribute key for search highlight in AttributedString.
public enum SearchHighlightAttributeKey: AttributedStringKey {
  public typealias Value = SearchHighlightAttribute
  public static let name = "Textual.SearchHighlight"
}

// MARK: - AttributeContainer Extension

extension AttributeContainer {
  /// The search highlight attribute value.
  public var searchHighlight: SearchHighlightAttribute? {
    get { self[SearchHighlightAttributeKey.self] }
    set { self[SearchHighlightAttributeKey.self] = newValue }
  }
}
