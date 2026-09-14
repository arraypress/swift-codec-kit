# Swift Codec Kit

Base64, hex, percent-encoding, HTML entities, backslash escapes, JWT decoding
and digests — as plain functions, on any Apple platform.

```swift
import CodecKit

Base64.encode("hello")                       // "aGVsbG8="
try Base64.decodeText("aGVsbG8")             // "hello" — padding optional
try Hex.decode("DE AD BE EF")                // 4 bytes
PercentEncoding.encode("a&b=c")              // "a%26b%3Dc"
HTMLEntities.decode("Tom&#8217;s")           // "Tom’s"
try Escaping.unescape("\\uD83C\\uDDEC\\uD83C\\uDDE7")  // "🇬🇧"
try JWT.decode(token).expiresAt              // a Date, if the token says
Digest.hash("abc", using: .sha256)           // "ba7816bf…"
try Digest.hash(contentsOf: url, using: .sha256)       // streamed, any size
```

## Why

Every one of these is a few lines that people write differently each time, and
several of the versions are wrong at an edge:

| Question | The wrong answer, and why it is tempting |
|---|---|
| Decode `aGVsbG8` | Foundation returns nil: it requires padding, and half the base64 in the world has none. |
| Decode a JWT part | Same problem, plus the URL-safe alphabet — `-` and `_` are not `+` and `/`. |
| Decode `hello+world` | `+` is a space in form encoding. `removingPercentEncoding` leaves it as a plus. |
| Encode `a&b` for a URL | `urlQueryAllowed` permits `&` and `=`, so one parameter quietly becomes two. |
| Decode `Tom & Jerry; and co` | Scanning ahead for a `;` swallows the rest of the sentence. |
| Decode `🇬🇧` | Two surrogates decoded separately give two replacement characters, not 🇬🇧. |
| Hash a 40 GB disk image | `Data(contentsOf:)` needs it all in memory. |

`HTMLEntities` exists because ten repositories in this fleet were each
carrying a partial copy.

## Installation

```swift
.package(url: "https://github.com/arraypress/swift-codec-kit.git", from: "0.1.0")
```

CryptoKit and Foundation only. No third-party dependencies, macOS 14+.

## Digests

`md5`, `sha1`, `sha256`, `sha384`, `sha512` and `crc32`. Files are read a
megabyte at a time, so size is not a limit.

`HashAlgorithm.isCryptographic` reports whether a choice still proves
anything: MD5 and SHA-1 have practical collision attacks and CRC-32 is not a
cryptographic hash at all. They are here because existing manifests use them.

## JWT

`JWT.decode` **decodes; it does not verify.** Without the signing key a
signature cannot be checked, so nothing here says a token is genuine — only
what it claims.

## Tests

22 tests, checked against published vectors: RFC 4648 for Base64, FIPS 180 for
the SHA family, and CRC-32's standard check value. A codec that agrees only
with itself is not a codec.

## Licence

MIT.
