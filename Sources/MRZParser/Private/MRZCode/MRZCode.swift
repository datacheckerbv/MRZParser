//
//  MRZCode.swift
//
//
//  Created by Roman Mazeev on 20.07.2021.
//

import Foundation

struct MRZCode {
    let format: MRZFormat
    var firstLineRaw: String?
    var documentTypeField: Field
    var countryCodeField: Field
    var documentNumberField: ValidatedField<String>
    var birthdateField: ValidatedField<Date?>
    var sexField: Field
    var expiryDateField: ValidatedField<Date?>
    var nationalityField: Field
    var optionalDataField: ValidatedField<String>
    var optionalData2Field: ValidatedField<String>?
    var namesField: NamesField
    var finalCheckDigit: String

    var isValid: Bool {
        // Special handling for DL (single-line driving license)
        if format == .dl {
            guard !finalCheckDigit.isEmpty, let first = firstLineRaw else { return false }
            // composite is first 29 chars (positions 0..28) and final check digit at position 29
            let prefixLength = min(29, first.count)
            let compositedValue = String(first.prefix(prefixLength))
            let isCompositedValueValid = MRZFieldFormatter.isValueValid(compositedValue, checkDigit: finalCheckDigit)
            let docNumPresent = !documentNumberField.rawValue.trimmingFillers.isEmpty
            return docNumPresent && isCompositedValueValid
        }

        if !finalCheckDigit.isEmpty {
            var fieldsValidate: [ValidatedFieldProtocol] = [ documentNumberField ]

            if format == .td1, let optionalData2Field = optionalData2Field {
                fieldsValidate.append(optionalDataField)
                fieldsValidate.append(contentsOf: [
                    birthdateField,
                    expiryDateField
                ])
                fieldsValidate.append(optionalData2Field)
            } else {
                fieldsValidate.append(contentsOf: [
                    birthdateField,
                    expiryDateField
                ])

                fieldsValidate.append(optionalDataField)
            }

            let compositedValue = fieldsValidate.reduce("", { $0 + $1.rawValue + $1.checkDigit })
            let isCompositedValueValid = MRZFieldFormatter.isValueValid(compositedValue, checkDigit: finalCheckDigit)
            return documentNumberIsValid &&
                birthdateField.isValid &&
                expiryDateField.isValid &&
                isCompositedValueValid
        } else {
            return documentNumberField.isValid &&
                birthdateField.isValid &&
                expiryDateField.isValid
        }
    }
}

private extension MRZCode {
    var documentNumberIsValid: Bool {
        if documentNumberField.isValid {
            return true
        }

        guard format == .td1, ["BEL", "PRT"].contains(countryCodeField.value) else { return false }
        return isExtendedDocumentNumberValid()
    }

    func isExtendedDocumentNumberValid() -> Bool {
        let sanitized = documentNumberField.rawValue.replacingOccurrences(of: "<", with: "")
        guard !sanitized.isEmpty else { return false }
        return MRZFieldFormatter.isValueValid(sanitized, checkDigit: documentNumberField.checkDigit)
    }
}
