//
//  ContentView.swift
//  The Bucket
//
//  Created by Sam Ayler on 12/12/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var viewModel: BucketViewModel
    @State private var showingFilePicker = false
    @State private var showingError = false
    @State private var isCalendarExpanded = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Navigation Header
                HStack {
                    Text("The Bucket")
                        .font(.title.bold())
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Main Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Date Picker Section
                        VStack(alignment: .leading, spacing: 8) {
                            // Header with date display
                            Button(action: { withAnimation { isCalendarExpanded.toggle() } }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Selected Date")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(viewModel.selectedDate, format: .dateTime.day().month().year())
                                            .font(.title2.bold())
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: isCalendarExpanded ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
                                )
                            }
                            
                            // Expandable Calendar
                            if isCalendarExpanded {
                                DatePicker(
                                    "Select Date",
                                    selection: Binding(
                                        get: { viewModel.selectedDate },
                                        set: { date in 
                                            viewModel.updateSelectedDate(date)
                                            withAnimation { isCalendarExpanded = false }
                                        }
                                    ),
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                                .frame(maxHeight: 300)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Filter and Sort Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Filters")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            FilterSortControls(viewModel: viewModel)
                        }
                        .padding(.horizontal)
                        
                        // Bucket Views
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach([1, 2, 3, 4, 5], id: \.self) { days in
                                    BucketView(
                                        days: days,
                                        pilots: viewModel.pilotsForBucket(days, on: viewModel.selectedDate)
                                    )
                                }
                            }
                            .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGroupedBackground))
                                .ignoresSafeArea()
                        )
                        
                        #if DEBUG
                        DebugView(viewModel: viewModel)
                            .padding(.horizontal)
                        #endif
                    }
                }
                
                // Bottom Toolbar
                HStack(spacing: 20) {
                    // Import Button
                    Button(action: { showingFilePicker = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 24))
                            Text("Import")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Filter Button
                    Button(action: { /* Add filter action */ }) {
                        VStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 24))
                            Text("Filter")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Sort Button
                    Button(action: viewModel.toggleSortOrder) {
                        VStack(spacing: 4) {
                            Image(systemName: viewModel.sortBySeniority ? "arrow.up.circle" : "arrow.down.circle")
                                .font(.system(size: 24))
                            Text("Sort")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Debug Log Button (only in DEBUG builds)
                    #if DEBUG
                    Button(action: logPilotsForDate) {
                        VStack(spacing: 4) {
                            Image(systemName: "terminal")
                                .font(.system(size: 24))
                            Text("Log")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    #endif
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                )
            }
            .navigationBarHidden(true)
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                onCompletion: handleFileImport
            )
            .alert("Import Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.importError ?? "Unknown error")
            }
            .overlay {
                if viewModel.isImporting {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Importing...")
                                .font(.headline)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 8)
                        )
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task {
                await viewModel.importPDF(url)
            }
        case .failure(let error):
            viewModel.importError = error.localizedDescription
            showingError = true
        }
    }
    
    private func logPilotsForDate() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 17
        
        guard let date = calendar.date(from: components) else {
            print("❌ Could not create date for December 17, 2024")
            return
        }
        
        let pilotsOnDate = viewModel.pilots.filter { pilot in
            pilot.reserveDays.contains { reserveDay in
                calendar.isDate(reserveDay.date, inSameDayAs: date)
            }
        }.sorted { $0.employeeNumber < $1.employeeNumber }
        
        print("\n📅 Pilots on December 17, 2024:")
        print("Found \(pilotsOnDate.count) pilots")
        
        for pilot in pilotsOnDate {
            let status = pilot.reserveDays.first { calendar.isDate($0.date, inSameDayAs: date) }?.status.rawValue ?? "Unknown"
            print("Employee #\(pilot.employeeNumber) - Status: \(status)")
        }
        print("\n")
    }
}

// MARK: - Supporting Views
struct FilterSortControls: View {
    @ObservedObject var viewModel: BucketViewModel
    
    var body: some View {
        Picker("Reserve Status", selection: $viewModel.selectedReserveStatus) {
            Text("All").tag(Optional<ReserveStatus>.none)
            Text("RSA").tag(Optional(ReserveStatus.RSA))
            Text("RSP").tag(Optional(ReserveStatus.RSP))
        }
        .pickerStyle(.segmented)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(BucketViewModel.preview())
}
