//
//  MRZResult.swift
//  
//
//  Created by Roman Mazeev on 15.06.2021.
//

import Foundation

public enum MRZFormat: CaseIterable {
    case td1, td2, td3, dl

    public var lineLength: Int {
        switch self {
        case .td1:
            return 30
        case .td2:
            return 36
        case .td3:
            return 44
        case .dl:
            return 30
        }
    }

    public var linesCount: Int {
        switch self {
        case .td1:
            return 3
        case .td2, .td3:
            return 2
        case .dl:
            return 1
        }
    }
}

public struct MRZResult: Hashable {
    public enum DocumentType: CaseIterable {
        case visa
        case passport
        case drivingLicense
        case id
        case undefined

        var identifier: Character {
            switch self {
            case .visa:
                return "V"
            case .passport:
                return "P"
            case .drivingLicense:
                return "D"
            case .id:
                return "I"
            case .undefined:
                return "_"
            }
        }
    }

    public enum Sex: CaseIterable {
        case male
        case female
        case unspecified

        var identifier: [String] {
            switch self {
            case .male:
                return ["M"]
            case .female:
                return ["F"]
            case .unspecified:
                return ["X", "<", " "]
            }
        }
    }

    public let format: MRZFormat
    public let documentType: DocumentType
    public let documentTypeAdditional: Character?
    public let countryCode: String
    public let surnames: String
    public let givenNames: String
    public let documentNumber: String?
    public let nationalityCountryCode: String
    public let birthdate: Date?
    public let sex: Sex
    public let expiryDate: Date?
    public let optionalData: String?
    /// `nil` if not provided
    public let optionalData2: String?
    /// The raw MRZ lines as parsed (each line as a separate string, in order)
    public let rawMRZLines: [String]
    /// Whether the overall MRZ validation passed
    public let isValid: Bool
    /// Check digit for document number validation
    public let documentNumberCheckDigit: String?
    /// Check digit for birthdate validation
    public let birthdateCheckDigit: String?
    /// Check digit for expiry date validation
    public let expiryDateCheckDigit: String?
    /// Check digit for optional data validation
    public let optionalDataCheckDigit: String?
    /// Check digit for optional data 2 validation (TD1 only)
    public let optionalData2CheckDigit: String?
    /// Composite check digit for overall MRZ validation
    public let compositeCheckDigit: String?

    public init(
        format: MRZFormat,
        documentType: DocumentType,
        documentTypeAdditional: Character?,
        countryCode: String,
        surnames: String,
        givenNames: String,
        documentNumber: String?,
        nationalityCountryCode: String,
        birthdate: Date?,
        sex: Sex,
        expiryDate: Date?,
        optionalData: String?,
        optionalData2: String?,
        rawMRZLines: [String],
        isValid: Bool,
        documentNumberCheckDigit: String?,
        birthdateCheckDigit: String?,
        expiryDateCheckDigit: String?,
        optionalDataCheckDigit: String?,
        optionalData2CheckDigit: String?,
        compositeCheckDigit: String?
    ) {
        self.format = format
        self.documentType = documentType
        self.documentTypeAdditional = documentTypeAdditional
        self.countryCode = countryCode
        self.surnames = surnames
        self.givenNames = givenNames
        self.documentNumber = documentNumber
        self.nationalityCountryCode = nationalityCountryCode
        self.birthdate = birthdate
        self.sex = sex
        self.expiryDate = expiryDate
        self.optionalData = optionalData
        self.optionalData2 = optionalData2
        self.rawMRZLines = rawMRZLines
        self.isValid = isValid
        self.documentNumberCheckDigit = documentNumberCheckDigit
        self.birthdateCheckDigit = birthdateCheckDigit
        self.expiryDateCheckDigit = expiryDateCheckDigit
        self.optionalDataCheckDigit = optionalDataCheckDigit
        self.optionalData2CheckDigit = optionalData2CheckDigit
        self.compositeCheckDigit = compositeCheckDigit
    }
}

