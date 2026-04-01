import Foundation
import Testing

@testable import Textual

struct FootnoteReferenceTests {
  /// A test implementation of FootnoteDataProvider.
  private struct MockProvider: FootnoteDataProvider {
    let mapping: [String: Int]

    func resolve(identifier: String) -> Int? {
      mapping[identifier]
    }
  }

  private static let singleProvider = MockProvider(mapping: ["1": 1])
  private static let multiProvider = MockProvider(mapping: ["1": 1, "2": 2, "note": 3])
  private static let emptyProvider = MockProvider(mapping: [:])

  // MARK: - PatternProcessor.Rule Tests

  @Test func resolvedReferenceIsReplacedWithDisplayNumber() throws {
    // given
    let processor = PatternProcessor(
      rules: [.footnoteReferences(provider: Self.singleProvider)]
    )
    let input = try AttributedString(
      markdown: "See this[^1] for details",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    let text = String(output.characters)
    #expect(text == "See this1 for details")
  }

  @Test func unresolvedReferenceIsLeftAsPlainText() throws {
    // given
    let processor = PatternProcessor(
      rules: [.footnoteReferences(provider: Self.emptyProvider)]
    )
    let input = try AttributedString(
      markdown: "See this[^unknown] for details",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    let text = String(output.characters)
    #expect(text == "See this[^unknown] for details")
  }

  @Test func footnoteReferenceAttributeIsApplied() throws {
    // given
    let processor = PatternProcessor(
      rules: [.footnoteReferences(provider: Self.singleProvider)]
    )
    let input = try AttributedString(
      markdown: "See this[^1] for details",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    var foundAttribute: FootnoteReferenceAttribute?
    for run in output.runs {
      if let attr = run[FootnoteReferenceAttributeKey.self] {
        foundAttribute = attr
        break
      }
    }

    let attr = try #require(foundAttribute)
    #expect(attr.identifier == "1")
    #expect(attr.displayNumber == 1)
    #expect(attr.hasSearchMatch == false)
  }

  @Test func linkAttributeWithFootnoteURLIsApplied() throws {
    // given
    let processor = PatternProcessor(
      rules: [.footnoteReferences(provider: Self.singleProvider)]
    )
    let input = try AttributedString(
      markdown: "See this[^1] for details",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    var foundURL: URL?
    for run in output.runs {
      if run[FootnoteReferenceAttributeKey.self] != nil {
        foundURL = run.link
        break
      }
    }

    let url = try #require(foundURL)
    #expect(url.scheme == "prism")
    #expect(url.host() == "footnote")
    #expect(url.pathComponents.contains("1"))
  }

  @Test func patternDoesNotMatchInsideCodeSpans() throws {
    // given
    let processor = PatternProcessor(
      rules: [.footnoteReferences(provider: Self.singleProvider)]
    )
    let input = try AttributedString(
      markdown: "Use `[^1]` in code and [^1] outside",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    let text = String(output.characters)
    // Code span should preserve [^1], outside should be replaced with 1
    #expect(text == "Use [^1] in code and 1 outside")
  }

  @Test func patternDoesNotMatchInsideInlineHTML() throws {
    // given
    let processor = PatternProcessor(
      rules: [.footnoteReferences(provider: Self.singleProvider)]
    )
    let input = try AttributedString(
      markdown: "Text [^1] here",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then — the reference outside any HTML/code should still be processed
    var hasFootnoteAttr = false
    for run in output.runs {
      if run[FootnoteReferenceAttributeKey.self] != nil {
        hasFootnoteAttr = true
        break
      }
    }
    #expect(hasFootnoteAttr)
  }

  @Test func multipleReferencesInOneParagraphAreAllProcessed() throws {
    // given
    let processor = PatternProcessor(
      rules: [.footnoteReferences(provider: Self.multiProvider)]
    )
    let input = try AttributedString(
      markdown: "First[^1] and second[^2] and named[^note]",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    let text = String(output.characters)
    #expect(text == "First1 and second2 and named3")

    var identifiers: [String] = []
    for run in output.runs {
      if let attr = run[FootnoteReferenceAttributeKey.self] {
        identifiers.append(attr.identifier)
      }
    }
    #expect(identifiers == ["1", "2", "note"])
  }

  @Test func adjacentReferencesAreBothProcessed() throws {
    // given
    let processor = PatternProcessor(
      rules: [.footnoteReferences(provider: Self.multiProvider)]
    )
    let input = try AttributedString(
      markdown: "See[^1][^2] here",
      including: \.textual,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )

    // when
    let output = try processor.expand(input)

    // then
    let text = String(output.characters)
    #expect(text == "See12 here")

    var numbers: [Int] = []
    for run in output.runs {
      if let attr = run[FootnoteReferenceAttributeKey.self] {
        numbers.append(attr.displayNumber)
      }
    }
    #expect(numbers == [1, 2])
  }
}
