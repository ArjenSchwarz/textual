import Foundation

/// Protocol for resolving footnote identifiers to display numbers.
///
/// Implement this protocol to provide footnote resolution data to the
/// ``PatternProcessor/Rule/footnoteReferences(provider:)`` pattern rule.
/// The provider decouples Textual from any concrete footnote data type.
public protocol FootnoteDataProvider: Sendable {
  /// Returns the display number for a footnote identifier, or `nil` if the identifier
  /// has no definition.
  ///
  /// - Parameter identifier: The footnote identifier (e.g., "1" from `[^1]`).
  /// - Returns: The sequential display number, or `nil` for unresolved references.
  func resolve(identifier: String) -> Int?
}

extension PatternProcessor.Rule {
  /// Creates a rule that replaces footnote references (`[^id]`) with styled display numbers.
  ///
  /// Resolved references are replaced with the display number and annotated with
  /// ``FootnoteReferenceAttribute`` and a `prism://footnote/{identifier}` link attribute.
  /// Unresolved references (where the provider returns `nil`) are left as plain text.
  ///
  /// - Parameter provider: The footnote data provider for resolving identifiers.
  /// - Returns: A pattern processor rule for footnote reference expansion.
  static func footnoteReferences(provider: any FootnoteDataProvider) -> Self {
    .init(patterns: [.footnoteReference]) { token, attributes in
      guard let identifier = token.capturedContent,
        let number = provider.resolve(identifier: identifier)
      else {
        return nil  // Leave unresolved references as plain text
      }

      var attrs = attributes
      attrs.footnoteReference = FootnoteReferenceAttribute(
        identifier: identifier,
        displayNumber: number
      )

      // Link attribute enables tap handling via openURL
      if let url = URL(string: "prism://footnote/\(identifier)") {
        attrs.link = url
      }

      return AttributedString("\(number)", attributes: attrs)
    }
  }
}
