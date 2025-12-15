# Changelog

All notable changes to this fork will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2025-12-15

### Added

- **Driving License (DL) Support**: Full parsing for ISO/IEC 18013-1 single-line Driving License MRZ format
  - Added DL format detection and parsing logic
  - Added comprehensive DL test suite (`DLTests.swift`)
  - Support for NLD (Netherlands) eDL format
- **Validation Transparency**:
  - Added `isValid: Bool` field to `MRZResult` structure
  - Added all check digit fields to `MRZResult`: `documentNumberCheckDigit`, `birthdateCheckDigit`, `expiryDateCheckDigit`, `optionalDataCheckDigit`, `optionalData2CheckDigit`, `compositeCheckDigit`
  - Parser now returns `MRZResult` even for invalid MRZ (previously returned `nil`)
- **Debug Mode**:
  - Added `debug: Bool` parameter to `MRZParser.init()` (default: `false`)
  - When enabled, prints check digit comparisons to console with ✓ (match) and ✗ (mismatch) indicators
  - Helps identify which specific check digits are causing validation failures
- **Raw MRZ Access**: Added `rawMRZLines: [String]` to `MRZResult` containing original MRZ input lines
- **Enhanced Test Coverage**:
  - Ported complete test suite from Go MRZ reference package ([datacheckerbv/mrz](https://github.com/datacheckerbv/mrz))
  - Added 65+ comprehensive test cases covering all document formats and edge cases
  - Tests include valid cases, invalid check digits, country-specific formats, and boundary conditions

### Changed

- **Parser Behavior**: Parser no longer returns `nil` for invalid MRZ; instead returns `MRZResult` with `isValid: false`
- Updated all test cases to include `isValid` field and check digit assertions
- Enhanced documentation with debug mode examples and check digit usage

### Fixed

- Improved error handling for malformed MRZ strings
- Better validation logic for country-specific formats

---

## Fork Information

This fork was created on 2025-12-15 from [appintheair/MRZParser](https://github.com/appintheair/MRZParser) (upstream version ~1.1.3).

**Maintained by**: [datacheckerbv](https://github.com/datacheckerbv)

**Original Project**: [appintheair/MRZParser](https://github.com/appintheair/MRZParser)

**License**: MIT (preserved from upstream)

[Unreleased]: https://github.com/datacheckerbv/MRZParser/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/datacheckerbv/MRZParser/releases/tag/v1.2.0
