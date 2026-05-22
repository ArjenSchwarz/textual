import Foundation

/// Custom attribute for marking rendered HTML comment ranges in text.
///
/// This attribute is used by Prism's HTML comment feature to identify inline
/// runs that were produced by replacing a source `<!-- ... -->` comment. The
/// attribute carries the comment's inner text so that downstream consumers
/// (for example, an accessibility composer) can announce the comment content
/// without re-parsing the markdown source.
///
/// ## Usage
///
/// ```swift
/// var attributedString = AttributedString("Comment text")
/// if let range = attributedString.range(of: "Comment text") {
///     attributedString[range].htmlCommentRange = HTMLCommentRangeAttribute(
///         innerText: "Comment text"
///     )
/// }
/// ```
public struct HTMLCommentRangeAttribute: Hashable, Sendable, Codable {
  /// The inner text of the source HTML comment, with `<!--` / `-->` markers stripped.
  public let innerText: String

  /// Creates an HTML comment range attribute.
  ///
  /// - Parameter innerText: The inner text of the source comment.
  public init(innerText: String) {
    self.innerText = innerText
  }
}

// MARK: - AttributeScope Extension

extension AttributeScopes {
  /// Attribute scope for Textual HTML-comment-related attributes.
  public struct TextualHTMLCommentAttributes: AttributeScope {
    public let htmlCommentRange: HTMLCommentRangeAttributeKey
  }

  /// Access to Textual HTML comment attributes scope.
  public var textualHTMLComment: TextualHTMLCommentAttributes.Type {
    TextualHTMLCommentAttributes.self
  }
}

/// Attribute key for HTML comment range in `AttributedString`.
public enum HTMLCommentRangeAttributeKey: AttributedStringKey {
  public typealias Value = HTMLCommentRangeAttribute
  public static let name = "Textual.HTMLCommentRange"
}

// MARK: - AttributeContainer Extension

extension AttributeContainer {
  /// The HTML comment range attribute value.
  public var htmlCommentRange: HTMLCommentRangeAttribute? {
    get { self[HTMLCommentRangeAttributeKey.self] }
    set { self[HTMLCommentRangeAttributeKey.self] = newValue }
  }
}
