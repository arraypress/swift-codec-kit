//
//  Base64.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Base64, including the URL-safe alphabet.
public enum Base64 {

    /// Which alphabet, and whether it is padded.
    public enum Alphabet: String, Sendable, CaseIterable {
        /// The standard alphabet, with `+` and `/`.
        case standard
        /// The URL and filename safe alphabet, with `-` and `_` — RFC 4648 §5.
        /// This is what a JWT uses, and what survives being put in a path.
        case urlSafe
    }

    public static func encode(_ data: Data, alphabet: Alphabet = .standard, padded: Bool = true) -> String {
        var text = data.base64EncodedString()
        if alphabet == .urlSafe {
            text = text.replacingOccurrences(of: "+", with: "-")
                       .replacingOccurrences(of: "/", with: "_")
        }
        if !padded { text = text.replacingOccurrences(of: "=", with: "") }
        return text
    }

    public static func encode(_ text: String, alphabet: Alphabet = .standard, padded: Bool = true) -> String {
        encode(Data(text.utf8), alphabet: alphabet, padded: padded)
    }

    /// Decodes either alphabet, padded or not.
    ///
    /// Accepting both without being told which is deliberate: the two are
    /// distinguishable by their characters, and a caller pasting a token
    /// should not have to know which variant produced it. Whitespace and
    /// newlines are ignored, because base64 in the wild arrives wrapped.
    public static func decode(_ text: String) throws -> Data {
        var cleaned = text.filter { !$0.isWhitespace }
        cleaned = cleaned.replacingOccurrences(of: "-", with: "+")
                         .replacingOccurrences(of: "_", with: "/")

        // Padding is optional in the URL-safe world and required by Foundation.
        let remainder = cleaned.count % 4
        if remainder == 2 { cleaned += "==" }
        else if remainder == 3 { cleaned += "=" }
        else if remainder == 1 { throw CodecError.notBase64("length \(text.count) cannot be Base64") }

        guard let data = Data(base64Encoded: cleaned) else {
            throw CodecError.notBase64("unexpected characters")
        }
        return data
    }

    /// Decodes to text, when the bytes are text.
    public static func decodeText(_ text: String) throws -> String {
        let data = try decode(text)
        guard let decoded = String(data: data, encoding: .utf8) else { throw CodecError.notUTF8 }
        return decoded
    }
}
