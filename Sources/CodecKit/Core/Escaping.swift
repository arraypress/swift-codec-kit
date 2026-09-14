//
//  Escaping.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Backslash escapes, in the dialects that differ.
public enum Escaping {

    public enum Dialect: String, Sendable, CaseIterable {
        /// JSON: `\n`, `\t`, `\"`, `\\`, and `\uXXXX` for the rest.
        case json
        /// A C-like or Swift-like string literal, which also has `\0`.
        case swift
        /// A POSIX shell single-quoted string, where the only escape that
        /// exists is ending the quote and starting it again.
        case shell
    }

    public static func escape(_ text: String, dialect: Dialect = .json) -> String {
        if dialect == .shell {
            // Inside single quotes nothing is special, so the only thing to
            // handle is a single quote itself: close, emit an escaped one,
            // reopen. Anything else is a way to get a shell injection.
            return "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
        }
        var out = ""
        out.reserveCapacity(text.count)
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            case "\u{08}": out += "\\b"
            case "\u{0C}": out += "\\f"
            case "\u{00}" where dialect == .swift: out += "\\0"
            default:
                if scalar.value < 0x20 {
                    out += String(format: "\\u%04X", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out
    }

    /// Reverses the escaping, including `\uXXXX` and its surrogate pairs.
    public static func unescape(_ text: String) throws -> String {
        var out = ""
        var characters = Array(text)
        var index = 0

        while index < characters.count {
            guard characters[index] == "\\", index + 1 < characters.count else {
                out.append(characters[index]); index += 1; continue
            }
            let next = characters[index + 1]
            index += 2
            switch next {
            case "n": out.append("\n")
            case "r": out.append("\r")
            case "t": out.append("\t")
            case "b": out.append("\u{08}")
            case "f": out.append("\u{0C}")
            case "0": out.append("\u{00}")
            case "\\": out.append("\\")
            case "\"": out.append("\"")
            case "'": out.append("'")
            case "/": out.append("/")
            case "u", "x":
                let width = next == "u" ? 4 : 2
                guard index + width <= characters.count,
                      let value = UInt32(String(characters[index..<index + width]), radix: 16)
                else { throw CodecError.unreadable("a truncated \\\(next) escape") }
                index += width

                // A high surrogate is only half a character: JSON writes
                // anything past the BMP as a pair, and decoding them
                // separately produces two replacement characters.
                if next == "u", (0xD800...0xDBFF).contains(value),
                   index + 6 <= characters.count,
                   characters[index] == "\\", characters[index + 1] == "u",
                   let low = UInt32(String(characters[index + 2..<index + 6]), radix: 16),
                   (0xDC00...0xDFFF).contains(low) {
                    let combined = 0x10000 + (value - 0xD800) * 0x400 + (low - 0xDC00)
                    if let scalar = Unicode.Scalar(combined) { out.append(Character(scalar)) }
                    index += 6
                } else if let scalar = Unicode.Scalar(value) {
                    out.append(Character(scalar))
                }
            default:
                out.append(next)
            }
        }
        return out
    }
}
