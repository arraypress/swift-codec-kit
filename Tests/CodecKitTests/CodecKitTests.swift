//
//  CodecKitTests.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//
//  Checked against PUBLISHED vectors wherever one exists — RFC 4648 for
//  Base64, FIPS 180 for the SHA family, and CRC-32's standard check value.
//  A codec that agrees only with itself is not a codec.
//

import XCTest
@testable import CodecKit

final class CodecKitTests: XCTestCase {

    // MARK: - Base64, RFC 4648 §10

    func testBase64MatchesTheRFCVectors() throws {
        let vectors = [("", ""), ("f", "Zg=="), ("fo", "Zm8="), ("foo", "Zm9v"),
                       ("foob", "Zm9vYg=="), ("fooba", "Zm9vYmE="), ("foobar", "Zm9vYmFy")]
        for (plain, encoded) in vectors {
            XCTAssertEqual(Base64.encode(plain), encoded)
            XCTAssertEqual(try Base64.decodeText(encoded), plain)
        }
    }

    func testBase64UrlSafeAlphabet() throws {
        let data = Data([0xFB, 0xFF, 0xBE])
        XCTAssertEqual(Base64.encode(data), "+/++")
        XCTAssertEqual(Base64.encode(data, alphabet: .urlSafe), "-_--")
        // Both decode without being told which they are.
        XCTAssertEqual(try Base64.decode("+/++"), data)
        XCTAssertEqual(try Base64.decode("-_--"), data)
    }

    func testBase64AcceptsUnpaddedAndWrapped() throws {
        XCTAssertEqual(try Base64.decodeText("Zm9vYmE"), "fooba", "padding is optional in the wild")
        XCTAssertEqual(try Base64.decodeText("Zm9v\nYmFy"), "foobar", "base64 arrives wrapped")
    }

    func testBase64RefusesImpossibleLengths() {
        XCTAssertThrowsError(try Base64.decode("Zm9vY"), "5 characters cannot be Base64")
        XCTAssertThrowsError(try Base64.decode("!!!!"))
    }

    // MARK: - Hex

    func testHexRoundTripsAndAcceptsTheWaysPeopleWriteIt() throws {
        XCTAssertEqual(Hex.encode("abc"), "616263")
        XCTAssertEqual(Hex.encode("abc", uppercase: true, separator: " "), "61 62 63")
        for spelling in ["deadbeef", "DE AD BE EF", "de:ad:be:ef", "0xdeadbeef", "\\xde\\xad\\xbe\\xef"] {
            XCTAssertEqual(try Hex.decode(spelling), Data([0xDE, 0xAD, 0xBE, 0xEF]), "\(spelling) failed")
        }
    }

    func testHexRefusesOddDigits() {
        XCTAssertThrowsError(try Hex.decode("abc"))
        XCTAssertThrowsError(try Hex.decode("zz"))
    }

    // MARK: - Percent encoding

    func testComponentScopeEscapesTheStructuralCharacters() throws {
        // Encoding a value with & in it as if it were a URL is how one
        // parameter silently becomes two.
        XCTAssertEqual(PercentEncoding.encode("a&b=c/d?e"), "a%26b%3Dc%2Fd%3Fe")
        XCTAssertEqual(PercentEncoding.encode("hello world"), "hello%20world")
        XCTAssertEqual(try PercentEncoding.decode("a%26b"), "a&b")
    }

    func testPlusIsASpaceBecauseFormsSayItIs() throws {
        XCTAssertEqual(try PercentEncoding.decode("hello+world"), "hello world")
        XCTAssertEqual(try PercentEncoding.decode("a+b", plusIsSpace: false), "a+b")
    }

    // MARK: - HTML entities

    func testEntitiesEncodeWithoutDoubleEscaping() {
        XCTAssertEqual(HTMLEntities.encode("<a href=\"x\">T & Q</a>"),
                       "&lt;a href=&quot;x&quot;&gt;T &amp; Q&lt;/a&gt;")
        // The ampersand it just produced must not be escaped again.
        XCTAssertEqual(HTMLEntities.encode("&"), "&amp;")
        XCTAssertEqual(HTMLEntities.decode(HTMLEntities.encode("a & b < c")), "a & b < c")
    }

    func testEntitiesDecodeNamedAndNumeric() {
        XCTAssertEqual(HTMLEntities.decode("Tom&#8217;s caf&eacute;s &amp; bars"), "Tom\u{2019}s caf&eacute;s & bars",
                       "eacute is outside the carried table and is left alone rather than guessed")
        XCTAssertEqual(HTMLEntities.decode("&#x2014;&mdash;"), "——")
        XCTAssertEqual(HTMLEntities.decode("5 &lt; 10 &amp;&amp; 10 &gt; 5"), "5 < 10 && 10 > 5")
    }

