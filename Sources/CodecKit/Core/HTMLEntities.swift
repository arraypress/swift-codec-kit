//
//  HTMLEntities.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// HTML entities, encoded and decoded.
///
/// Extracted because ten repositories in this fleet were each carrying their
/// own partial version — feed parsing, three scrapers, the PPTX writer, the
/// SVG exporter and the Notes writer among them.
public enum HTMLEntities {

    /// The five that XML and HTML both require.
    static let required: [(character: Character, entity: String)] = [
        ("&", "&amp;"), ("<", "&lt;"), (">", "&gt;"), ("\"", "&quot;"), ("'", "&#39;"),
    ]

    /// Escapes text for placing inside markup.
    ///
    /// `&` goes first and is handled by the ordered walk below — replacing it
    /// after the others would double-escape everything they produced.
    public static func encode(_ text: String, quotes: Bool = true) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        for character in text {
            switch character {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += quotes ? "&quot;" : "\""
            case "'": out += quotes ? "&#39;" : "'"
            default: out.append(character)
            }
        }
        return out
    }

    /// Named entities worth knowing without carrying the whole HTML5 table.
    ///
    /// The full list is over two thousand names. These are the ones that
    /// actually appear in feeds, page titles and scraped text.
    static let named: [String: Character] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'",
        "nbsp": "\u{00A0}", "copy": "©", "reg": "®", "trade": "™",
        "hellip": "…", "mdash": "—", "ndash": "–", "lsquo": "\u{2018}",
        "rsquo": "\u{2019}", "ldquo": "\u{201C}", "rdquo": "\u{201D}",
        "bull": "•", "middot": "·", "deg": "°", "plusmn": "±",
        "times": "×", "divide": "÷", "frac12": "½", "frac14": "¼",
        "euro": "€", "pound": "£", "yen": "¥", "cent": "¢", "sect": "§",
        "para": "¶", "dagger": "†", "laquo": "«", "raquo": "»",
        "larr": "←", "rarr": "→", "uarr": "↑", "darr": "↓", "harr": "↔",
    ]

    /// Decodes named and numeric entities.
    ///
    /// Numeric ones matter more than named ones in practice: a scraper meets
    /// `&#8217;` far more often than `&rsquo;`, and both are the same
    /// apostrophe.
    public static func decode(_ text: String) -> String {
        guard text.contains("&") else { return text }
        var out = ""
        out.reserveCapacity(text.count)
        var rest = Substring(text)

        while let start = rest.firstIndex(of: "&") {
            out += rest[rest.startIndex..<start]
            rest = rest[start...]

            // An entity is short. Scanning the whole remainder for a semicolon
            // would match one paragraphs away and swallow everything between.
            guard let end = rest.prefix(12).firstIndex(of: ";") else {
                out.append("&")
                rest = rest.dropFirst()
                continue
            }
            let body = rest[rest.index(after: start)..<end]
            if let character = resolve(String(body)) {
                out.append(character)
            } else {
                out += rest[start...end]
            }
            rest = rest[rest.index(after: end)...]
        }
        out += rest
        return out
    }

    static func resolve(_ body: String) -> Character? {
        if body.hasPrefix("#") {
            let digits = body.dropFirst()
            let scalar: UInt32?
            if digits.hasPrefix("x") || digits.hasPrefix("X") {
                scalar = UInt32(digits.dropFirst(), radix: 16)
            } else {
                scalar = UInt32(digits)
            }
            guard let scalar, let unicode = Unicode.Scalar(scalar) else { return nil }
            return Character(unicode)
        }
        return named[body] ?? named[body.lowercased()]
    }
}
