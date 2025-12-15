//
//  MRZParser.swift
//
//
//  Created by Roman Mazeev on 15.06.2021.
//

import Foundation

public struct MRZParser {
    private let formatter: MRZFieldFormatter
    private let debug: Bool

    public init(isOCRCorrectionEnabled: Bool, debug: Bool = false) {
        formatter = MRZFieldFormatter(isOCRCorrectionEnabled: isOCRCorrectionEnabled)
        self.debug = debug
    }

    init(formatter: MRZFieldFormatter) {
        self.formatter = formatter
        self.debug = false
    }

    // MARK: Parsing
    public func parse(mrzLines: [String]) -> MRZResult? {
        guard let format = mrzFormat(from: mrzLines) else { return nil }

        let mrzCode: MRZCode = MRZCodeFactory().create(
            from: mrzLines,
            format: format,
            formatter: formatter
        )

        let documentTypeRaw = mrzCode.documentTypeField.rawValue
        let documentType = MRZResult.DocumentType.allCases.first { $0.identifier == documentTypeRaw.first } ?? .undefined
        let additional: Character? = (documentTypeRaw.count == 2) ? documentTypeRaw.last : nil
        let documentTypeAdditional: Character? = {
            guard let c = additional else { return nil }
            if c == "<" || c == " " { return nil }
            return c
        }()
        let optionalData = sanitizedOptionalData(
            field: mrzCode.optionalDataField,
            documentType: documentType,
            format: format
        )
        let optionalData2 = mrzCode.optionalData2Field.map { field in
            sanitizedOptionalData(field: field, documentType: documentType, format: format)
        }

        let result = MRZResult(
            format: format,
            documentType: documentType,
            documentTypeAdditional: documentTypeAdditional,
            countryCode: mrzCode.countryCodeField.value,
            surnames: mrzCode.namesField.surnames,
            givenNames: mrzCode.namesField.givenNames,
            documentNumber: mrzCode.documentNumberField.value,
            nationalityCountryCode: mrzCode.nationalityField.value,
            birthdate: mrzCode.birthdateField.value,
            sex: MRZResult.Sex.allCases.first(where: {
                $0.identifier.contains(mrzCode.sexField.value)
            }) ?? .unspecified,
            expiryDate: mrzCode.expiryDateField.value,
            optionalData: optionalData,
            optionalData2: optionalData2,
            rawMRZLines: mrzLines,
            isValid: mrzCode.isValid,
            documentNumberCheckDigit: mrzCode.documentNumberField.checkDigit.isEmpty ? nil : mrzCode.documentNumberField.checkDigit,
            birthdateCheckDigit: mrzCode.birthdateField.checkDigit.isEmpty ? nil : mrzCode.birthdateField.checkDigit,
            expiryDateCheckDigit: mrzCode.expiryDateField.checkDigit.isEmpty ? nil : mrzCode.expiryDateField.checkDigit,
            optionalDataCheckDigit: mrzCode.optionalDataField.checkDigit.isEmpty ? nil : mrzCode.optionalDataField.checkDigit,
            optionalData2CheckDigit: mrzCode.optionalData2Field?.checkDigit.isEmpty == false ? mrzCode.optionalData2Field?.checkDigit : nil,
            compositeCheckDigit: mrzCode.finalCheckDigit.isEmpty ? nil : mrzCode.finalCheckDigit
        )
        
        if debug {
            printDebugInfo(for: mrzCode, result: result)
        }
        
        return result
    }

    public func parse(mrzString: String) -> MRZResult? {
        return parse(mrzLines: mrzString.components(separatedBy: "\n"))
    }

    // MARK: MRZ-Format detection
    private func mrzFormat(from mrzLines: [String]) -> MRZFormat? {
        switch mrzLines.count {
        case MRZFormat.td2.linesCount,  MRZFormat.td3.linesCount:
            return [.td2, .td3].first(where: { $0.lineLength == uniformedLineLength(for: mrzLines) })
        case MRZFormat.td1.linesCount:
            return (uniformedLineLength(for: mrzLines) == MRZFormat.td1.lineLength) ? .td1 : nil
        case MRZFormat.dl.linesCount:
            return (uniformedLineLength(for: mrzLines) == MRZFormat.dl.lineLength) ? .dl : nil
        default:
            return nil
        }
    }

