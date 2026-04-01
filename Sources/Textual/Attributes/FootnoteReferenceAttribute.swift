import Foundation

/// Custom attribute for marking footnote reference ranges in text.
///
/// This attribute is used by Prism's footnote feature to identify inline footnote
/// reference badges. It stores the footnote identifier, display number, and whether
/// the footnote content contains a search match.
///
/// ## Usage
///
/// ```swift
/// var attributedString = AttributedString("See 1")
/// if let range = attributedString.range(of: "1") {
///     attributedString[range].footnoteReference = FootnoteReferenceAttribute(
///         identifier: "note1",
///         displayNumber: 1
///     )
/// }
/// ```
public struct FootnoteReferenceAttribute: Hashable, Sendable, Codable {
  /// The footnote identifier from the markdown source (e.g., "note1" from `[^note1]`).
  public let identifier: String

  /// The sequential display number assigned based on first-reference order.
  public let displayNumber: Int

  /// Whether the footnote's definition content contains a search match.
  ///
  /// When `true`, the badge should be rendered with the search highlight color
  /// to indicate that the footnote content matches the current search query.
  public var hasSearchMatch: Bool

  /// Creates a footnote reference attribute.
  ///
  /// - Parameters:
  ///   - identifier: The footnote identifier from the source.
  ///   - displayNumber: The sequential display number.
  ///   - hasSearchMatch: Whether the footnote content matches a search query. Defaults to `false`.
  public init(identifier: String, displayNumber: Int, hasSearchMatch: Bool = false) {
    self.identifier = identifier
    self.displayNumber = displayNumber
    self.hasSearchMatch = hasSearchMatch
  }

  /// Returns a copy with the search match flag set to `true`.
  public func withSearchMatch() -> FootnoteReferenceAttribute {
    FootnoteReferenceAttribute(
      identifier: identifier,
      displayNumber: displayNumber,
      hasSearchMatch: true
    )
  }
}

// MARK: - AttributeScope Extension

extension AttributeScopes {
  /// Attribute scope for Textual footnote-related attributes.
  public struct TextualFootnoteAttributes: AttributeScope {
    public let footnoteReference: FootnoteReferenceAttributeKey
  }

  /// Access to Textual footnote attributes scope.
  public var textualFootnote: TextualFootnoteAttributes.Type {
    TextualFootnoteAttributes.self
  }
}

/// Attribute key for footnote reference in AttributedString.
public enum FootnoteReferenceAttributeKey: AttributedStringKey {
  public typealias Value = FootnoteReferenceAttribute
  public static let name = "Textual.FootnoteReference"
}

// MARK: - AttributeContainer Extension

extension AttributeContainer {
  /// The footnote reference attribute value.
  public var footnoteReference: FootnoteReferenceAttribute? {
    get { self[FootnoteReferenceAttributeKey.self] }
    set { self[FootnoteReferenceAttributeKey.self] = newValue }
  }
}
