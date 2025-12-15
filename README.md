[![Build and test](https://github.com/datacheckerbv/MRZParser/actions/workflows/Build%20and%20test.yml/badge.svg)](https://github.com/datacheckerbv/MRZParser/actions/workflows/Build%20and%20test.yml)
[![codecov](https://codecov.io/gh/appintheair/MRZParser/branch/develop/graph/badge.svg?token=XS5F9MtSfq)](https://codecov.io/gh/appintheair/MRZParser)
[![spm](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://github.com/datacheckerbv/MRZParser/blob/develop/Package.swift)

# MRZParser

Powerful [MRZ](https://en.wikipedia.org/wiki/Machine-readable_passport) code parser supporting a wide range of travel and identity documents:

- TD1 (ID cards, including country-specific layouts and extended document numbers for BEL/PRT)
- TD2 (ID cards)
- TD3 (Passports)
- MRVA/MRVB (Visas type A/B)
- Driving Licenses (DL, ISO/IEC 18013-1 format)

## Features

- **Comprehensive document support**: Parses MRZs from passports, ID cards (TD1/TD2), visas, and driving licenses.
- **Country-specific logic**: Handles special layouts, such as 13-character document numbers for Belgium (BEL) and Portugal (PRT) TD1 ID cards.
- **Robust validation**: Check digit and field validation per ICAO 9303 and ISO 18013-1 standards. Parser returns results even for invalid MRZ with `isValid` flag to indicate validation status.
- **Check digit transparency**: All check digits (document number, birthdate, expiry date, composite) are exposed in `MRZResult` for custom validation or audit purposes.
- **Debug mode**: Enable debug flag to print check digit comparisons (parsed vs. calculated) to console, helping identify validation issues.
- **Optional data sanitization**: Sensitive personal IDs in TD1 optional fields are blanked for privacy (e.g., NLD BSN).
- **Raw MRZ access**: The parser output (`MRZResult`) includes the original MRZ lines as parsed (`rawMRZLines`).
- **Battle-tested**: Extensive test suite, including all real-world and edge cases.

## Fields Distribution of Official Travel Documents

![image](https://raw.githubusercontent.com/appintheair/MRZParser/develop/docs/img/Fields_Distribution.png)

### Fields description

Field | TD1 description | TD2 description | TD3 description | MRVA description | MRVB description | DL description
----- | --------------- | --------------- | --------------- | ---------------- | ---------------- | --------------
Document type | The first letter shall be 'I', 'A' or 'C' |  <- | Normally 'P' for passport | The First letter must be 'V' | <- | The first letter shall be 'D' (for Driving License)
Country code | 3 letters code (ISO 3166-1) or country name (in English) | <- | <- | <- | <- | 3 letters code (ISO 3166-1)
Document number | Document number | <- | <- | <- | <- | Document number (up to 25 chars, ISO/IEC 18013-1)
Birth date | Format: YYMMDD | <- | <- | <- | <- | Format: YYMMDD
Sex | Genre. Male: 'M', Female: 'F' or Undefined: 'X', "<" or "" | <- | <- | <- | <- | 'M', 'F', 'X', '<' or ''
Expiry date  | Format: YYMMDD | <- | <- | <- | <- | Format: YYMMDD
Nationality | 3 letters code (ISO 3166-1) or country name (in English) | <- | <- | <- | <- | 3 letters code (ISO 3166-1)
Surname | Holder primary identifier(s) | <- | Primary identifier(s) | <- | <- | Holder primary identifier(s)
Given names | Holder secondary identifier(s) | <- | Secondary identifier(s) | <- | <- | Holder secondary identifier(s)
Optional data | Optional personal data at the discretion of the issuing State. Non-mandatory field. | <- | Personal number. In some countries non-mandatory field. | Optional personal data at the discretion of the issuing State. Non-mandatory field. | <- | Optional personal data at the discretion of the issuing State. Non-mandatory field.
Optional data 2 | Optional personal data at the discretion of the issuing State. Non-mandatory field. | X | X | X | X | X

## Installation guide

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/appintheair/MRZParser.git", .upToNextMajor(from: "1.1.2"))
]
```

## Usage

The parser is able to validate the MRZ string and parse the MRZ code. Let's start by initializing our parser.

```swift
let parser = MRZParser(isOCRCorrectionEnabled: true)
```

For parsing, we use the `parse` method which returns the `MRZResult` structure with all the necessary data, including the original MRZ lines, check digits, and validation status:

```swift
let result = parser.parse(mrzString: mrzString)
print(result?.isValid) // true or false
print(result?.rawMRZLines) // ["I<UTOD231458907<<<<<<<<<<<<<<<", ...]
print(result?.documentNumberCheckDigit) // "7"
print(result?.compositeCheckDigit) // "6"
```

### Debugging Check Digit Validation

If you need to debug check digit validation issues, enable the debug flag to see detailed comparisons:

```swift
let debugParser = MRZParser(isOCRCorrectionEnabled: true, debug: true)
let result = debugParser.parse(mrzString: mrzString)
// Console output will show:
// Document Number Check Digit: ✓ Parsed=7 Calculated=7
// Birthdate Check Digit: ✓ Parsed=2 Calculated=2
// Expiry Date Check Digit: ✓ Parsed=9 Calculated=9
// Composite Check Digit: ✓ Parsed=6 Calculated=6
```

For invalid MRZ, the parser still returns a result but with `isValid: false`, and debug mode shows which check digits don't match:

```swift
// Debug output for invalid check digit:
// Document Number Check Digit: ✗ Parsed=8 Calculated=7
```

## Example

### TD1 (ID card)

#### TD1 Input

```txt
I<UTOD231458907<<<<<<<<<<<<<<<
7408122F1204159UTO<<<<<<<<<<<6
ERIKSSON<<ANNA<MARIA<<<<<<<<<<
```

#### TD1 Output

Field | Value
----- | -----
Document type | I
Country code | UTO
Document number | D23145890
Birth date | 1974.08.12
Sex | FEMALE
Expiry date  | 2012.04.15
Nationality | UTO
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | ""
Optional data 2 | ""
rawMRZLines | ["I<UTOD231458907<<<<<<<<<<<<<<<", "7408122F1204159UTO<<<<<<<<<<<6", "ERIKSSON<<ANNA<MARIA<<<<<<<<<<"]
isValid | true
Document number check digit | 7
Birthdate check digit | 2
Expiry date check digit | 9
Composite check digit | 6

### TD1 (ID card, BEL/PRT extended document number)

#### TD1 (ID card, BEL/PRT extended document number) Input

```txt
IDBEL615057409<9390<<<<<<<<<<<
1202177F2506160BEL120217144293
SPECIMEN<<SPECIMEN<<<<<<<<<<<<
```

#### TD1 (ID card, BEL/PRT extended document number) Output

Field | Value
----- | -----
Document type | I
Country code | BEL
Document number | 615057409939
Birth date | 2012.02.17
Sex | FEMALE
Expiry date | 2025.06.16
Nationality | BEL
Surname | SPECIMEN
Given names | SPECIMEN
Optional data | ""
Optional data 2 | ""
rawMRZLines | ["IDBEL615057409<9390<<<<<<<<<<<", "1202177F2506160BEL120217144293", "SPECIMEN<<SPECIMEN<<<<<<<<<<<<"]
isValid | true
Document number check digit | 9
Birthdate check digit | 7
Expiry date check digit | 0
Composite check digit | 3

### Driving License (DL)

#### Input

```txt
D<NLD1234567890123456789012345<
8001012M2501012NLD<<<<<<<<<<<6
DOE<<JOHN<<<<<<<<<<<<<<<<<<<<<
```

#### Driving License (DL) Output

Field | Value
----- | -----
Document type | D
Country code | NLD
Document number | 1234567890123456789012345
Birth date | 1980.01.01
Sex | MALE
Expiry date | 2025.01.01
Nationality | NLD
Surname | DOE
Given names | JOHN
Optional data | ""
Optional data 2 | ""
rawMRZLines | ["D<NLD1234567890123456789012345<", "8001012M2501012NLD<<<<<<<<<<<6", "DOE<<JOHN<<<<<<<<<<<<<<<<<<<<<"]
isValid | true
Composite check digit | 6

### TD2

#### TD2 Input

```txt
I<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<
D231458907UTO7408122F1204159<<<<<<<6
```

#### TD2 Output

Field | Value
----- | -----
Document type | I
Country code | UTO
Document number | D23145890
Birth date | 1974.08.12
Sex | FEMALE
Expiry date  | 2012.04.15
Nationality | UTO
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | ""
rawMRZLines | ["I<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<", "D231458907UTO7408122F1204159<<<<<<<6"]
isValid | true
Document number check digit | 7
Birthdate check digit | 2
Expiry date check digit | 9
Composite check digit | 6

### TD3 (Passport)

#### TD3 Input

```txt
P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
L898902C36UTO7408122F1204159ZE184226B<<<<<10
```

#### TD3 Output

Field | Value
----- | -----
Document type | P
Country code | UTO
Document number | L898902C3
Birth date | 1974.08.12
Sex | FEMALE
Expiry date  | 2012.04.15
Nationality | UTO
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | ZE184226B
rawMRZLines | ["P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<", "L898902C36UTO7408122F1204159ZE184226B<<<<<10"]
isValid | true
Document number check digit | 6
Birthdate check digit | 2
Expiry date check digit | 9
Composite check digit | 0

### MRVA (Visa type A)

#### MRVA Input

```txt
V<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
L8988901C4XXX4009078F96121096ZE184226B<<<<<<
```

#### MRVA Output

Field | Value
----- | -----
Document type | V
Country code | UTO
Document number | L8988901C
Birth date | 1940.09.07
Sex | FEMALE
Expiry date  | 1996.12.10
Nationality | XXX
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | 6ZE184226B
rawMRZLines | ["V<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<", "L8988901C4XXX4009078F96121096ZE184226B<<<<<<"]
isValid | true
Document number check digit | 4
Birthdate check digit | 8
Expiry date check digit | 6

### MRVB (Visa type B)

#### MRVB Input

```txt
V<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<
L8988901C4XXX4009078F9612109<<<<<<<<
```

#### MRVB Output

Field | Value
----- | -----
Document type | V
Country code | UTO
Document number | L8988901C
Birth date | 1940.09.07
Sex | FEMALE
Expiry date  | 1996.12.10
Nationality | XXX
Surname | ERIKSSON
Given names | ANNA MARIA
Optional data | ""
rawMRZLines | ["V<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<", "L8988901C4XXX4009078F9612109<<<<<<<<"]
isValid | true
Document number check digit | 4
Birthdate check digit | 8
Expiry date check digit | 9

## License

The library is distributed under the MIT [LICENSE](https://opensource.org/licenses/MIT).

## Test Coverage

This library includes a comprehensive test suite, with all test cases from the Go reference MRZ package ported to Swift. This ensures robust handling of real-world MRZs, including country-specific and edge cases. To run tests:

```sh
swift test
```