    private func uniformedLineLength(for mrzLines: [String]) -> Int? {
        guard let lineLength = mrzLines.first?.count,
              !mrzLines.contains(where: { $0.count != lineLength }) else { return nil }
        return lineLength
    }

    private func sanitizedOptionalData(
        field: ValidatedField<String>,
        documentType: MRZResult.DocumentType,
        format: MRZFormat
    ) -> String {
        guard format == .td1, documentType == .id else { return field.value }

        let trimmed = field.rawValue.replacingOccurrences(of: "<", with: "")
        guard !trimmed.isEmpty,
              CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: trimmed)) else {
            return field.value
        }

        return ""
    }
    
    private func printDebugInfo(for mrzCode: MRZCode, result: MRZResult) {
        print("\n=== MRZ Debug Info ===")
        print("Valid: \(result.isValid)")
        print("Format: \(result.format)")
        
        // Document Number
        if let parsed = result.documentNumberCheckDigit {
            let calculated = MRZFieldFormatter.checkDigit(for: mrzCode.documentNumberField.rawValue).map(String.init) ?? "?"
            let match = parsed == calculated ? "✓" : "✗"
            print("Document Number Check Digit: \(match) Parsed=\(parsed) Calculated=\(calculated)")
        }
        
        // Birthdate
        if let parsed = result.birthdateCheckDigit {
            let calculated = MRZFieldFormatter.checkDigit(for: mrzCode.birthdateField.rawValue).map(String.init) ?? "?"
            let match = parsed == calculated ? "✓" : "✗"
            print("Birthdate Check Digit: \(match) Parsed=\(parsed) Calculated=\(calculated)")
        }
        
        // Expiry Date
        if let parsed = result.expiryDateCheckDigit {
            let calculated = MRZFieldFormatter.checkDigit(for: mrzCode.expiryDateField.rawValue).map(String.init) ?? "?"
            let match = parsed == calculated ? "✓" : "✗"
            print("Expiry Date Check Digit: \(match) Parsed=\(parsed) Calculated=\(calculated)")
        }
        
        // Optional Data
        if let parsed = result.optionalDataCheckDigit {
            let calculated = MRZFieldFormatter.checkDigit(for: mrzCode.optionalDataField.rawValue).map(String.init) ?? "?"
            let match = parsed == calculated ? "✓" : "✗"
            print("Optional Data Check Digit: \(match) Parsed=\(parsed) Calculated=\(calculated)")
        }
        
        // Optional Data 2 (TD1 only)
        if let parsed = result.optionalData2CheckDigit {
            let calculated = mrzCode.optionalData2Field.flatMap { MRZFieldFormatter.checkDigit(for: $0.rawValue).map(String.init) } ?? "?"
            let match = parsed == calculated ? "✓" : "✗"
            print("Optional Data 2 Check Digit: \(match) Parsed=\(parsed) Calculated=\(calculated)")
        }
        
        // Composite
        if let parsed = result.compositeCheckDigit {
            var fieldsValidate: [ValidatedFieldProtocol] = [ mrzCode.documentNumberField ]
            
            if mrzCode.format == .td1, let optionalData2Field = mrzCode.optionalData2Field {
                fieldsValidate.append(mrzCode.optionalDataField)
                fieldsValidate.append(contentsOf: [
                    mrzCode.birthdateField,
                    mrzCode.expiryDateField
                ])
                fieldsValidate.append(optionalData2Field)
            } else {
                fieldsValidate.append(contentsOf: [
                    mrzCode.birthdateField,
                    mrzCode.expiryDateField
                ])
                fieldsValidate.append(mrzCode.optionalDataField)
            }
            
            let compositedValue = fieldsValidate.reduce("", { $0 + $1.rawValue + $1.checkDigit })
            let calculated = MRZFieldFormatter.checkDigit(for: compositedValue).map(String.init) ?? "?"
            let match = parsed == calculated ? "✓" : "✗"
            print("Composite Check Digit: \(match) Parsed=\(parsed) Calculated=\(calculated)")
        }
        
        print("======================\n")
    }
}

