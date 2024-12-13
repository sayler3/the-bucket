import Foundation

enum ReserveStatus: String {
    case RSA = "RSA"
    case RSP = "RSP"
}

struct Pilot: Identifiable {
    let id = UUID()
    let seniorityNumber: Int
    let employeeNumber: String
    let name: String
    var reserveDays: [(date: Date, status: ReserveStatus)] // Changed to track status per day
    
    var reserveStatus: ReserveStatus {
        // Return the most common status
        let statusCounts = reserveDays.reduce(into: [:]) { counts, day in
            counts[day.status, default: 0] += 1
        }
        return statusCounts.max(by: { $0.value < $1.value })?.key ?? .RSA
    }
}

extension Pilot {
    func isOnReserve(for date: Date) -> Bool {
        return reserveDays.contains { dayTuple in
            Calendar.current.isDate(dayTuple.date, inSameDayAs: date)
        }
    }
} 