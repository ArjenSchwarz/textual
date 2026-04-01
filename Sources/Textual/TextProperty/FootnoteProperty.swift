import SwiftUI

/// A text property that applies footnote badge pill styling.
///
/// This property conforms to ``TextProperty`` and applies background color,
/// foreground color, and baseline offset attributes to render footnote references
/// as superscript pill badges.
///
/// ## Usage
///
/// Use the static factory method for convenience:
///
/// ```swift
/// let badgeStyle = FootnoteProperty.footnoteBadge
/// ```
public struct FootnoteProperty: TextProperty {
  public init() {}

  public func apply(
    in attributes: inout AttributeContainer,
    environment: TextEnvironmentValues
  ) {
    if let bg = environment.footnoteBadgeBackground
      .bestMatch(for: environment.colorEnvironment) {
      attributes.backgroundColor = bg
    }
    if let fg = environment.footnoteBadgeForeground
      .bestMatch(for: environment.colorEnvironment) {
      attributes.foregroundColor = fg
    }
    attributes.baselineOffset = 4
  }
}

// MARK: - Static Factory Method

extension TextProperty where Self == FootnoteProperty {
  /// Creates a footnote badge property with the standard badge styling.
  public static var footnoteBadge: Self {
    FootnoteProperty()
  }
}
