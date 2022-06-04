//
//  ImageProcessor.swift
//  WatermarkBuilder
//
//  Created by Alfred Lapkovsky on 21/05/2022.
//

import Foundation


class ImageProcessor {
    
    static let shared = ImageProcessor()
    
    private let endpointURL = URL(string: "https://watermark-builder.herokuapp.com/api/watermark")!
    
    private init() {
    }
    
    func processImage(_ imageData: ImageData, params: TextWatermarkParams) async throws -> Data {
        try await processImage(composeTextWatermarkRequest(imageData, params: params))
    }
    
    func processImage(_ imageData: ImageData, params: CustomWatermarkParams) async throws -> Data {
        try await processImage(composeCustomWatermarkRequest(imageData, params: params))
    }
    
    private func processImage(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let response = response as? HTTPURLResponse else {
                throw Error.generic()
            }
            
            guard response.statusCode == 200 else {
                let errorCodes = try JSONDecoder().decode(ApiErrorCodes.self, from: data)
                throw Error(errorCodes)
            }
            
            return data
        }
        catch {
            throw error is Error ? error : Error.generic()
        }
    }
    
    private func composeTextWatermarkRequest(_ imageData: ImageData, params: TextWatermarkParams) -> URLRequest {
        let boundary = ProcessInfo.processInfo.globallyUniqueString
        
        var request        = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue(composeMultipartContentType(boundary: boundary), forHTTPHeaderField: "Content-Type")
        
        let httpBody = NSMutableData()
        
        httpBody.append(composeMultipartFileField(fieldName: "picture", fileName: imageData.name, mimeType: imageData.mimeType, fileData: imageData.data, boundary: boundary))
        httpBody.append(string: composeMultipartTextField(name: "text", value: params.text, boundary: boundary))
        
        if let fontSize = params.fontSize {
            httpBody.append(string: composeMultipartTextField(name: "font_size", value: fontSize, boundary: boundary))
        }
        if let fontFamily = params.fontFamily {
            httpBody.append(string: composeMultipartTextField(name: "font_family", value: fontFamily, boundary: boundary))
        }
        if let densityLevel = params.densityLevel {
            httpBody.append(string: composeMultipartTextField(name: "density_level", value: densityLevel.rawValue, boundary: boundary))
        }
        if let color = params.color {
            httpBody.append(string: composeMultipartTextField(name: "color", value: color, boundary: boundary))
        }
        if let opacity = params.opacity {
            httpBody.append(string: composeMultipartTextField(name: "opacity", value: opacity, boundary: boundary))
        }
        if let rotationAngle = params.rotationAngle {
            httpBody.append(string: composeMultipartTextField(name: "rotation_angle", value: rotationAngle, boundary: boundary))
        }
        if let isFontItalic = params.isFontItalic {
            httpBody.append(string: composeMultipartTextField(name: "font_italic", value: isFontItalic, boundary: boundary))
        }
        if let fontWeight = params.fontWeight {
            httpBody.append(string: composeMultipartTextField(name: "font_weight", value: fontWeight.rawValue, boundary: boundary))
        }
        if let shadowOpacity = params.shadowOpacity {
            httpBody.append(string: composeMultipartTextField(name: "shadow_opacity", value: shadowOpacity, boundary: boundary))
        }
        if let shadowBlurRadius = params.shadowBlurRadius {
            httpBody.append(string: composeMultipartTextField(name: "shadow_blur_radius", value: shadowBlurRadius, boundary: boundary))
        }
        if let shadowOffsetX = params.shadowOffsetX {
            httpBody.append(string: composeMultipartTextField(name: "shadow_offset_x", value: shadowOffsetX, boundary: boundary))
        }
        if let shadowOffsetY = params.shadowOffsetY {
            httpBody.append(string: composeMultipartTextField(name: "shadow_offset_y", value: shadowOffsetY, boundary: boundary))
        }
        if let shadowColor = params.shadowColor {
            httpBody.append(string: composeMultipartTextField(name: "shadow_color", value: shadowColor, boundary: boundary))
        }
        if let fontDecorations = params.fontDecorations {
            httpBody.append(string: composeMultipartTextField(name: "font_decorations", value: String(fontDecorations), boundary: boundary))
        }
        if let strokeColor = params.strokeColor {
            httpBody.append(string: composeMultipartTextField(name: "stroke_color", value: strokeColor, boundary: boundary))
        }
        if let strokeOpactity = params.strokeOpacity {
            httpBody.append(string: composeMultipartTextField(name: "stroke_opacity", value: strokeOpactity, boundary: boundary))
        }
        
        httpBody.append(string: "--\(boundary)--")
        
        request.httpBody = httpBody as Data
        
        return request
    }
    
    private func composeCustomWatermarkRequest(_ imageData: ImageData, params: CustomWatermarkParams) -> URLRequest {
        let boundary = ProcessInfo.processInfo.globallyUniqueString
        
        var request        = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue(composeMultipartContentType(boundary: boundary), forHTTPHeaderField: "Content-Type")
        
        let httpBody = NSMutableData()
        
        httpBody.append(composeMultipartFileField(fieldName: "picture", fileName: imageData.name, mimeType: imageData.mimeType, fileData: imageData.data, boundary: boundary))
        httpBody.append(composeMultipartFileField(fieldName: "watermark", fileName: params.imageData.name, mimeType: params.imageData.mimeType, fileData: params.imageData.data, boundary: boundary))
        
        if let opacity = params.opacity {
            httpBody.append(string: composeMultipartTextField(name: "opacity", value: opacity, boundary: boundary))
        }
        if let rotationAngle = params.rotationAngle {
            httpBody.append(string: composeMultipartTextField(name: "rotation_angle", value: rotationAngle, boundary: boundary))
        }
        if let densityLevel = params.densityLevel {
            httpBody.append(string: composeMultipartTextField(name: "density_level", value: densityLevel.rawValue, boundary: boundary))
        }
        
        httpBody.append(string: "--\(boundary)--")
        
        request.httpBody = httpBody as Data
        
        return request
    }
    
    private func composeMultipartContentType(boundary: String) -> String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    private func composeMultipartTextField(name: String, value: AnyHashable, boundary: String) -> String {
        "--\(boundary)\r\n"
            .appending("Content-Disposition: form-data; name=\"\(name)\"\r\n")
            .appending("\r\n")
            .appending("\(value)\r\n")
    }
    
    private func composeMultipartFileField(fieldName: String, fileName: String, mimeType: String, fileData: Data, boundary: String) -> Data {
        let mutableData = NSMutableData()
        mutableData.append(string: "--\(boundary)\r\n")
        mutableData.append(string: "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        mutableData.append(string: "Content-Type: \(mimeType)\r\n\r\n")
        mutableData.append(fileData)
        mutableData.append(string: "\r\n")
        return mutableData as Data
    }
    
    struct TextWatermarkParams {
        var text            : String
        var fontFamily      : String?
        var fontSize        : Int?
        var densityLevel    : DensityLevel?
        var color           : String?
        var opacity         : Double?
        var rotationAngle   : Int?
        var isFontItalic    : Bool?
        var fontWeight      : FontWeight?
        var shadowOpacity   : Double?
        var shadowBlurRadius: Int?
        var shadowOffsetX   : Int?
        var shadowOffsetY   : Int?
        var shadowColor     : String?
        var fontDecorations : FontDecorations?
        var strokeColor     : String?
        var strokeOpacity   : Double?
    }
    
    struct CustomWatermarkParams {
        var imageData    : ImageData
        var opacity      : Double?
        var rotationAngle: Int?
        var densityLevel : DensityLevel?
    }
    
    struct ImageData {
        let data    : Data
        let mimeType: String
        let name    : String
    }
    
    enum DensityLevel : Int, CaseIterable {
        case min    = 1
        case low    = 2
        case medium = 3
        case high   = 4
        case max    = 5
    }
    
    enum FontWeight : Int, CaseIterable {
        case w100 = 100
        case w200 = 200
        case w300 = 300
        case w400 = 400
        case w500 = 500
        case w600 = 600
        case w700 = 700
        case w800 = 800
        case w900 = 900
    }
    
    struct FontDecorations: OptionSet {
        let rawValue: OptionBits
        
        static let underline   = FontDecorations(rawValue: 1 << 0)
        static let lineThrough = FontDecorations(rawValue: 1 << 1)
    }
    
    struct Error : Swift.Error {
        let message: String
        
        private static let genericMessage                     = "Pieprasījums neizdevās. Lūdzu, pamēģiniet vēlreiz vēlāk."
        private static let invalidWatermarkTextMessage        = "Nederīgs ūdenszīmes teksts."
        private static let invalidImageBufferMessage          = "Nederīgi attēla dati."
        private static let invalidWatermarkImageBufferMessage = "Nederīgi ūdenszīmes attēla dati."
        private static let tooManyFieldsMessage               = "Pārāk daudz pieprasījuma lauku."
        private static let tooManyFilesMessage                = "Pārāk daudz pieprasījuma failu."
        private static let fileTooLargeMessage                = "Fails ir pārāk liels."
        private static let fieldNameTooLongMessage            = "Pieprasījuma lauka nosaukums ir pārāk garš."
        private static let fieldTooLongMessage                = "Pieprasījuma lauka vērtība ir pārāk gara."
        private static let invalidFileType                    = "Nederīgs faila tips."
        private static let noPictureProvided                  = "Attēls nav sniegts."
        private static let noWatermarkDataProvided            = "Nav nodrošināta ūdenszīme."
        
        fileprivate init(_ message: String) {
            self.message = message
        }
        
        fileprivate init(_ errorCodes: ApiErrorCodes) {
            let message = errorCodes.errorCodes.reduce(into: "") { result, errorCode in
                switch errorCode.code {
                case ApiErrorCode.codeGeneric                    : result += Self.genericMessage
                case ApiErrorCode.codeInvalidWatermarkText       : result += Self.invalidWatermarkTextMessage
                case ApiErrorCode.codeInvalidImageBuffer         : result += Self.invalidImageBufferMessage
                case ApiErrorCode.codeInvalidWatermarkImageBuffer: result += Self.invalidWatermarkImageBufferMessage
                case ApiErrorCode.codeTooManyFields              : result += Self.tooManyFieldsMessage
                case ApiErrorCode.codeTooManyFiles               : result += Self.tooManyFilesMessage
                case ApiErrorCode.codeFileTooLarge               : result += Self.fileTooLargeMessage
                case ApiErrorCode.codeFieldNameTooLong           : result += Self.fieldNameTooLongMessage
                case ApiErrorCode.codeFieldTooLong               : result += Self.fieldTooLongMessage
                case ApiErrorCode.codeInvalidFileType            : result += Self.invalidFileType
                case ApiErrorCode.codeNoPictureProvided          : result += Self.noPictureProvided
                case ApiErrorCode.codeNoWatermarkDataProvided    : result += Self.noWatermarkDataProvided
                default:
                    return
                }
                
                result += "\n"
            }
            
            self.message = !message.isEmpty ? message : Self.genericMessage
        }
        
        static fileprivate func generic() -> Error {
            return Error(Self.genericMessage)
        }
    }
    
    fileprivate struct ApiErrorCodes: Decodable {
        let errorCodes: [ApiErrorCode]
    }
    
    fileprivate struct ApiErrorCode : Decodable {
        static let codeGeneric                     = 1
        static let codeInvalidWatermarkText        = 2
        static let codeInvalidImageBuffer          = 3
        static let codeInvalidWatermarkImageBuffer = 4
        static let codeTooManyFields               = 5
        static let codeTooManyFiles                = 6
        static let codeFileTooLarge                = 7
        static let codeFieldNameTooLong            = 8
        static let codeFieldTooLong                = 9
        static let codeInvalidFileType             = 10
        static let codeNoPictureProvided           = 11
        static let codeNoWatermarkDataProvided     = 12
        
        let code: Int
        let data: String?
    }
}

private extension String {
    
    init(_ fontDecorations: ImageProcessor.FontDecorations) {
        self = ""

        if fontDecorations.contains(.underline) {
            self += "u"
        }
        if fontDecorations.contains(.lineThrough) {
            self += "t"
        }
    }
}

private extension NSMutableData {
    
    func append(string: String) {
        guard let data = string.data(using: .utf8) else { return }
        
        append(data)
    }
}
