//
//  MRZParserTests.swift
//
//
//  Created by Roman Mazeev on 15.06.2021.
//

import XCTest
@testable import MRZParser

final class MRZParserTests: XCTestCase {
    private var parser: MRZParser!

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
        return formatter
    }()

    override func setUp() {
        super.setUp()
        parser = MRZParser(isOCRCorrectionEnabled: true, debug: false)
    }

    func testTD1() {
        let mrzString = """
                        I<UTOD231458907<<<<<<<<<<<<<<<
                        7408122F1204159UTO<<<<<<<<<<<6
                        ERIKSSON<<ANNA<MARIA<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: nil,
            countryCode: "UTO",
            surnames: "ERIKSSON",
            givenNames: "ANNA MARIA",
            documentNumber: "D23145890",
            nationalityCountryCode: "UTO",
            birthdate:  dateFormatter.date(from: "740812")!,
            sex: .female,
            expiryDate: dateFormatter.date(from: "120415")!,
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "7",
            birthdateCheckDigit: "2",
            expiryDateCheckDigit: "9",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "6"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }
    
    func testTD1_CheckDigit_Debugging() {
        // Valid MRZ - enable debug to see check digit comparison
        let mrzString = """
                        I<UTOD231458907<<<<<<<<<<<<<<<
                        7408122F1204159UTO<<<<<<<<<<<6
                        ERIKSSON<<ANNA<MARIA<<<<<<<<<<
                        """
        
        // Create parser with debug enabled to see check digit comparison in console
        let debugParser = MRZParser(isOCRCorrectionEnabled: true, debug: true)
        let result = debugParser.parse(mrzString: mrzString)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.isValid, true)
        
        // Verify the parsed check digit values from MRZ
        XCTAssertEqual(result?.documentNumberCheckDigit, "7")
        XCTAssertEqual(result?.birthdateCheckDigit, "2")
        XCTAssertEqual(result?.expiryDateCheckDigit, "9")
        XCTAssertEqual(result?.compositeCheckDigit, "6")
        
        // Debug output will show all check digits with ✓ for valid matches
    }
    
    func testTD1_Invalid_CheckDigit() {
        // Invalid document number check digit (should be 7, is 8)
        let mrzString = """
                        I<UTOD231458908<<<<<<<<<<<<<<<
                        7408122F1204159UTO<<<<<<<<<<<6
                        ERIKSSON<<ANNA<MARIA<<<<<<<<<<
                        """
        
        // Create parser with debug enabled to see which check digit is wrong
        let debugParser = MRZParser(isOCRCorrectionEnabled: true, debug: true)
        let result = debugParser.parse(mrzString: mrzString)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.isValid, false) // Invalid due to document number check digit
        
        // Verify the parsed check digit values
        XCTAssertEqual(result?.documentNumberCheckDigit, "8") // What's in the MRZ (wrong)
        XCTAssertEqual(result?.birthdateCheckDigit, "2")
        XCTAssertEqual(result?.expiryDateCheckDigit, "9")
        XCTAssertEqual(result?.compositeCheckDigit, "6")
        
        // Debug output will show: Document Number Check Digit: ✗ Parsed=8 Calculated=7
    }

    func testTD1_Valid() {
        let mrzString = """
                        I<NLDD231458918<<<<<<<<<<<<<<<
                        7408122F1204159NLD<<<<<<<<<<<4
                        ERIKSSON<<ANNA<MARIA<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: nil,
            countryCode: "NLD",
            surnames: "ERIKSSON",
            givenNames: "ANNA MARIA",
            documentNumber: "D23145891",
            nationalityCountryCode: "NLD",
            birthdate: dateFormatter.date(from: "19740812"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20120415"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "8",
            birthdateCheckDigit: "2",
            expiryDateCheckDigit: "9",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "4"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_NLD_BSN_Valid() {
        let mrzString = """
                        I<NLDSPECI20142999999990<<<<<8
                        6503101F2403096NLD<<<<<<<<<<<8
                        DE<BRUIJN<<WILLEKE<LISELOTTE<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: nil,
            countryCode: "NLD",
            surnames: "DE BRUIJN",
            givenNames: "WILLEKE LISELOTTE",
            documentNumber: "SPECI2014",
            nationalityCountryCode: "NLD",
            birthdate: dateFormatter.date(from: "19650310"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20240309"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "2",
            birthdateCheckDigit: "1",
            expiryDateCheckDigit: "6",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "8"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_AUT_Valid() {
        let mrzString = """
                        IDAUTPA12345673<<<<<<<<<<<<<<<
                        8112314F3108011AUT<<<<<<<<<<<6
                        MUSTERFRAU<<MARIA<<<<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: "D",
            countryCode: "AUT",
            surnames: "MUSTERFRAU",
            givenNames: "MARIA",
            documentNumber: "PA1234567",
            nationalityCountryCode: "AUT",
            birthdate: dateFormatter.date(from: "19811231"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20310801"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "3",
            birthdateCheckDigit: "4",
            expiryDateCheckDigit: "1",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "6"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_BEL_1_Valid() {
        let mrzString = """
                        IDBEL000001115<7027<<<<<<<<<<<
                        9502286F3001064BEL950228998747
                        SPECIMEN<<SPECIMEN<<<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: "D",
            countryCode: "BEL",
            surnames: "SPECIMEN",
            givenNames: "SPECIMEN",
            documentNumber: "000001115702",
            nationalityCountryCode: "BEL",
            birthdate: dateFormatter.date(from: "19950228"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20300106"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "7",
            birthdateCheckDigit: "6",
            expiryDateCheckDigit: "4",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "7"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_BEL_2_Valid() {
        let mrzString = """
                        IDBEL592211692<1741<<<<<<<<<<<
                        9003107F2509301BEL900310244094
                        SPECIMEN<<SPECIMEN<<<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: "D",
            countryCode: "BEL",
            surnames: "SPECIMEN",
            givenNames: "SPECIMEN",
            documentNumber: "592211692174",
            nationalityCountryCode: "BEL",
            birthdate: dateFormatter.date(from: "19900310"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20250930"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "1",
            birthdateCheckDigit: "7",
            expiryDateCheckDigit: "1",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "4"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_BEL_3_Valid() {
        let mrzString = """
                        IDBEL615057409<9390<<<<<<<<<<<
                        1202177F2506160BEL120217144293
                        SPECIMEN<<SPECIMEN<<<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: "D",
            countryCode: "BEL",
            surnames: "SPECIMEN",
            givenNames: "SPECIMEN",
            documentNumber: "615057409939",
            nationalityCountryCode: "BEL",
            birthdate: dateFormatter.date(from: "20120217"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20250616"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "0",
            birthdateCheckDigit: "7",
            expiryDateCheckDigit: "0",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "3"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_EST_Valid() {
        let mrzString = """
                        IDESTAS0002261938001085718<<<<
                        8001081M2606288EST<<<<<<<<<<<1
                        JOERG<<JAAK<KRISTJAN<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: "D",
            countryCode: "EST",
            surnames: "JOERG",
            givenNames: "JAAK KRISTJAN",
            documentNumber: "AS0002261",
            nationalityCountryCode: "EST",
            birthdate: dateFormatter.date(from: "19800108"),
            sex: .male,
            expiryDate: dateFormatter.date(from: "20260628"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "9",
            birthdateCheckDigit: "1",
            expiryDateCheckDigit: "8",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "1"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_FRA_Valid() {
        let mrzString = """
                        IDFRAX4RTBPFW46<<<<<<<<<<<<<<<
                        9007138F3002119FRA<<<<<<<<<<<6
                        MARTIN<<MAELYS<GAELLE<MARIE<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: "D",
            countryCode: "FRA",
            surnames: "MARTIN",
            givenNames: "MAELYS GAELLE MARIE",
            documentNumber: "X4RTBPFW4",
            nationalityCountryCode: "FRA",
            birthdate: dateFormatter.date(from: "19900713"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20300211"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "6",
            birthdateCheckDigit: "8",
            expiryDateCheckDigit: "9",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "6"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_PRT_1_Valid() {
        let mrzString = """
                        I<PRT0000414022<ZZ70<<<<<<<<<<
                        8010100M2012294PRT<<<<<<<<<<<2
                        MIGUEL<<SOPHIA<<<<<<<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: nil,
            countryCode: "PRT",
            surnames: "MIGUEL",
            givenNames: "SOPHIA",
            documentNumber: "0000414022ZZ",
            nationalityCountryCode: "PRT",
            birthdate: dateFormatter.date(from: "19801010"),
            sex: .male,
            expiryDate: dateFormatter.date(from: "20201229"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "7",
            birthdateCheckDigit: "0",
            expiryDateCheckDigit: "4",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "2"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_PRT_2_Valid() {
        let mrzString = """
                        I<PRT000024759<ZZ72<<<<<<<<<<<
                        8010100F2006017PRT<<<<<<<<<<<8
                        CARLOS<MONTEIRO<<AMELIA<VANESS
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: nil,
            countryCode: "PRT",
            surnames: "CARLOS MONTEIRO",
            givenNames: "AMELIA VANES",
            documentNumber: "000024759ZZ7",
            nationalityCountryCode: "PRT",
            birthdate: dateFormatter.date(from: "19801010"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20200601"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "2",
            birthdateCheckDigit: "0",
            expiryDateCheckDigit: "7",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "8"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_PRT_3_Valid() {
        let mrzString = """
                        I<PRT141974817<ZV17<<<<<<<<<<<
                        9801082F3407242PRT<<<<<<<<<<<4
                        RONALDO<<CHRISTIANO<<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: nil,
            countryCode: "PRT",
            surnames: "RONALDO",
            givenNames: "CHRISTIANO",
            documentNumber: "141974817ZV1",
            nationalityCountryCode: "PRT",
            birthdate: dateFormatter.date(from: "19980108"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20340724"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "7",
            birthdateCheckDigit: "2",
            expiryDateCheckDigit: "2",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "4"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_HRV_Valid() {
        let mrzString = """
                        IOHRV115501830605781305459<<<<
                        7911255F2608020HRV<<<<<<<<<<<5
                        SPECIMEN<<SPECIMEN<<<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: "O",
            countryCode: "HRV",
            surnames: "SPECIMEN",
            givenNames: "SPECIMEN",
            documentNumber: "115501830",
            nationalityCountryCode: "HRV",
            birthdate: dateFormatter.date(from: "19791125"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20260802"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "6",
            birthdateCheckDigit: "5",
            expiryDateCheckDigit: "0",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "5"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD1_ID_DEU_Valid() {
        let mrzString = """
                        IDD<<T010089212<<<<<<<<<<<<<<<
                        6408125<2010315D<<<<<<<<<<<<<6
                        MUSTERMANN<<ERIKA<<<<<<<<<<<<<
                        """
        let result = MRZResult(
            format: .td1,
            documentType: .id,
            documentTypeAdditional: "D",
            countryCode: "D",
            surnames: "MUSTERMANN",
            givenNames: "ERIKA",
            documentNumber: "T01008921",
            nationalityCountryCode: "D",
            birthdate: dateFormatter.date(from: "19640812"),
            sex: .unspecified,
            expiryDate: dateFormatter.date(from: "20201031"),
            optionalData: "",
            optionalData2: "",
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "2",
            birthdateCheckDigit: "5",
            expiryDateCheckDigit: "5",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "6"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD2() {
        let mrzString = """
                        IRUTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<
                        D231458907UTO7408122F1204159<<<<<<<6
                        """
        let result = MRZResult(
            format: .td2,
            documentType: .id,
            documentTypeAdditional: "R",
            countryCode: "UTO",
            surnames: "ERIKSSON",
            givenNames: "ANNA MARIA",
            documentNumber: "D23145890",
            nationalityCountryCode: "UTO",
            birthdate:  dateFormatter.date(from: "740812")!,
            sex: .female,
            expiryDate: dateFormatter.date(from: "120415")!,
            optionalData: "",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "7",
            birthdateCheckDigit: "2",
            expiryDateCheckDigit: "9",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "6"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD2_Valid() {
        let mrzString = """
                        IRNLDERIKSSON<<ANNA<MARIA<<<<<<<<<<<
                        D231458907NLD7408122F1204159<<<<<<<6
                        """
        let result = MRZResult(
            format: .td2,
            documentType: .id,
            documentTypeAdditional: "R",
            countryCode: "NLD",
            surnames: "ERIKSSON",
            givenNames: "ANNA MARIA",
            documentNumber: "D23145890",
            nationalityCountryCode: "NLD",
            birthdate: dateFormatter.date(from: "19740812"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20120415"),
            optionalData: "",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "7",
            birthdateCheckDigit: "2",
            expiryDateCheckDigit: "9",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "6"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD3_Valid() {
        let mrzString = """
                        P<NLDERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
                        L898902C36NLD7408122F1204159ZE184226B<<<<<10
                        """
        let result = MRZResult(
            format: .td3,
            documentType: .passport,
            documentTypeAdditional: nil,
            countryCode: "NLD",
            surnames: "ERIKSSON",
            givenNames: "ANNA MARIA",
            documentNumber: "L898902C3",
            nationalityCountryCode: "NLD",
            birthdate: dateFormatter.date(from: "19740812"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20120415"),
            optionalData: "ZE184226B",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "6",
            birthdateCheckDigit: "2",
            expiryDateCheckDigit: "9",
            optionalDataCheckDigit: "1",
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "0"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD3_PP_NLD_Valid() {
        let mrzString = """
                        P<NLDDE<BRUIJN<<WILLEKE<LISELOTTE<<<<<<<<<<<
                        SPECI20142NLD6503101F2403096999999990<<<<<84
                        """
        let result = MRZResult(
            format: .td3,
            documentType: .passport,
            documentTypeAdditional: nil,
            countryCode: "NLD",
            surnames: "DE BRUIJN",
            givenNames: "WILLEKE LISELOTTE",
            documentNumber: "SPECI2014",
            nationalityCountryCode: "NLD",
            birthdate: dateFormatter.date(from: "19650310"),
            sex: .female,
            expiryDate: dateFormatter.date(from: "20240309"),
            optionalData: "999999990",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "2",
            birthdateCheckDigit: "1",
            expiryDateCheckDigit: "6",
            optionalDataCheckDigit: "8",
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "4"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD2_ID_ROU_Valid() {
        let mrzString = """
                        IDROUPOPESCU<<MARIN<<<<<<<<<<<<<<<<<
                        SS099993<1ROU4609135M810913814000881
                        """
        let result = MRZResult(
            format: .td2,
            documentType: .id,
            documentTypeAdditional: "D",
            countryCode: "ROU",
            surnames: "POPESCU",
            givenNames: "MARIN",
            documentNumber: "SS099993",
            nationalityCountryCode: "ROU",
            birthdate: dateFormatter.date(from: "19460913"),
            sex: .male,
            expiryDate: dateFormatter.date(from: "19810913"),
            optionalData: "1400088",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "1",
            birthdateCheckDigit: "5",
            expiryDateCheckDigit: "8",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "1"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD3() {
        let mrzString = """
                        P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
                        L898902C36UTO7408122F1204159ZE184226B<<<<<10
                        """
        let result = MRZResult(
            format: .td3,
            documentType: .passport,
            documentTypeAdditional: nil,
            countryCode: "UTO",
            surnames: "ERIKSSON",
            givenNames: "ANNA MARIA",
            documentNumber: "L898902C3",
            nationalityCountryCode: "UTO",
            birthdate:  dateFormatter.date(from: "740812")!,
            sex: .female,
            expiryDate: dateFormatter.date(from: "120415")!,
            optionalData: "ZE184226B",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "6",
            birthdateCheckDigit: "2",
            expiryDateCheckDigit: "9",
            optionalDataCheckDigit: "1",
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "0"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD3RussianInternationalPassport() {
        let mrzString = """
                        P<RUSIMIAREK<<EVGENII<<<<<<<<<<<<<<<<<<<<<<<
                        1104000008RUS8209120M2601157<<<<<<<<<<<<<<06
                        """
        let result = MRZResult(
            format: .td3,
            documentType: .passport,
            documentTypeAdditional: nil,
            countryCode: "RUS",
            surnames: "IMIAREK",
            givenNames: "EVGENII",
            documentNumber: "110400000",
            nationalityCountryCode: "RUS",
            birthdate:  dateFormatter.date(from: "820912")!,
            sex: .male,
            expiryDate: dateFormatter.date(from: "260115")!,
            optionalData: "",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "8",
            birthdateCheckDigit: "0",
            expiryDateCheckDigit: "7",
            optionalDataCheckDigit: "0",
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "6"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD3RussianPassport() {
        let mrzString = """
                        PNRUSZDRIL7K<<SERGEQ<ANATOL9EVI3<<<<<<<<<<<<
                        3919353498RUS7207233M<<<<<<<4151218910003<50
                        """
        let result = MRZResult(
            format: .td3,
            documentType: .passport,
            documentTypeAdditional: "N",
            countryCode: "RUS",
            surnames: "ZDRIL7K",
            givenNames: "SERGEQ ANATOL9EVI3",
            documentNumber: "391935349",
            nationalityCountryCode: "RUS",
            birthdate:  dateFormatter.date(from: "720723")!,
            sex: .male,
            expiryDate: nil,
            optionalData: "4151218910003",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "8",
            birthdateCheckDigit: "3",
            expiryDateCheckDigit: "<",
            optionalDataCheckDigit: "5",
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "0"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testTD3NetherlandsPassport() {
        let mrzString = """
                        P<NLDDE<BRUIJN<<WILLEKE<LISELOTTE<<<<<<<<<<<
                        SPECI20142NLD6503101F2403096999999990<<<<<84
                        """
        let result = MRZResult(
            format: .td3,
            documentType: .passport,
            documentTypeAdditional: nil,
            countryCode: "NLD",
            surnames: "DE BRUIJN",
            givenNames: "WILLEKE LISELOTTE",
            documentNumber: "SPECI2014",
            nationalityCountryCode: "NLD",
            birthdate:  dateFormatter.date(from: "650310")!,
            sex: .female,
            expiryDate: dateFormatter.date(from: "240309")!,
            optionalData: "999999990",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "2",
            birthdateCheckDigit: "1",
            expiryDateCheckDigit: "6",
            optionalDataCheckDigit: "8",
            optionalData2CheckDigit: nil,
            compositeCheckDigit: "4"
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testMRVA() {
        let mrzString = """
                        V<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
                        L8988901C4XXX4009078F96121096ZE184226B<<<<<<
                        """
        let result = MRZResult(
            format: .td3,
            documentType: .visa,
            documentTypeAdditional: nil,
            countryCode: "UTO",
            surnames: "ERIKSSON",
            givenNames: "ANNA MARIA",
            documentNumber: "L8988901C",
            nationalityCountryCode: "XXX",
            birthdate:  dateFormatter.date(from: "19400907")!,
            sex: .female,
            expiryDate: dateFormatter.date(from: "19961210")!,
            optionalData: "6ZE184226B",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "4",
            birthdateCheckDigit: "8",
            expiryDateCheckDigit: "9",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: nil
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }

    func testMRVB() {
        let mrzString = """
                        V<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<
                        L8988901C4XXX4009078F9612109<<<<<<<<
                        """
        let result = MRZResult(
            format: .td2,
            documentType: .visa,
            documentTypeAdditional: nil,
            countryCode: "UTO",
            surnames: "ERIKSSON",
            givenNames: "ANNA MARIA",
            documentNumber: "L8988901C",
            nationalityCountryCode: "XXX",
            birthdate:  dateFormatter.date(from: "19400907")!,
            sex: .female,
            expiryDate: dateFormatter.date(from: "19961210")!,
            optionalData: "",
            optionalData2: nil,
            rawMRZLines: mrzString.split(separator: "\n").map { String($0) },
            isValid: true,
            documentNumberCheckDigit: "4",
            birthdateCheckDigit: "8",
            expiryDateCheckDigit: "9",
            optionalDataCheckDigit: nil,
            optionalData2CheckDigit: nil,
            compositeCheckDigit: nil
        )

        XCTAssertEqual(parser.parse(mrzString: mrzString), result)
    }
}
