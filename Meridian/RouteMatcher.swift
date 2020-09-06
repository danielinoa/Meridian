//
//  RouteMatcher.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

public struct MatchedRoute {
    let parameters: [String: Substring]

    public init(parameters: [String: Substring] = [:]) {
        self.parameters = parameters
    }

    public func parameter<Key: URLParameterKey>(for key: Key.Type) throws -> Key.DecodeType {
        guard let substring = self.parameters[Key.stringKey] else {
            throw MissingURLParameterError()
        }
        let value = String(substring)
        if Key.DecodeType.self == String.self {
            return value as! Key.DecodeType
        } else if let finalValue = Key.DecodeType(value) {
            return finalValue
        } else {
            throw URLParameterDecodingError(type: Key.DecodeType.self)
        }

    }
}

public struct RouteMatcher {
    public let matches: (RequestHeader) -> MatchedRoute?

    public static func path(_ string: String) -> RouteMatcher {
        RouteMatcher(matches: { header in
            if (header.path == string) {
                return MatchedRoute()
            } else {
                return nil
            }
        })
    }

    public static let root = RouteMatcher.path("")

    public static let any = RouteMatcher(matches: { _ in MatchedRoute() })

    public static func method(_ method: HTTPMethod, _ matcher: RouteMatcher) -> RouteMatcher {
        RouteMatcher(matches: { header in
            if header.method == method {
                return matcher.matches(header)
            }
            return nil
        })
    }

    public static func get(_ matcher: RouteMatcher) -> RouteMatcher {
        self.method(.GET, matcher)
    }

    public static func post(_ matcher: RouteMatcher) -> RouteMatcher {
        self.method(.POST, matcher)
    }

    public static func patch(_ matcher: RouteMatcher) -> RouteMatcher {
        self.method(.PATCH, matcher)
    }

    public static func delete(_ matcher: RouteMatcher) -> RouteMatcher {
        self.method(.DELETE, matcher)
    }
}

extension RouteMatcher: ExpressibleByStringInterpolation {

    public struct RegexMatcher: StringInterpolationProtocol {

        var regexString = ""

        var mapping: [String] = []

        public init(literalCapacity: Int, interpolationCount: Int) {

        }

        mutating public func appendLiteral(_ literal: String) {
            regexString.append(literal) // escape for regex
        }

        public mutating func appendInterpolation<SpecificKey: URLParameterKey>(_ urlParameter: KeyPath<ParameterKeys, SpecificKey>) {

            regexString.append("([^/]+)")

            mapping.append(SpecificKey.stringKey)
        }
    }

    public init(stringLiteral value: String) {
        self = Self.path(value)
    }

    public init(stringInterpolation: RegexMatcher) {
        let regex = try! NSRegularExpression(pattern: "^\(stringInterpolation.regexString)$")

        self.matches = { header in
            let matches = regex.matches(in: header.path, range: NSRange(location: 0, length: header.path.utf16.count))

            if matches.isEmpty {
                return nil
            }

            var result: [String: Substring] = [:]

            for match in matches {
                let ranges = (0..<match.numberOfRanges)
                    .dropFirst() /*ignore the first match*/
                    .map({ match.range(at: $0) })

                zip(stringInterpolation.mapping, ranges).forEach({ urlParameterName, range in
                    guard let betterRange = Range(range, in: header.path) else { fatalError("Should be able to convert ranges") }
                    result[urlParameterName] = header.path[betterRange]
                })
            }

            return MatchedRoute(parameters: result)
        }
    }
}

extension RouteMatcher: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: RouteMatcher...) {
        self.matches = { header in
            elements.lazy.compactMap({ $0.matches(header) }).first
        }
    }
}
