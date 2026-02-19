import AppKit
import Foundation

struct Snippet: Hashable {
  let trigger: String
  let replacementTemplate: String
  let details: String?
  let caseSensitive: Bool

  func matchesSuffix(in candidate: String) -> Bool {
    guard candidate.count >= trigger.count else { return false }

    if caseSensitive {
      return candidate.hasSuffix(trigger)
    }

    return candidate.lowercased().hasSuffix(trigger.lowercased())
  }
}

struct RenderedSnippet {
  let text: String
  let cursorOffsetFromEnd: Int?
}

enum SnippetTemplateRenderer {
  static func render(_ template: String) -> RenderedSnippet {
    var output = ""
    var cursorPosition: Int?
    var cursor = template.startIndex

    while let openRange = template[cursor...].range(of: "{{") {
      output += String(template[cursor..<openRange.lowerBound])

      guard let closeRange = template[openRange.upperBound...].range(of: "}}") else {
        output += String(template[openRange.lowerBound...])
        cursor = template.endIndex
        break
      }

      let token = template[openRange.upperBound..<closeRange.lowerBound]
        .trimmingCharacters(in: .whitespacesAndNewlines)

      if token == "cursor" {
        cursorPosition = output.count
      } else {
        output += resolveToken(token)
      }

      cursor = closeRange.upperBound
    }

    if cursor < template.endIndex {
      output += String(template[cursor...])
    }

    if let cursorPosition {
      return RenderedSnippet(
        text: output, cursorOffsetFromEnd: max(0, output.count - cursorPosition))
    }

    return RenderedSnippet(text: output, cursorOffsetFromEnd: nil)
  }

  private static func resolveToken(_ token: String) -> String {
    switch token {
    case "date":
      return formatDate("yyyy-MM-dd")
    case "time":
      return formatDate("HH:mm")
    case "datetime":
      return formatDate("yyyy-MM-dd HH:mm")
    case "uuid":
      return UUID().uuidString
    case "clipboard":
      return NSPasteboard.general.string(forType: .string) ?? ""
    default:
      if token.hasPrefix("date:") {
        let format = String(token.dropFirst("date:".count))
        return formatDate(format)
      }
      return "{{\(token)}}"
    }
  }

  private static func formatDate(_ format: String) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = format
    return formatter.string(from: Date())
  }
}
