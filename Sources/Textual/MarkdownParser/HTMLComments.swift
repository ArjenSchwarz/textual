import SwiftUI

/// Visual and accessibility configuration for the
/// ``AttributedStringMarkdownParser/SyntaxExtension/htmlComments(visible:appearance:)``
/// syntax extension.
public struct HTMLCommentAppearance: Sendable {
  /// Foreground colour applied to the rendered comment text.
  public var foregroundColor: Color

  /// The SF Symbol name used as the prefix glyph (for example, `"info.circle"`).
  public var prefixSymbolName: String

  /// When `true`, the rendered comment text is italicised.
  public var italic: Bool

  /// Localised "Comment" prefix used by accessibility consumers (Prism's
  /// inline accessibility composer reads this attribute alongside the
  /// `HTMLCommentRangeAttribute` runs).
  public var accessibilityCommentLabel: String

  /// Localised "End comment" suffix used by accessibility consumers.
  public var accessibilityEndCommentLabel: String

  /// Creates a new appearance configuration.
  public init(
    foregroundColor: Color,
    prefixSymbolName: String,
    italic: Bool,
    accessibilityCommentLabel: String,
    accessibilityEndCommentLabel: String
  ) {
    self.foregroundColor = foregroundColor
    self.prefixSymbolName = prefixSymbolName
    self.italic = italic
    self.accessibilityCommentLabel = accessibilityCommentLabel
    self.accessibilityEndCommentLabel = accessibilityEndCommentLabel
  }
}

extension AttributedStringMarkdownParser.SyntaxExtension {
  /// Replaces inline HTML comments (`<!-- ... -->`) with either an empty run
  /// (when `visible == false`) or a styled run containing the SF Symbol from
  /// ``HTMLCommentAppearance/prefixSymbolName``, a single space, and the
  /// comment's inner text (when `visible == true`).
  ///
  /// Comments inside inline code spans and code blocks are left untouched.
  /// Empty or whitespace-only comments produce no output regardless of
  /// `visible`.
  ///
  /// The styled run is tagged with ``HTMLCommentRangeAttribute`` carrying the
  /// comment's inner text so that downstream consumers (typically an
  /// accessibility composer) can present the run as a comment.
  ///
  /// - Parameters:
  ///   - visible: When `true`, comments are rendered as a styled glyph + text
  ///     run. When `false`, comments are replaced with an empty run.
  ///   - appearance: Foreground colour, glyph name, and accessibility labels.
  /// - Returns: A syntax extension that transforms HTML comment ranges.
  public static func htmlComments(
    visible: Bool,
    appearance: HTMLCommentAppearance
  ) -> Self {
    .init(patterns: [.htmlComment]) { token, attributes in
      // Extract the comment's inner text. The capture group includes everything
      // between `<!--` and `-->`; trim outer whitespace for both visibility
      // decisions and the rendered output.
      let inner = (token.capturedContent ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard !inner.isEmpty else {
        // Empty or whitespace-only comments produce no output regardless of
        // visibility (Req 2.6, 3.6).
        return AttributedString()
      }
      guard visible else {
        return AttributedString()
      }

      // Build the replacement runs. The entire replacement is tagged with
      // `HTMLCommentRangeAttribute` so the accessibility composer can identify
      // the comment boundary from any position within it.
      let range = HTMLCommentRangeAttribute(innerText: inner)

      // Symbol attachment — decorative, accessibility comes from the range
      // attribute on the text portion.
      let attachment = HTMLCommentSymbolAttachment(symbolName: appearance.prefixSymbolName)
      var symbolAttributes = attributes.attachment(AnyAttachment(attachment))
      symbolAttributes.htmlCommentRange = range
      let symbolRun = AttributedString("\u{FFFC}", attributes: symbolAttributes)

      // Single space between symbol and text — still part of the comment range.
      var spaceAttributes = attributes
      spaceAttributes.htmlCommentRange = range
      let spaceRun = AttributedString(" ", attributes: spaceAttributes)

      // Styled text run — italic + foreground colour.
      var textAttributes = attributes
      textAttributes.foregroundColor = appearance.foregroundColor
      if appearance.italic {
        var intent = textAttributes.inlinePresentationIntent ?? []
        intent.insert(.emphasized)
        textAttributes.inlinePresentationIntent = intent
      }
      textAttributes.htmlCommentRange = range
      let textRun = AttributedString(inner, attributes: textAttributes)

      var result = AttributedString()
      result.append(symbolRun)
      result.append(spaceRun)
      result.append(textRun)
      return result
    }
  }
}
