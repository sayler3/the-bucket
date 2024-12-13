import PDFKit
import Foundation

private struct ReserveDay: Hashable {
    let date: Date
    let status: ReserveStatus
}

class PDFParser {
    private let calendar = Calendar.current
    
    func parse(_ url: URL) async throws -> (month: Int, year: Int, pilots: [Pilot]) {
        print("📥 Starting PDF import from: \(url)")
        print("📂 File exists: \(FileManager.default.fileExists(atPath: url.path))")
        
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFImportError.invalidPDF
        }
        
        guard let data = try? Data(contentsOf: url) else {
            throw PDFImportError.invalidPDF
        }
        
        print("✅ Successfully read PDF data: \(data.count) bytes")
        print("📄 PDF Info:")
        print("  - Page count: \(pdfDocument.pageCount)")
        print("  - Is encrypted: \(pdfDocument.isEncrypted)")
        print("  - Document attributes: \(String(describing: pdfDocument.documentAttributes))")
        
        var allPilots: [Pilot] = []
        var monthYear: (month: Int, year: Int)?
        
        // Process each page
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            print("\n📃 Processing Page \(pageIndex + 1):")
            print("  - Page bounds: \(String(describing: page.bounds))")
            print("  - Page rotation: \(page.rotation)")
            
            guard let content = page.string else { continue }
            print("📝 Content preview (first 200 chars):\n\(String(content.prefix(200)))")
            
            let lines = content.components(separatedBy: .newlines)
            print("\n Processing \(lines.count) lines\n")
            
            // Extract month/year from first page
            if pageIndex == 0 {
                if let extracted = extractMonthYear(from: content) {
                    monthYear = extracted
                    print("📅 Found month/year: \(extracted.month)/\(extracted.year)")
                }
            }
            
