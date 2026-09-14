//
//  Digest.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//

import CryptoKit
import Foundation

/// Hashing bytes, text and files.
public enum Digest {

    /// How much of a file to read at a time.
    ///
    /// Files get hashed in chunks rather than loaded whole: a disk image is
    /// larger than memory, and `Data(contentsOf:)` on one is how a tool that
    /// worked on the test fixtures dies on the real thing.
    static let chunkSize = 1 << 20

    public static func hash(_ data: Data, using algorithm: HashAlgorithm) -> String {
        switch algorithm {
        case .md5: hex(Insecure.MD5.hash(data: data))
        case .sha1: hex(Insecure.SHA1.hash(data: data))
        case .sha256: hex(SHA256.hash(data: data))
        case .sha384: hex(SHA384.hash(data: data))
        case .sha512: hex(SHA512.hash(data: data))
        case .crc32: String(format: "%08x", CRC32.checksum(data))
        }
    }

    public static func hash(_ text: String, using algorithm: HashAlgorithm) -> String {
        hash(Data(text.utf8), using: algorithm)
    }

    /// Hashes a file without reading it all into memory.
    public static func hash(contentsOf url: URL, using algorithm: HashAlgorithm) throws -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            throw CodecError.unreadable(url.lastPathComponent)
        }
        defer { try? handle.close() }

        if algorithm == .crc32 {
            var crc = CRC32.start
            while case let chunk = handle.readData(ofLength: chunkSize), !chunk.isEmpty {
                crc = CRC32.update(crc, with: chunk)
            }
            return String(format: "%08x", CRC32.finish(crc))
        }

        var md5 = Insecure.MD5(), sha1 = Insecure.SHA1()
        var sha256 = SHA256(), sha384 = SHA384(), sha512 = SHA512()
        while case let chunk = handle.readData(ofLength: chunkSize), !chunk.isEmpty {
            switch algorithm {
            case .md5: md5.update(data: chunk)
            case .sha1: sha1.update(data: chunk)
            case .sha256: sha256.update(data: chunk)
            case .sha384: sha384.update(data: chunk)
            case .sha512: sha512.update(data: chunk)
            case .crc32: break
            }
        }
        switch algorithm {
        case .md5: return hex(md5.finalize())
        case .sha1: return hex(sha1.finalize())
        case .sha256: return hex(sha256.finalize())
        case .sha384: return hex(sha384.finalize())
        case .sha512: return hex(sha512.finalize())
        case .crc32: return ""
        }
    }

    /// Whether a digest matches, compared without regard to case or spacing.
    ///
    /// A checksum copied from a web page arrives with stray whitespace and in
    /// whichever case that page used; refusing it for either would be a false
    /// negative on a file that is fine.
    public static func matches(_ produced: String, _ expected: String) -> Bool {
        func normalise(_ text: String) -> String {
            text.lowercased().filter { !$0.isWhitespace && $0 != ":" }
        }
        return normalise(produced) == normalise(expected)
    }

    private static func hex<D: Sequence>(_ digest: D) -> String where D.Element == UInt8 {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}

/// CRC-32, which CryptoKit does not carry.
///
/// Not a cryptographic hash — it detects accidental corruption and nothing
/// more. Here because zip files, PNG chunks and a great many old manifests
/// use it.
enum CRC32 {
    static let start: UInt32 = 0xFFFFFFFF

    static let table: [UInt32] = (0..<256).map { index -> UInt32 in
        var value = UInt32(index)
        for _ in 0..<8 {
            value = (value & 1) == 1 ? (value >> 1) ^ 0xEDB88320 : value >> 1
        }
        return value
    }

    static func update(_ crc: UInt32, with data: Data) -> UInt32 {
        var current = crc
        for byte in data {
            current = (current >> 8) ^ table[Int((current ^ UInt32(byte)) & 0xFF)]
        }
        return current
    }

    static func finish(_ crc: UInt32) -> UInt32 { crc ^ 0xFFFFFFFF }

    static func checksum(_ data: Data) -> UInt32 { finish(update(start, with: data)) }
}
