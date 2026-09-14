//
//  JWT.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Reading a JSON Web Token.
///
/// **This decodes. It does NOT verify.** Without the signing key a token's
/// signature cannot be checked, so nothing here says a token is genuine —
/// only what it claims. Treating a decoded token as trusted is the classic
/// JWT mistake, and the type says so rather than leaving it implied.
public struct JWT: Sendable, Equatable {

    /// The header, as JSON text.
    public let header: String
    /// The payload, as JSON text.
    public let payload: String
    /// The signature, still encoded — there is nothing to decode it against.
    public let signature: String

    /// The algorithm the header names, if it names one.
    public let algorithm: String?
    /// Standard time claims, when present.
    public let issuedAt: Date?
    public let expiresAt: Date?
    public let notBefore: Date?

    /// Whether `exp` has passed. Nil when the token does not say.
    public var isExpired: Bool? {
        guard let expiresAt else { return nil }
        return expiresAt < Date()
    }

    public static func decode(_ token: String) throws -> JWT {
        let parts = token.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw CodecError.notAJWT("a JWT has three dot-separated parts; this has \(parts.count)")
        }

        let header = try text(of: parts[0], what: "header")
        let payload = try text(of: parts[1], what: "payload")

        let claims = (try? JSONSerialization.jsonObject(with: Data(payload.utf8))) as? [String: Any] ?? [:]
        let headerFields = (try? JSONSerialization.jsonObject(with: Data(header.utf8))) as? [String: Any] ?? [:]

        return JWT(
            header: header,
            payload: payload,
            signature: String(parts[2]),
            algorithm: headerFields["alg"] as? String,
            issuedAt: date(claims["iat"]),
            expiresAt: date(claims["exp"]),
            notBefore: date(claims["nbf"])
        )
    }

    private static func text(of part: Substring, what: String) throws -> String {
        // A JWT is always URL-safe base64 and usually unpadded, which Base64
        // handles without being told.
        guard let decoded = try? Base64.decodeText(String(part)) else {
            throw CodecError.notAJWT("the \(what) is not valid Base64")
        }
        return decoded
    }

    /// JWT time claims are seconds since the epoch, as a number.
    private static func date(_ value: Any?) -> Date? {
        guard let seconds = value as? Double ?? (value as? Int).map(Double.init) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }
}