            // Process pilots on this page
            let pagePilots = processPage(content: content, month: monthYear?.month ?? 0, year: monthYear?.year ?? 0)
            allPilots.append(contentsOf: pagePilots)
        }
        
        guard let (month, year) = monthYear else {
            throw PDFImportError.parsingError("Could not determine month and year")
        }
        
        guard !allPilots.isEmpty else {
            throw PDFImportError.noReserveData
        }
        
        print("✅ Parsed \(allPilots.count) pilots")
        validateParsedData(pilots: allPilots, month: month, year: year)
        return (month: month, year: year, pilots: allPilots)
    }
    
    private func processPage(content: String, month: Int, year: Int) -> [Pilot] {
        var pilots: [Pilot] = []
        let lines = content.components(separatedBy: .newlines)
        var currentPilot: (seniority: Int, employeeNum: String)?
        var reserveDays: Set<ReserveDay> = []
        var currentDay = 1
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 31
        
        print("\n Processing \(lines.count) lines\n")
        
        for line in lines {
            // Add this before line 113
            #if DEBUG
            if line.contains("RSA") || line.contains("RSP") {
                print("\n🔍 Found potential reserve line: '\(line)'")
                print("  Current day: \(currentDay)")
                if let pilot = currentPilot {
                    print("  Processing for pilot: #\(pilot.seniority)")
                }
            }
            #endif
            
            // Look for pilot info line (improved pattern)
            if let pilotMatch = try? NSRegularExpression(pattern: #"^#?(\d+)\s*[/-]\s*(\d{6})"#)
                .firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let seniorityRange = Range(pilotMatch.range(at: 1), in: line),
               let employeeRange = Range(pilotMatch.range(at: 2), in: line),
               let seniority = Int(String(line[seniorityRange])) {
                
                let employeeNum = String(line[employeeRange])
                print("\n👤 Processing pilot: #\(seniority) (\(employeeNum))")
                
                // Save previous pilot if exists
                if let pilot = currentPilot, !reserveDays.isEmpty {
                    pilots.append(Pilot(
                        seniorityNumber: pilot.seniority,
                        employeeNumber: pilot.employeeNum,
                        name: "",
                        reserveDays: Array(reserveDays).map { ($0.date, $0.status) }
                    ))
                    print("  ✅ Added pilot #\(pilot.seniority) with \(reserveDays.count) reserve days")
                }
                
                // Start new pilot
                currentPilot = (seniority: seniority, employeeNum: employeeNum)
                reserveDays = []
                currentDay = 1
                continue
            }
            
            // Look for reserve status (simplified pattern)
            if let pilot = currentPilot,
               currentDay <= daysInMonth, // Only process days within the month
               let statusMatch = try? NSRegularExpression(pattern: #"(RSA|RSP)"#)
                .firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let statusRange = Range(statusMatch.range(at: 1), in: line),
               let status = ReserveStatus(rawValue: String(line[statusRange])) {
                
                #if DEBUG
                print("\n👉 Found reserve line: '\(line)'")
                print("  Current day: \(currentDay)")
                print("  Processing for pilot: #\(pilot.seniority)")
                #endif
                
                var components = DateComponents()
                components.year = year
                components.month = month
                components.day = currentDay
                
                if let date = Calendar.current.date(from: components) {
                    reserveDays.insert(ReserveDay(date: date, status: status))
                    #if DEBUG
                    print("    📅 Added \(status) for day \(currentDay) - \(date)")
                    if components.day == 17 {
                        print("    🎯 Found pilot #\(pilot.seniority) on December 17th with status \(status)")
                    }
                    #endif
                }
                currentDay += 1
            }
        }
        
        // Don't forget the last pilot
        if let pilot = currentPilot, !reserveDays.isEmpty {
            pilots.append(Pilot(
                seniorityNumber: pilot.seniority,
                employeeNumber: pilot.employeeNum,
                name: "",
                reserveDays: Array(reserveDays).map { ($0.date, $0.status) }
            ))
            print("  ✅ Added pilot #\(pilot.seniority) with \(reserveDays.count) reserve days")
        }
        
        return pilots
    }
    
    private func extractMonthYear(from content: String) -> (month: Int, year: Int)? {
        let monthNames = Calendar.current.monthSymbols
        let pattern = "Period:\\s*([A-Za-z]+)\\s*(\\d{4})"
        
        guard let match = try? NSRegularExpression(pattern: pattern)
            .firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
            let monthRange = Range(match.range(at: 1), in: content),
            let yearRange = Range(match.range(at: 2), in: content),
            let year = Int(String(content[yearRange])) else {
            return nil
        }
        
        let monthStr = String(content[monthRange])
        guard let month = monthNames.firstIndex(of: monthStr)?.advanced(by: 1) else {
            return nil
        }
        
        return (month, year)
    }
    
    private func validateParsedData(pilots: [Pilot], month: Int, year: Int) {
        print("\n🔍 Validation Report:")
        print("Total pilots parsed: \(pilots.count)")
        
        // Check specific dates
        let dateToCheck = Calendar.current.date(from: DateComponents(year: year, month: month, day: 17))!
        let pilotsOnDate = pilots.filter { pilot in
            pilot.reserveDays.contains { day in
                Calendar.current.isDate(day.date, inSameDayAs: dateToCheck)
            }
        }
        
        print("Pilots on the 17th: \(pilotsOnDate.count)")
        print("\nDetailed pilot status for 17th:")
        for pilot in pilotsOnDate {
            print("Pilot #\(pilot.seniorityNumber) (Employee #\(pilot.employeeNumber))")
            let status = pilot.reserveDays.first { 
                Calendar.current.isDate($0.date, inSameDayAs: dateToCheck)
            }?.status.rawValue ?? "Unknown"
            print("  - Status: \(status)")
        }
        
        // Check for data anomalies
        let pilotsWithNoReserveDays = pilots.filter { $0.reserveDays.isEmpty }
        if !pilotsWithNoReserveDays.isEmpty {
            print("\n⚠️ Warning: Found \(pilotsWithNoReserveDays.count) pilots with no reserve days")
            pilotsWithNoReserveDays.forEach { pilot in
                print("  - Pilot #\(pilot.seniorityNumber) (Employee #\(pilot.employeeNumber))")
            }
        }
    }
} 