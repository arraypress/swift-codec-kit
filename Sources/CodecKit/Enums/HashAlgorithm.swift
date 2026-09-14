//
//  HashAlgorithm.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A digest algorithm.
public enum HashAlgorithm: String, Sendable, CaseIterable, Codable {
    case md5
    case sha1
    case sha256
    case sha384
    case sha512
    case crc32

    /// Hex characters in the result.
    public var width: Int {
        switch self {
        case .md5: 32
        case .sha1: 40
        case .sha256: 64
        case .sha384: 96
        case .sha512: 128
        case .crc32: 8
        }
    }

    /// Whether it is still fit to prove a file has not been tampered with.
    ///
    /// MD5 and SHA-1 have practical collision attacks and CRC-32 is not a
    /// cryptographic hash at all — it catches accidental corruption and
    /// nothing else. They stay because existing checksums use them, and a
    /// tool that cannot read an old manifest is no use.
    public var isCryptographic: Bool {
        switch self {
        case .sha256, .sha384, .sha512: true
        case .md5, .sha1, .crc32: false
        }
    }

    public init?(name: String) {
        let cleaned = name.lowercased().replacingOccurrences(of: "-", with: "")
        guard let match = Self(rawValue: cleaned) else { return nil }
        self = match
    }
}
