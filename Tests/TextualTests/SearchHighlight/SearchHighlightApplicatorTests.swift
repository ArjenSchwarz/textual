import Foundation
import SwiftUI
import Testing

@testable import Textual

@Suite("SearchHighlightApplicator")
struct SearchHighlightApplicatorTests {

  // Type alias for brevity
  typealias Applicator = SearchHighlightApplicator
  typealias Options = SearchHighlightApplicator.SearchOptions

  // Helper to get searchHighlight attribute from a run
  private func getSearchHighlight(from run: AttributedString.Runs.Run) -> SearchHighlightAttribute?
  {
    run[SearchHighlightAttributeKey.self]
  }

  // MARK: - Empty Query Tests

  @Test("returns no matches for empty query")
  func emptyQueryNoMatches() {
    let content = AttributedString("some text")
    let result = Applicator.applyHighlights(
      to: content,
      query: ""
    )

    #expect(result.matches.isEmpty)
    #expect(result.highlighted == content)
  }

  // MARK: - Single Occurrence Tests

  @Test("finds single occurrence")
  func singleOccurrence() {
    let content = AttributedString("find me here")
    let result = Applicator.applyHighlights(
      to: content,
      query: "me"
    )

    #expect(result.matches.count == 1)
  }

  @Test("highlights single occurrence correctly")
  func highlightsSingleOccurrence() {
    let content = AttributedString("find me here")
    let result = Applicator.applyHighlights(
      to: content,
      query: "me"
    )

    // Verify highlight was applied
    var highlightCount = 0
    for run in result.highlighted.runs {
      if getSearchHighlight(from: run) != nil {
        highlightCount += 1
      }
    }
    #expect(highlightCount >= 1)
  }

  // MARK: - Multiple Occurrences Tests

  @Test("finds multiple occurrences with distinct ranges")
  func multipleOccurrences() {
    let content = AttributedString("the cat and the dog and the bird")
    let result = Applicator.applyHighlights(
      to: content,
      query: "the"
    )

    #expect(result.matches.count == 3)

    // Verify each match has a distinct range
    let uniqueRanges = Set(result.matches.map { "\($0.lowerBound)-\($0.upperBound)" })
    #expect(uniqueRanges.count == 3)
  }

  @Test("repeated words highlight correctly - key test for Decision 9")
  func repeatedWordsHighlightCorrectly() {
    // This is a critical test: each "word" should get its own distinct highlight
    let content = AttributedString("word word word")
    let result = Applicator.applyHighlights(
      to: content,
      query: "word"
    )

    #expect(result.matches.count == 3)

    // Verify all matches are distinct
    for i in 0..<result.matches.count {
      for j in (i + 1)..<result.matches.count {
        #expect(result.matches[i] != result.matches[j])
      }
    }

    // Verify highlights applied to each occurrence
    var highlightCount = 0
    for run in result.highlighted.runs {
      if getSearchHighlight(from: run) != nil {
        highlightCount += 1
      }
    }
    #expect(highlightCount >= 3)
  }

  // MARK: - Current Match Tests

  @Test("marks current match correctly")
  func marksCurrentMatch() {
    let content = AttributedString("word word word")
    let result = Applicator.applyHighlights(
      to: content,
      query: "word",
      currentMatchIndex: 1
    )

    #expect(result.matches.count == 3)

    // Count current highlights
    var currentCount = 0
    var nonCurrentCount = 0
    for run in result.highlighted.runs {
      if let highlight = getSearchHighlight(from: run) {
        if highlight.isCurrent {
          currentCount += 1
        } else {
          nonCurrentCount += 1
        }
      }
    }

    #expect(currentCount >= 1)
    #expect(nonCurrentCount >= 2)
  }

  @Test("first match is current when index is 0")
  func firstMatchCurrent() {
    let content = AttributedString("a b a")
    let result = Applicator.applyHighlights(
      to: content,
      query: "a",
      currentMatchIndex: 0
    )

    #expect(result.matches.count == 2)

    // The first match range should have isCurrent = true
    if let firstRange = result.matches.first {
      // Access the attribute via the AttributeContainer
      let container = result.highlighted[firstRange]
      let firstHighlight = container[SearchHighlightAttributeKey.self]
      #expect(firstHighlight?.isCurrent == true)
    }
  }

