//
//  MRZCodeFactory.swift
//
//
//  Created by Roman Mazeev on 14/10/2018.
//

import Foundation

struct MRZCodeFactory {
    func create(
        from mrzLines: [String],
        format: MRZFormat,
        formatter: MRZFieldFormatter
    ) -> MRZCode {
        let firstLine = mrzLines[0]
        let secondLine = mrzLines.count > 1 ? mrzLines[1] : ""

        let documentNumberField: ValidatedField<String>
        let birthdateField: ValidatedField<Date?>
        let sexField: Field
        let expiryDateField: ValidatedField<Date?>
        let nationalityField: Field
        let optionalDataField: ValidatedField<String>
        let optionalData2Field: ValidatedField<String>?
        let namesField: NamesField
        let finalCheckDigit: String

        switch format {
        case .td1:
            // Issuing state (positions 2..4) may change field layout for certain countries (e.g., BEL, PRT)
            let issuing = formatter.createField(from: firstLine, at: 2, length: 3, fieldType: .countryCode).value
            if issuing == "BEL" || issuing == "PRT" {
                // BEL/PRT TD1 variant: document number is longer (13 chars) and has a check digit at pos 18
                let dnField = formatter.createStringValidatedField(
                    from: firstLine,
                    at: 5,
                    length: 13,
                    fieldType: .documentNumber
                )
                // Clean filler characters inside document number (BEL/PRT extended docnum uses '<' as filler)
                let cleaned = dnField.rawValue.replacingOccurrences(of: "<", with: "")
                documentNumberField = ValidatedField(value: cleaned, rawValue: dnField.rawValue, checkDigit: dnField.checkDigit)
                // optional data shifts for BEL/PRT
                optionalDataField = formatter.createStringValidatedField(
                    from: firstLine,
                    at: 19,
                    length: 11,
                    fieldType: .optionalData,
                    checkDigitFollows: false
                )
            } else {
                documentNumberField = formatter.createStringValidatedField(
                    from: firstLine,
                    at: 5,
                    length: 9,
                    fieldType: .documentNumber
                )
                optionalDataField = formatter.createStringValidatedField(
                    from: firstLine,
                    at: 15,
                    length: 15,
                    fieldType: .optionalData,
                    checkDigitFollows: false
                )
            }
            birthdateField = formatter.createDateValidatedField(
                from: secondLine,
                at: 0,
                length: 6,
                fieldType: .birthdate
            )
            sexField = formatter.createField(from: secondLine, at: 7, length: 1, fieldType: .sex)
            expiryDateField = formatter.createDateValidatedField(
                from: secondLine,
                at: 8,
                length: 6,
                fieldType: .expiryDate
            )
            nationalityField = formatter.createField(from: secondLine, at: 15, length: 3, fieldType: .nationality)
            optionalData2Field = formatter.createStringValidatedField(
                from: secondLine,
                at: 18,
                length: 11,
                fieldType: .optionalData,
                checkDigitFollows: false
            )
            finalCheckDigit = formatter.createField(from: secondLine, at: 29, length: 1, fieldType: .hash).rawValue

            let thirdLine = mrzLines[2]
            namesField = formatter.createNamesField(from: thirdLine, at: 0, length: 29)
        case .td2, .td3:
            /// MRV-B and MRV-A types
            let isVisaDocument = firstLine.first == MRZResult.DocumentType.visa.identifier

            documentNumberField = formatter.createStringValidatedField(from: secondLine, at: 0, length: 9, fieldType: .documentNumber
            )
            birthdateField = formatter.createDateValidatedField(
                from: secondLine,
                at: 13,
                length: 6,
                fieldType: .birthdate
            )
            sexField = formatter.createField(from: secondLine, at: 20, length: 1, fieldType: .sex)
            expiryDateField = formatter.createDateValidatedField(
                from: secondLine, at: 21, length: 6, fieldType: .expiryDate
            )
            nationalityField = formatter.createField(from: secondLine, at: 10, length: 3, fieldType: .nationality)

            if format == .td2 {
                optionalDataField = formatter.createStringValidatedField(
                    from: secondLine,
                    at: 28,
                    length: isVisaDocument ? 8 : 7,
                    fieldType: .optionalData,
                    checkDigitFollows: false
                )
                optionalData2Field = nil
                namesField = formatter.createNamesField(from: firstLine, at: 5, length: 31)
                finalCheckDigit = isVisaDocument ? "" : formatter.createField(
                    from: secondLine, at: 35, length: 1, fieldType: .hash
                ).rawValue
            } else {
                optionalDataField = {
                    if isVisaDocument {
                        return formatter.createStringValidatedField(
                            from: secondLine,
                            at: 28,
                            length: 16,
                            fieldType: .optionalData,
                            checkDigitFollows: false
                        )
                    } else {
                        return formatter.createStringValidatedField(
                            from: secondLine, at: 28, length: 14, fieldType: .optionalData
                        )
                    }
                }()
                optionalData2Field = nil
                namesField = formatter.createNamesField(from: firstLine, at: 5, length: 39)
                finalCheckDigit = isVisaDocument ? "" : formatter.createField(
                    from: secondLine,
                    at: 43,
                    length: 1,
                    fieldType: .hash
                ).rawValue
            }
        case .dl:
            let line = firstLine

            documentNumberField = formatter.createStringValidatedField(
                from: line,
                at: 6,
                length: 10,
                fieldType: .documentNumber,
                checkDigitFollows: false
            )

            birthdateField = ValidatedField(value: nil, rawValue: "", checkDigit: "")
            sexField = Field(value: "", rawValue: "")
            expiryDateField = ValidatedField(value: nil, rawValue: "", checkDigit: "")
            nationalityField = formatter.createField(from: line, at: 2, length: 3, fieldType: .nationality)

            optionalDataField = formatter.createStringValidatedField(
                from: line,
                at: 16,
                length: 13,
                fieldType: .optionalData,
                checkDigitFollows: false
            )
            optionalData2Field = nil
            namesField = (surnames: "", givenNames: "")
            finalCheckDigit = formatter.createField(from: line, at: 29, length: 1, fieldType: .hash).rawValue
        }

        return MRZCode(
            format: format,
            firstLineRaw: firstLine,
            documentTypeField: formatter.createField(from: firstLine, at: 0, length: 2, fieldType: .documentType),
            countryCodeField: formatter.createField(from: firstLine, at: 2, length: 3, fieldType: .countryCode),
            documentNumberField: documentNumberField,
            birthdateField: birthdateField,
            sexField: sexField,
            expiryDateField: expiryDateField,
            nationalityField: nationalityField,
            optionalDataField: optionalDataField,
            optionalData2Field: optionalData2Field,
            namesField: namesField,
            finalCheckDigit: finalCheckDigit
        )
    }
}
