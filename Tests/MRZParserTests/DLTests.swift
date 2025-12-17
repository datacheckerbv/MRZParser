//
//  DLTests.swift
//
//
//  Created by Fabian Afatsawo on 15.12.2025.
//

import XCTest
@testable import MRZParser

final class DLTests: XCTestCase {
    private var parser: MRZDecoder!

    override func setUp() {
        super.setUp()
        parser = MRZDecoder(isOCRCorrectionEnabled: true, debug: false)
    }

    func testDL_Valid() {
        let line = "D1NLD15094962111659VW87Z78NB84"

        let result = parser.parse(mrzString: line)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.isValid, true)
        XCTAssertEqual(result?.documentNumber, "5094962111")
        XCTAssertEqual(result?.countryCode, "NLD")
        XCTAssertEqual(result?.optionalData, "659VW87Z78NB8")
        XCTAssertEqual(result?.rawMRZLines, [line])
        XCTAssertEqual(result?.compositeCheckDigit, "4")
        XCTAssertNil(result?.documentNumberCheckDigit) // DL format has no separate doc number check digit
    }

    func testDL_Issuer_Invalid() {
        let line = "D1UTO15094962111659VW87Z78NB84"

        let result = parser.parse(mrzString: line)

        // Parser now returns a result even for invalid MRZ, allowing inspection of fields
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.isValid, false) // Invalid due to country code validation
        XCTAssertEqual(result?.countryCode, "UTO") // Invalid issuer code
        XCTAssertEqual(result?.documentNumber, "5094962111")
    }
    
    func testDL_CheckDigit_Mismatch() {
        // Valid structure but wrong composite check digit (should be 4, is 5)
        let line = "D1NLD15094962111659VW87Z78NB85"
        
        // Create parser with debug enabled to see check digit comparison
        let debugParser = MRZDecoder(isOCRCorrectionEnabled: true, debug: true)
        let result = debugParser.parse(mrzString: line)
        
        // Parser returns result even when check digit is wrong
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.isValid, false) // Invalid due to check digit mismatch
        XCTAssertEqual(result?.compositeCheckDigit, "5") // What was in the MRZ (wrong)
        
        // Debug output will show: Composite Check Digit: ✗ Parsed=5 Calculated=4    }
    }
}