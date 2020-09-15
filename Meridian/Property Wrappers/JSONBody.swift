//
//  JSONBody.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/28/20.
//

import Foundation

@propertyWrapper
public struct JSONBody<Type: Decodable>: PropertyWrapper {

    @ParameterBox var finalValue: Type?

    let decoder: JSONDecoder

    public init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }

    func update<Inner>(_ requestContext: RequestContext, errors: inout [Error]) where Type == Inner? {
        do {
            guard requestContext.header.method != .GET else {
                throw UnexpectedGETRequestError()
            }

            guard let contentType = requestContext.header.headers["Content-Type"], contentType.contains("application/json") else {
                throw JSONContentTypeError()
            }

            guard !requestContext.postBody.isEmpty else {
                self.finalValue = .some(.none)
                return
            }

            self.finalValue = try decoder.decode(Type.self, from: requestContext.postBody)
        } catch let error as DecodingError {
            self.finalValue = nil
            errors.append(JSONBodyDecodingError(type: Type.self, underlyingError: error))
        } catch let error as ReportableError {
            errors.append(error)
            self.finalValue = nil
        } catch {
            errors.append(BasicError(message: "An unknown error occurred in \(JSONBody.self)."))
            self.finalValue = nil
        }
    }
    
    func update(_ requestContext: RequestContext, errors: inout [Error]) {
        do {
            guard requestContext.header.method != .GET else {
                throw UnexpectedGETRequestError()
            }

            guard let contentType = requestContext.header.headers["Content-Type"], contentType.contains("application/json") else {
                throw JSONContentTypeError()
            }

            guard !requestContext.postBody.isEmpty else {
                throw MissingBodyError()
            }

            self.finalValue = try decoder.decode(Type.self, from: requestContext.postBody)
        } catch let error as DecodingError {
            self.finalValue = nil
            errors.append(JSONBodyDecodingError(type: Type.self, underlyingError: error))
        } catch let error as ReportableError {
            errors.append(error)
            self.finalValue = nil
        } catch {
            errors.append(BasicError(message: "An unknown error occurred in \(JSONBody.self).")) // maybe fatal
            self.finalValue = nil
        }

    }

    public var wrappedValue: Type {
        return finalValue!
    }
}

