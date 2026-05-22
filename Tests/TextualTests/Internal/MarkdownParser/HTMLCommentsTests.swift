import Foundation
import SwiftUI
import Testing

@testable import Textual

struct HTMLCommentsTests {
  private static let appearance = HTMLCommentAppearance(
    foregroundColor: .gray,
    prefixSymbolName: "info.circle",
    italic: true,
    accessibilityCommentLabel: "Comment",
    accessibilityEndCommentLabel: "End comment"
  )

  // MARK: - Visibility behaviour

  @Test func visibleTrueReplacesCommentWithSymbolAndInnerText() throws {
    // given
    let processor = AttributedStringMarkdownParser.PatternProcessor(
      syntaxExtensions: [.htmlComments(visible: true, appearance: Self.appearance)]
    )
    let input = try AttributedString(
      markdown: "before <!-- note --> after",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then — the comment markers are gone, the inner text is present, and an
    // object-replacement character (the symbol attachment) sits before it.
    let text = String(output.characters)
    #expect(!text.contains("<!--"))
    #expect(!text.contains("-->"))
    #expect(text.contains("note"))
    #expect(text.contains("\u{FFFC}"))  // attachment placeholder
  }

  @Test func visibleFalseReplacesCommentWithEmpty() throws {
    // given
    let processor = AttributedStringMarkdownParser.PatternProcessor(
      syntaxExtensions: [.htmlComments(visible: false, appearance: Self.appearance)]
    )
    let input = try AttributedString(
      markdown: "before <!-- note --> after",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    let text = String(output.characters)
    #expect(!text.contains("<!--"))
    #expect(!text.contains("-->"))
    #expect(!text.contains("note"))
    #expect(text.contains("before"))
    #expect(text.contains("after"))
  }

  // MARK: - Code-span survival

  @Test func backtickWrappedCommentSurvivesLiterally() throws {
    // given — when the comment is inside a code span, both visible states must
    // leave the literal markers in place.
    let visibleProcessor = AttributedStringMarkdownParser.PatternProcessor(
      syntaxExtensions: [.htmlComments(visible: true, appearance: Self.appearance)]
    )
    let hiddenProcessor = AttributedStringMarkdownParser.PatternProcessor(
      syntaxExtensions: [.htmlComments(visible: false, appearance: Self.appearance)]
    )
    let input = try AttributedString(
      markdown: "Use `<!--x-->` literally",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let visibleOutput = try visibleProcessor.expand(input)
    let hiddenOutput = try hiddenProcessor.expand(input)

    // then
    let visibleText = String(visibleOutput.characters)
    let hiddenText = String(hiddenOutput.characters)
    #expect(visibleText.contains("<!--x-->"))
    #expect(hiddenText.contains("<!--x-->"))
  }

  // MARK: - Empty / whitespace-only

  @Test func emptyCommentProducesNoOutputEvenWhenVisible() throws {
    // given
    let processor = AttributedStringMarkdownParser.PatternProcessor(
      syntaxExtensions: [.htmlComments(visible: true, appearance: Self.appearance)]
    )
    let input = try AttributedString(
      markdown: "foo<!---->bar",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then — `foobar` with no attachment.
    let text = String(output.characters)
    #expect(text == "foobar")
    #expect(!text.contains("\u{FFFC}"))
  }

  @Test func whitespaceOnlyCommentProducesNoOutputEvenWhenVisible() throws {
    // given
    let processor = AttributedStringMarkdownParser.PatternProcessor(
      syntaxExtensions: [.htmlComments(visible: true, appearance: Self.appearance)]
    )
    let input = try AttributedString(
      markdown: "foo<!--   -->bar",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    let text = String(output.characters)
    #expect(text == "foobar")
    #expect(!text.contains("\u{FFFC}"))
  }

  // MARK: - Range attribute

  @Test func visibleCommentRangeIsTaggedWithHTMLCommentRangeAttribute() throws {
    // given
    let processor = AttributedStringMarkdownParser.PatternProcessor(
      syntaxExtensions: [.htmlComments(visible: true, appearance: Self.appearance)]
    )
    let input = try AttributedString(
      markdown: "before <!-- author note --> after",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then — at least one run carries HTMLCommentRangeAttribute whose innerText is "author note".
    var foundAttribute: HTMLCommentRangeAttribute?
    for run in output.runs {
      if let attr = run[HTMLCommentRangeAttributeKey.self] {
        foundAttribute = attr
        break
      }
    }
    let attr = try #require(foundAttribute)
    #expect(attr.innerText == "author note")
  }

  @Test func hiddenCommentLeavesNoRangeAttribute() throws {
    // given
    let processor = AttributedStringMarkdownParser.PatternProcessor(
      syntaxExtensions: [.htmlComments(visible: false, appearance: Self.appearance)]
    )
    let input = try AttributedString(
      markdown: "before <!-- note --> after",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    var sawAttribute = false
    for run in output.runs {
      if run[HTMLCommentRangeAttributeKey.self] != nil {
        sawAttribute = true
        break
      }
    }
    #expect(sawAttribute == false)
  }

  // MARK: - Mid-word handling

  @Test func midWordCommentSplitsSurroundingText() throws {
    // given — `foo<!--x-->bar` must render as `foo` + symbol + `x` + `bar`
    // when visible.
    let processor = AttributedStringMarkdownParser.PatternProcessor(
      syntaxExtensions: [.htmlComments(visible: true, appearance: Self.appearance)]
    )
    let input = try AttributedString(
      markdown: "foo<!--x-->bar",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    let text = String(output.characters)
    #expect(text.contains("foo"))
    #expect(text.contains("x"))
    #expect(text.contains("bar"))
    #expect(text.contains("\u{FFFC}"))
    #expect(!text.contains("<!--"))
  }
}

// MARK: - isInsideCodeSpan helper tests

struct IsInsideCodeSpanTests {
  @Test func rangeFullyInsideInlineCodeSpanIsDetected() throws {
    // given
    let input = try AttributedString(
      markdown: "Use `<!--x-->` literally",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when — find the range of the `<!--x-->` substring (which sits inside the code span).
    let commentRange = try #require(input.range(of: "<!--x-->"))

    // then
    #expect(
      AttributedStringMarkdownParser.PatternProcessor.isInsideCodeSpan(
        range: commentRange,
        in: input
      )
    )
  }

  @Test func rangeOutsideCodeSpanIsNotDetected() throws {
    // given
    let input = try AttributedString(
      markdown: "regular text <!--x--> here",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let commentRange = try #require(input.range(of: "<!--x-->"))

    // then
    #expect(
      AttributedStringMarkdownParser.PatternProcessor.isInsideCodeSpan(
        range: commentRange,
        in: input
      ) == false
    )
  }

  @Test func rangePartiallyOverlappingCodeSpanIsNotDetected() throws {
    // given — a range that starts inside the code span but extends outside it
    // should NOT be classified as inside a code span (the helper requires the
    // range to be fully inside).
    let input = try AttributedString(
      markdown: "`code` and more",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )
    // Find a range from the start of "code" to the end of the string.
    let codeStart = try #require(input.range(of: "code"))
    let fullRange = codeStart.lowerBound..<input.endIndex

    // then
    #expect(
      AttributedStringMarkdownParser.PatternProcessor.isInsideCodeSpan(
        range: fullRange,
        in: input
      ) == false
    )
  }
}
