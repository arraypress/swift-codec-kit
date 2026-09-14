//
//  CodecError.swift
//  CodecKit
//
//  Created by David Sherlock on 2026.
//

import Foundation

public enum CodecError: Error, LocalizedError, Equatable, Sendable {
    case notBase64(String)
    case notHex(String)
    case notUTF8
    case notAJWT(String)
    case unreadable(String)

    public var errorDescription: String? {
        switch self {
        case .notBase64(let why): "not valid Base64: \(why)"
        case .notHex(let why): "not valid hex: \(why)"
        case .notUTF8: "the bytes are not valid UTF-8 text"
        case .notAJWT(let why): "not a JWT: \(why)"
        case .unreadable(let what): "could not read \(what)"
        }
    }
}