    func testALoneAmpersandSurvives() {
        // Scanning ahead for a semicolon would swallow everything up to one
        // in a later sentence.
        XCTAssertEqual(HTMLEntities.decode("Tom & Jerry; and friends"), "Tom & Jerry; and friends")
        XCTAssertEqual(HTMLEntities.decode("100% & rising"), "100% & rising")
    }

    // MARK: - Escaping

    func testEscapesRoundTrip() throws {
        let awkward = "line\nbreak\ttab \"quoted\" back\\slash"
        XCTAssertEqual(try Escaping.unescape(Escaping.escape(awkward)), awkward)
        XCTAssertEqual(Escaping.escape("a\nb"), "a\\nb")
    }

    func testSurrogatePairsBecomeOneCharacter() throws {
        // JSON writes anything past the BMP as a pair; decoding them
        // separately gives two replacement characters.
        XCTAssertEqual(try Escaping.unescape("\\uD83C\\uDDEC\\uD83C\\uDDE7"), "🇬🇧")
        XCTAssertEqual(try Escaping.unescape("\\u00e9"), "é")
    }

    func testShellQuotingClosesAndReopens() {
        // The only escape a single-quoted shell string has.
        XCTAssertEqual(Escaping.escape("it's", dialect: .shell), "'it'\\''s'")
        XCTAssertEqual(Escaping.escape("plain", dialect: .shell), "'plain'")
    }

    func testTruncatedEscapesAreRefused() {
        XCTAssertThrowsError(try Escaping.unescape("\\u12"))
    }

    // MARK: - JWT

    func testJWTDecodesHeaderAndClaims() throws {
        // The canonical example token from jwt.io.
        let token = """
            eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\
            eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.\
            SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
            """
        let jwt = try JWT.decode(token)
        XCTAssertEqual(jwt.algorithm, "HS256")
        XCTAssertTrue(jwt.payload.contains("John Doe"))
        XCTAssertEqual(jwt.issuedAt, Date(timeIntervalSince1970: 1_516_239_022))
        XCTAssertNil(jwt.isExpired, "this token has no exp, so nothing can be said")
    }

    func testMalformedTokensAreRefused() {
        XCTAssertThrowsError(try JWT.decode("not.a.jwt"))
        XCTAssertThrowsError(try JWT.decode("onlyonepart"))
    }

    // MARK: - Digests, against published vectors

    func testHashesMatchPublishedVectors() {
        XCTAssertEqual(Digest.hash("", using: .md5), "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(Digest.hash("abc", using: .md5), "900150983cd24fb0d6963f7d28e17f72")
        XCTAssertEqual(Digest.hash("abc", using: .sha1), "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual(Digest.hash("abc", using: .sha256),
                       "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual(Digest.hash("abc", using: .sha512).prefix(32), "ddaf35a193617abacc417349ae204131")
        // CRC-32's standard check value.
        XCTAssertEqual(Digest.hash("123456789", using: .crc32), "cbf43926")
    }

    func testEveryAlgorithmProducesItsStatedWidth() {
        for algorithm in HashAlgorithm.allCases {
            XCTAssertEqual(Digest.hash("x", using: algorithm).count, algorithm.width, "\(algorithm)")
        }
    }

    func testStreamingAFileAgreesWithHashingItWhole() throws {
        // The chunked path has to give the same answer as the in-memory one,
        // across a chunk boundary.
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("codec-\(UUID().uuidString).bin")
        defer { try? FileManager.default.removeItem(at: url) }
        let payload = Data((0..<(Digest.chunkSize * 2 + 7)).map { UInt8($0 % 251) })
        try payload.write(to: url)

        for algorithm in HashAlgorithm.allCases {
            XCTAssertEqual(try Digest.hash(contentsOf: url, using: algorithm),
                           Digest.hash(payload, using: algorithm), "\(algorithm) differs when streamed")
        }
    }

    func testComparisonIgnoresCaseAndSpacing() {
        XCTAssertTrue(Digest.matches("ABC123", "abc123"))
        XCTAssertTrue(Digest.matches("ab c1 23", "abc123"), "a checksum copied from a page has spaces in it")
        XCTAssertFalse(Digest.matches("abc123", "abc124"))
    }

    func testWhichAlgorithmsStillProveAnything() {
        XCTAssertFalse(HashAlgorithm.md5.isCryptographic)
        XCTAssertFalse(HashAlgorithm.crc32.isCryptographic)
        XCTAssertTrue(HashAlgorithm.sha256.isCryptographic)
        XCTAssertEqual(HashAlgorithm(name: "SHA-256"), .sha256)
    }
}
