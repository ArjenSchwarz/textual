import Foundation
import Testing

@testable import Textual

@Suite("SearchHighlightAttribute")
struct SearchHighlightAttributeTests {

  // MARK: - Initialization Tests

  @Test("creates attribute with isCurrent true")
  func createWithIsCurrentTrue() {
    let attribute = SearchHighlightAttribute(isCurrent: true)
    #expect(attribute.isCurrent == true)
  }

  @Test("creates attribute with isCurrent false")
  func createWithIsCurrentFalse() {
    let attribute = SearchHighlightAttribute(isCurrent: false)
    #expect(attribute.isCurrent == false)
  }

  // MARK: - Equality Tests

  @Test("equal attributes have same isCurrent value")
  func equalityWithSameValue() {
    let attribute1 = SearchHighlightAttribute(isCurrent: true)
    let attribute2 = SearchHighlightAttribute(isCurrent: true)
    #expect(attribute1 == attribute2)
  }

  @Test("different isCurrent values are not equal")
  func inequalityWithDifferentValue() {
    let attribute1 = SearchHighlightAttribute(isCurrent: true)
    let attribute2 = SearchHighlightAttribute(isCurrent: false)
    #expect(attribute1 != attribute2)
  }

  // MARK: - Hashing Tests

  @Test("equal attributes have same hash")
  func hashingConsistency() {
    let attribute1 = SearchHighlightAttribute(isCurrent: true)
    let attribute2 = SearchHighlightAttribute(isCurrent: true)
    #expect(attribute1.hashValue == attribute2.hashValue)
  }

  @Test("can be used in Set")
  func usableInSet() {
    let set: Set<SearchHighlightAttribute> = [
      SearchHighlightAttribute(isCurrent: true),
      SearchHighlightAttribute(isCurrent: false),
      SearchHighlightAttribute(isCurrent: true),  // duplicate
    ]
    #expect(set.count == 2)
  }

  // MARK: - Codable Tests

  @Test("encodes and decodes correctly with isCurrent true")
  func codableWithTrue() throws {
    let original = SearchHighlightAttribute(isCurrent: true)
    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(SearchHighlightAttribute.self, from: encoded)
    #expect(decoded == original)
    #expect(decoded.isCurrent == true)
  }

  @Test("encodes and decodes correctly with isCurrent false")
  func codableWithFalse() throws {
    let original = SearchHighlightAttribute(isCurrent: false)
    let encoded = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(SearchHighlightAttribute.self, from: encoded)
    #expect(decoded == original)
    #expect(decoded.isCurrent == false)
  }

  // MARK: - AttributeContainer Integration Tests

  @Test("can be set on AttributeContainer")
  func setOnAttributeContainer() {
    var container = AttributeContainer()
    container.searchHighlight = SearchHighlightAttribute(isCurrent: true)
    #expect(container.searchHighlight != nil)
    #expect(container.searchHighlight?.isCurrent == true)
  }

  @Test("can be cleared from AttributeContainer")
  func clearFromAttributeContainer() {
    var container = AttributeContainer()
    container.searchHighlight = SearchHighlightAttribute(isCurrent: true)
    container.searchHighlight = nil
    #expect(container.searchHighlight == nil)
  }

  @Test("can be updated on AttributeContainer")
  func updateOnAttributeContainer() {
    var container = AttributeContainer()
    container.searchHighlight = SearchHighlightAttribute(isCurrent: false)
    container.searchHighlight = SearchHighlightAttribute(isCurrent: true)
    #expect(container.searchHighlight?.isCurrent == true)
  }
}