  @Test("nil currentMatchIndex marks no match as current")
  func nilCurrentIndexNoCurrentHighlight() {
    let content = AttributedString("word word")
    let result = Applicator.applyHighlights(
      to: content,
      query: "word",
      currentMatchIndex: nil
    )

    // No highlight should be marked as current
    for run in result.highlighted.runs {
      if let highlight = getSearchHighlight(from: run) {
        #expect(highlight.isCurrent == false)
      }
    }
  }

  // MARK: - Case Sensitivity Tests

  @Test("case insensitive search by default")
  func caseInsensitiveByDefault() {
    let content = AttributedString("Hello HELLO hello")
    let result = Applicator.applyHighlights(
      to: content,
      query: "hello"
    )

    #expect(result.matches.count == 3)
  }

  @Test("case sensitive search when specified")
  func caseSensitiveSearch() {
    let content = AttributedString("Hello HELLO hello")
    let result = Applicator.applyHighlights(
      to: content,
      query: "hello",
      options: Options(caseInsensitive: false)
    )

    #expect(result.matches.count == 1)
  }

  // MARK: - Formatted Text Tests

  @Test("handles formatted text correctly")
  func formattedTextHighlights() throws {
    // Create AttributedString with bold formatting
    var content = AttributedString("bold text here")
    if let range = content.range(of: "bold") {
      content[range].inlinePresentationIntent = .stronglyEmphasized
    }

    let result = Applicator.applyHighlights(
      to: content,
      query: "bold"
    )

    #expect(result.matches.count == 1)
  }

  @Test("preserves existing attributes when adding highlights")
  func preservesExistingAttributes() throws {
    var content = AttributedString("test text")
    content.foregroundColor = Color.red

    let result = Applicator.applyHighlights(
      to: content,
      query: "test"
    )

    // Original foreground color should be preserved
    #expect(result.highlighted.foregroundColor == Color.red)

    // Highlight should be added
    #expect(result.matches.count == 1)
  }

  // MARK: - Edge Cases

  @Test("handles query not found")
  func queryNotFound() {
    let content = AttributedString("hello world")
    let result = Applicator.applyHighlights(
      to: content,
      query: "xyz"
    )

    #expect(result.matches.isEmpty)
    #expect(result.highlighted == content)
  }

  @Test("handles empty attributed string")
  func emptyAttributedString() {
    let content = AttributedString("")
    let result = Applicator.applyHighlights(
      to: content,
      query: "test"
    )

    #expect(result.matches.isEmpty)
  }

  @Test("handles query at start of string")
  func queryAtStart() {
    let content = AttributedString("hello world")
    let result = Applicator.applyHighlights(
      to: content,
      query: "hello"
    )

    #expect(result.matches.count == 1)
  }

  @Test("handles query at end of string")
  func queryAtEnd() {
    let content = AttributedString("hello world")
    let result = Applicator.applyHighlights(
      to: content,
      query: "world"
    )

    #expect(result.matches.count == 1)
  }

  @Test("handles query that is entire string")
  func queryIsEntireString() {
    let content = AttributedString("hello")
    let result = Applicator.applyHighlights(
      to: content,
      query: "hello"
    )

    #expect(result.matches.count == 1)
  }

  // MARK: - SearchOptions Tests

  @Test("default options are case and diacritic insensitive")
  func defaultOptions() {
    let options = Options.default
    #expect(options.caseInsensitive == true)
    #expect(options.diacriticInsensitive == true)
  }

  @Test("diacritic insensitive search")
  func diacriticInsensitiveSearch() {
    let content = AttributedString("café cafe CAFÉ")
    let result = Applicator.applyHighlights(
      to: content,
      query: "cafe"
    )

    #expect(result.matches.count == 3)
  }

  @Test("diacritic sensitive search when specified")
  func diacriticSensitiveSearch() {
    let content = AttributedString("café cafe")
    let result = Applicator.applyHighlights(
      to: content,
      query: "cafe",
      options: Options(caseInsensitive: true, diacriticInsensitive: false)
    )

    #expect(result.matches.count == 1)
  }

  // MARK: - Result Struct Tests

  @Test("Result matchCount matches array count")
  func resultMatchCount() {
    let content = AttributedString("a a a")
    let result = Applicator.applyHighlights(
      to: content,
      query: "a"
    )

    #expect(result.matchCount == result.matches.count)
    #expect(result.matchCount == 3)
  }
}
