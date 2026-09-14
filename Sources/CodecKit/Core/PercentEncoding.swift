//
//  PercentEncoding.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// URL percent-encoding.
public enum PercentEncoding {

    /// How much of the text is treated as needing escaping.
    public enum Scope: String, Sendable, CaseIterable {
        /// A value going INTO a URL: `&`, `=`, `/` and `?` are all escaped.
        /// This is what you want for a query parameter, and it is the common
        /// case — encoding a whole URL when you meant a parameter is how a
        /// value with an ampersand in it silently becomes two parameters.
        case component
        /// A whole URL: the structural characters are left alone.
        case url
    }

    /// Characters left unescaped in component scope: RFC 3986's unreserved set.
    static let unreserved = CharacterSet(charactersIn:
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    public static func encode(_ text: String, scope: Scope = .component) -> String {
        let allowed = scope == .component ? unreserved : CharacterSet.urlQueryAllowed
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    }

    /// Decodes, and treats `+` as a space.
    ///
    /// `+` is a space in `application/x-www-form-urlencoded`, which is where
    /// most percent-encoded text a person pastes has come from. Foundation
    /// does not do this, so a form value arrives with plus signs in it.
    public static func decode(_ text: String, plusIsSpace: Bool = true) throws -> String {
        let prepared = plusIsSpace ? text.replacingOccurrences(of: "+", with: " ") : text
        guard let decoded = prepared.removingPercentEncoding else {
            throw CodecError.unreadable("percent-encoded text with an invalid escape")
        }
        return decoded
    }
}
