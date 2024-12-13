//
//  The_BucketTests.swift
//  The BucketTests
//
//  Created by Sam Ayler on 12/12/24.
//

import Testing
@testable import The_Bucket

struct The_BucketTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func testPDFImport() async throws {
        let viewModel = BucketViewModel()
        
        // Get the URL of the actual PDF
        guard let pdfURL = Bundle.module.url(forResource: "CAC Initial Dec 2024", withExtension: "pdf") else {
            throw "Could not find PDF file"
        }
        
        // Import the PDF
        await viewModel.importPDF(pdfURL)
        
        // Basic validation
        #expect(!viewModel.pilots.isEmpty, "Should find pilots in the PDF")
        
        // Verify pilot structure
        for pilot in viewModel.pilots {
            // Verify seniority number format
            #expect(pilot.seniorityNumber > 0, "Seniority number should be positive")
            
            // Verify employee number format
            #expect(pilot.employeeNumber.count == 6, "Employee number should be 6 digits")
            #expect(Int(pilot.employeeNumber) != nil, "Employee number should be numeric")
            
            // Verify name
            #expect(!pilot.name.isEmpty, "Name should not be empty")
            
            // Verify reserve status
            #expect(pilot.reserveStatus == .RSA || pilot.reserveStatus == .RSP,
                   "Reserve status should be either RSA or RSP")
            
            // Verify reserve days
            #expect(!pilot.reserveDays.isEmpty, "Should have reserve days")
            
            // Verify dates are in December 2024
            for date in pilot.reserveDays {
                let components = Calendar.current.dateComponents([.year, .month], from: date)
                #expect(components.year == 2024, "Year should be 2024")
                #expect(components.month == 12, "Month should be December")
            }
        }
    }

}
