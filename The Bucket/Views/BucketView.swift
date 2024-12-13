import SwiftUI

struct BucketView: View {
    let days: Int
    let pilots: [Pilot]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("\(days) Day\(days == 1 ? "" : "s")")
                    .font(.headline)
                
                Spacer()
                
                Text("\(pilots.count) Pilot\(pilots.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)
            
            // Pilot List
            if pilots.isEmpty {
                Text("No pilots available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
            } else {
                ForEach(pilots) { pilot in
                    PilotCardView(pilot: pilot)
                }
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
    }
}

struct PilotCardView: View {
    let pilot: Pilot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("#\(pilot.seniorityNumber)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text(pilot.reserveStatus.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        pilot.reserveStatus == .RSA ? 
                            Color.blue.opacity(0.2) : Color.green.opacity(0.2)
                    )
                    .cornerRadius(6)
            }
            
            // Details
            Text(pilot.name)
                .font(.system(.body, design: .rounded))
            
            Text("Employee #: \(pilot.employeeNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Dates
            Text(formatDates(pilot.reserveDays))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatDates(_ dates: [(Date, ReserveStatus)]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return dates.map { formatter.string(from: $0.0) }.joined(separator: ", ")
    }
}

#Preview {
    let dates = (1...5).map { day -> Date in
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = day
        return Calendar.current.date(from: components)!
    }
    
    let pilot = Pilot(
        seniorityNumber: 87,
        employeeNumber: "157629",
        name: "John Smith",
        reserveDays: dates.map { ($0, .RSA) }
    )
    
    return BucketView(days: 3, pilots: [pilot])
        .padding()
} 