import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import os.log

enum PDFImportError: Error {
    case invalidPDF
    case emptyContent
    case parsingError(String)
    case noReserveData
    
    var localizedDescription: String {
        switch self {
        case .invalidPDF:
            return "The selected file is not a valid PDF"
        case .emptyContent:
            return "The PDF appears to be empty"
        case .parsingError(let details):
            return "Error parsing PDF: \(details)"
        case .noReserveData:
            return "No reserve schedule data found in the PDF"
        }
    }
}

@MainActor
class BucketViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.thebucket.app", category: "PDFImport")
    @Published var pilots: [Pilot] = []
    @Published var isImporting: Bool = false
    @Published var importError: String?
    @Published var selectedReserveStatus: ReserveStatus?
    @Published var sortBySeniority: Bool = true
    @Published var selectedDate: Date
    
    private let calendar = Calendar.current
    private let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    
    init() {
        self.selectedDate = Calendar.current.startOfDay(for: Date())
        if isPreview {
            print("📱 Initializing BucketViewModel in preview mode")
        }
        print("📅 Initialized with current date: \(self.selectedDate)")
    }
    
    func updateSelectedDate(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
    }
    
    func toggleSortOrder() {
        sortBySeniority.toggle()
    }
    
    func pilotsForBucket(_ days: Int, on date: Date) -> [Pilot] {
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: days, to: startDate) ?? startDate
        
        return pilots.filter { pilot in
            pilot.reserveDays.contains { reserveDay in
                let (date, status) = reserveDay
                return date >= startDate && date < endDate && 
                       (selectedReserveStatus == nil || status == selectedReserveStatus)
            }
        }.sorted { first, second in
            if sortBySeniority {
                return first.seniorityNumber < second.seniorityNumber
            } else {
                return first.employeeNumber < second.employeeNumber
            }
        }
    }
    
    func importPDF(_ url: URL) async {
        isImporting = true
        importError = nil
        
        do {
            let parser = PDFParser()
            let (month, year, pilots) = try await parser.parse(url)
            
            await MainActor.run {
                self.pilots = pilots
                print("✅ Successfully parsed \(pilots.count) total pilots")
                updateToScheduleDate(from: pilots, month: month, year: year)
            }
        } catch {
            await MainActor.run {
                self.importError = error.localizedDescription
                print("❌ Import failed: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            isImporting = false
        }
    }
    
    private func updateToScheduleDate(from pilots: [Pilot], month: Int, year: Int) {
        let allReserveDays = pilots.flatMap { pilot in
            pilot.reserveDays.map { $0.date }
        }.sorted()
        
        if let closestDate = allReserveDays.min(by: { first, second in
            abs(first.timeIntervalSince(selectedDate)) < abs(second.timeIntervalSince(selectedDate))
        }) {
            selectedDate = closestDate
            print("📅 Snapped to nearest reserve day: \(selectedDate)")
        }
    }
    
    // Preview helper
    static func preview() -> BucketViewModel {
        let viewModel = BucketViewModel()
        print("📦 BucketViewModel.preview() called")
        
        // Create dates for December 2024
        let components = DateComponents(year: 2024, month: 12)
        let startDate = Calendar.current.date(from: components)!
        print("📅 Preview start date: \(startDate)")
        
        let dates = (1...31).compactMap { day -> Date? in
            var dateComponents = components
            dateComponents.day = day
            return Calendar.current.date(from: dateComponents)
        }
        print("📅 Created \(dates.count) dates for preview")
        
        // Create mock pilots with realistic reserve patterns
        viewModel.pilots = [
            Pilot(seniorityNumber: 87, 
                  employeeNumber: "157629", 
                  name: "Pilot 87", 
                  reserveDays: dates[0...15].map { ($0, .RSA) }),
            Pilot(seniorityNumber: 89, 
                  employeeNumber: "586473", 
                  name: "Pilot 89", 
                  reserveDays: dates[5...15].map { ($0, .RSP) }),
            Pilot(seniorityNumber: 90, 
                  employeeNumber: "280137", 
                  name: "Pilot 90", 
                  reserveDays: dates[10...23].map { ($0, .RSA) }),
            Pilot(seniorityNumber: 101, 
                  employeeNumber: "802791", 
                  name: "Pilot 101", 
                  reserveDays: dates[3...21].map { ($0, .RSP) })
        ]
        print("👥 Created \(viewModel.pilots.count) preview pilots")
        
        // Set initial date to December 1, 2024
        viewModel.selectedDate = startDate
        print("📅 Set preview date to: \(startDate)")
        
        return viewModel
    }
} 