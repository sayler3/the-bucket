import SwiftUI

struct DebugView: View {
    @ObservedObject var viewModel: BucketViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Selected Date: \(viewModel.selectedDate, format: .dateTime)")
            Text("Total Pilots: \(viewModel.pilots.count)")
            Text("Sort by Seniority: \(viewModel.sortBySeniority ? "Yes" : "No")")
            Text("Selected Status: \(viewModel.selectedReserveStatus?.rawValue ?? "All")")
            
            if !viewModel.pilots.isEmpty {
                Text("First Pilot:")
                let pilot = viewModel.pilots[0]
                Text("- Seniority: \(pilot.seniorityNumber)")
                Text("- Employee #: \(pilot.employeeNumber)")
                Text("- Reserve Days: \(pilot.reserveDays.count)")
            }
        }
        .font(.caption)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
} 