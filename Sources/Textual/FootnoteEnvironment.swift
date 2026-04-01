import SwiftUI

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
  /// Background color for footnote badge pills.
  @Entry var footnoteBadgeBackground = DynamicColor(
    light: Color.blue.opacity(0.15),
    dark: Color.blue.opacity(0.25)
  )

  /// Foreground color for footnote badge text.
  @Entry var footnoteBadgeForeground = DynamicColor(
    light: Color.blue,
    dark: Color.blue.opacity(0.9)
  )
}

// MARK: - View Modifier

extension View {
  /// Sets the footnote badge colors for Textual rendering.
  ///
  /// Use this modifier to customize the colors used for inline footnote reference badges.
  ///
  /// ```swift
  /// DocumentView()
  ///     .footnoteBadgeColors(
  ///         background: .blue.opacity(0.15),
  ///         foreground: .blue
  ///     )
  /// ```
  ///
  /// - Parameters:
  ///   - background: The background color for footnote badges.
  ///   - foreground: The foreground (text) color for footnote badges.
  /// - Returns: A view with the footnote badge colors configured.
  public func footnoteBadgeColors(
    background: Color,
    foreground: Color
  ) -> some View {
    self
      .environment(\.footnoteBadgeBackground, DynamicColor(background))
      .environment(\.footnoteBadgeForeground, DynamicColor(foreground))
  }

  /// Sets the footnote badge colors using dynamic colors for light/dark mode adaptation.
  ///
  /// - Parameters:
  ///   - background: The dynamic background color for footnote badges.
  ///   - foreground: The dynamic foreground color for footnote badges.
  /// - Returns: A view with the footnote badge colors configured.
  public func footnoteBadgeColors(
    background: DynamicColor,
    foreground: DynamicColor
  ) -> some View {
    self
      .environment(\.footnoteBadgeBackground, background)
      .environment(\.footnoteBadgeForeground, foreground)
  }
}
