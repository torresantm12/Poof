import AppKit
import Carbon.HIToolbox
import Foundation

final class TextInjector {
  func replaceTypedText(
    deleteCount: Int,
    replacementText: String,
    cursorOffsetFromEnd: Int?
  ) {
    guard deleteCount >= 0 else { return }

    sendBackspaces(count: deleteCount)

    let injectedByKeystrokes = injectTextByKeystroke(replacementText)
    if !injectedByKeystrokes {
      injectTextByClipboardPaste(replacementText)
    }

    if let cursorOffsetFromEnd, cursorOffsetFromEnd > 0 {
      moveCursorLeft(count: cursorOffsetFromEnd)
    }
  }

  private func sendBackspaces(count: Int) {
    guard count > 0 else { return }
    for _ in 0..<count {
      postKeyPress(keyCode: CGKeyCode(kVK_Delete), flags: [])
      usleep(1_500)
    }
  }

  private func injectTextByKeystroke(_ text: String) -> Bool {
    guard !text.isEmpty else { return true }

    for chunk in text.chunked(maxCharacters: 20) {
      guard
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Space), keyDown: true),
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_Space), keyDown: false)
      else {
        return false
      }

      keyDown.keyboardSetUnicodeString(stringLength: chunk.utf16.count, unicodeString: Array(chunk.utf16))
      keyDown.post(tap: .cghidEventTap)
      keyUp.post(tap: .cghidEventTap)
      usleep(1_500)
    }

    return true
  }

  private func injectTextByClipboardPaste(_ text: String) {
    let pasteboard = NSPasteboard.general
    let previousText = pasteboard.string(forType: .string)

    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)

    postKeyPress(keyCode: CGKeyCode(kVK_ANSI_V), flags: [.maskCommand])

    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) {
      pasteboard.clearContents()
      if let previousText {
        pasteboard.setString(previousText, forType: .string)
      }
    }
  }

  private func moveCursorLeft(count: Int) {
    guard count > 0 else { return }
    for _ in 0..<count {
      postKeyPress(keyCode: CGKeyCode(kVK_LeftArrow), flags: [])
      usleep(1_000)
    }
  }

  private func postKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) {
    guard
      let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
      let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
    else {
      return
    }

    keyDown.flags = flags
    keyUp.flags = flags
    keyDown.post(tap: .cghidEventTap)
    keyUp.post(tap: .cghidEventTap)
  }
}

private extension String {
  func chunked(maxCharacters: Int) -> [String] {
    guard maxCharacters > 0 else { return [self] }

    var chunks: [String] = []
    var start = startIndex

    while start < endIndex {
      let end = index(start, offsetBy: maxCharacters, limitedBy: endIndex) ?? endIndex
      chunks.append(String(self[start..<end]))
      start = end
    }

    return chunks
  }
}
