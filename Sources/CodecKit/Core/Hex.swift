//
//  Hex.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Hexadecimal, for bytes and for text.
public enum Hex {

    public static func encode(_ data: Data, uppercase: Bool = false, separator: String = "") -> String {
        data.map { String(format: uppercase ? "%02X" : "%02x", $0) }.joined(separator: separator)
    }

    public static func encode(_ text: String, uppercase: Bool = false, separator: String = "") -> String {
        encode(Data(text.utf8), uppercase: uppercase, separator: separator)
    }

    /// Decodes hex, ignoring the ways people space it out.
    ///
    /// `DE AD BE EF`, `de:ad:be:ef`, `\xde\xad` and `0xdeadbeef` are all the
    /// same four bytes, and refusing any of them would be pedantry.
    public static func decode(_ text: String) throws -> Data {
        var cleaned = text.lowercased()
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: "\\x", with: "")
        cleaned.removeAll { $0.isWhitespace || $0 == ":" || $0 == "-" || $0 == "," }

        guard cleaned.count.isMultiple(of: 2) else {
            throw CodecError.notHex("an odd number of digits (\(cleaned.count)) cannot be whole bytes")
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(cleaned.count / 2)
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let next = cleaned.index(index, offsetBy: 2)
            guard let byte = UInt8(cleaned[index..<next], radix: 16) else {
                throw CodecError.notHex("'\(cleaned[index..<next])' is not a hex byte")
            }
            bytes.append(byte)
            index = next
        }
        return Data(bytes)
    }

    public static func decodeText(_ text: String) throws -> String {
        guard let decoded = String(data: try decode(text), encoding: .utf8) else { throw CodecError.notUTF8 }
        return decoded
    }
}
