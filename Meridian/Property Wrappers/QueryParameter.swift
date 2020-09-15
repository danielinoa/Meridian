//
//  QueryParameter.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

//protocol OptionalType {
//    associatedtype WrappedType
//
//    var optionalValue: WrappedType?
//}


public struct Present: Codable {
    public init() {

    }
}

extension Optional where Wrapped == Present {
    public var isPresent: Bool {
        self != nil
    }

    public var isNotPresent: Bool {
        self == nil
    }
}

private struct Holder<Contained: Decodable>: Decodable {
    let value: Contained
}

@propertyWrapper
public struct QueryParameter<Type: Decodable>: PropertyWrapper {

    @ParameterBox var finalValue: Type?

    let key: String

    public init(_ key: String) {
        self.key = key
    }

    func update<Inner>(_ requestContext: RequestContext, errors: inout [Error]) where Type == Inner? {
        guard let queryItem = requestContext.queryParameters.first(where: { $0.name == key }) else {
            self.finalValue = .some(.none)
            return
        }
        if Inner.self == Present.self {
            self.finalValue = Present?.some(Present()) as? Type
        } else if let value = queryItem.value {
            if Inner.self == String.self {
                self.finalValue = String?.some(value) as? Type
                return
            }
            do {
                let newString = "{\"value\": " + value + " }"
                let decoder = JSONDecoder()
                self.finalValue = try decoder.decode(Holder<Inner>.self, from: newString.data(using: .utf8)!).value
            } catch {
                do {
                    let newString = "{\"value\": \"" + value + "\" }"
                    let decoder = JSONDecoder()
                    self.finalValue = try decoder.decode(Holder<Type>.self, from: newString.data(using: .utf8)!).value
                } catch {
                    self.finalValue = nil
                    errors.append(QueryParameterDecodingError(type: Type.self, key: key))
                }
            }
        } else {
            self.finalValue = nil
            errors.append(NoValueQueryParameterError(key: key)) // this is maybe fatal
        }
    }

    @_disfavoredOverload
    func update(_ requestContext: RequestContext, errors: inout [Error]) {
        guard let queryItem = requestContext.queryParameters.first(where: { $0.name == key }) else {
            errors.append(MissingQueryParameterError(key: key))
            self.finalValue = nil
            return
        }
        if Type.self == Present.self {
            self.finalValue = Present() as? Type
        } else if let value = queryItem.value {

            do {
                let newString = "{\"value\": " + value + " }"
                let decoder = JSONDecoder()
                self.finalValue = try decoder.decode(Holder<Type>.self, from: newString.data(using: .utf8)!).value
            } catch {
                do {
                    let newString = "{\"value\": \"" + value + "\" }"
                    let decoder = JSONDecoder()
                    self.finalValue = try decoder.decode(Holder<Type>.self, from: newString.data(using: .utf8)!).value
                } catch {
                    self.finalValue = nil
                    errors.append(QueryParameterDecodingError(type: Type.self, key: key))
                }
            }
        } else {
            self.finalValue = nil
            errors.append(NoValueQueryParameterError(key: key)) // this is maybe fatal
        }
    }

    public var wrappedValue: Type {
        return finalValue!
    }
}
