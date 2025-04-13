//
//  MedicalRecordsView.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI

struct MedicalRecord: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let doctor: String
    let hospital: String
    let recordType: RecordType
    let content: String
    let attachments: [String]
    var isFavorite: Bool = false
    var tags: [String] = []
    
    enum RecordType: String, CaseIterable {
        case labResult = "Lab Result"
        case prescription = "Prescription"
        case doctorNote = "Doctor's Note"
        case radiology = "Radiology"
        case procedure = "Procedure"
        case vaccination = "Vaccination"
        
        var icon: String {
            switch self {
            case .labResult: return "flask.fill"
            case .prescription: return "pills.fill"
            case .doctorNote: return "note.text"
            case .radiology: return "lungs.fill"
            case .procedure: return "heart.text.square.fill"
            case .vaccination: return "syringe.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .labResult: return .purple
            case .prescription: return .blue
            case .doctorNote: return .green
            case .radiology: return .orange
            case .procedure: return .red
            case .vaccination: return .teal
            }
        }
    }
}

struct MedicalRecordsView: View {
    @State private var searchText = ""
    @State private var selectedFilter: String = "All"
    @State private var selectedRecord: MedicalRecord?
    @State private var showingRecordDetail = false
    @State private var records: [MedicalRecord] = []
    @State private var showingAddRecord = false
    @State private var showingSortOptions = false
    @State private var sortOrder = SortOrder.dateDescending
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case alphabetical = "A to Z"
        case type = "By Type"
        
        var systemImage: String {
            switch self {
            case .dateDescending: return "arrow.down.circle"
            case .dateAscending: return "arrow.up.circle"
            case .alphabetical: return "textformat.abc"
            case .type: return "tag"
            }
        }
    }
    
    let filterOptions = ["All"] + MedicalRecord.RecordType.allCases.map { $0.rawValue }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter section
            VStack(spacing: 12) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search records...", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Filter options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filterOptions, id: \.self) { filter in
                            FilterChip(
                                title: filter,
                                isSelected: selectedFilter == filter,
                                onTap: {
                                    selectedFilter = filter
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                }
            }
            .padding(.top)
            .background(Color(.systemBackground))
            
            // Records list
            if filteredRecords.isEmpty {
                emptyStateView
            } else {
                recordsListView
            }
        }
        .navigationTitle("Medical Records")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            Label(order.rawValue, systemImage: order.systemImage)
                                .foregroundColor(sortOrder == order ? .blue : .primary)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddRecord = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AddRecordView(onSave: { newRecord in
                records.append(newRecord)
            })
        }
        .sheet(item: $selectedRecord) { record in
            RecordDetailView(record: record)
        }
        .onAppear {
            if records.isEmpty {
                loadSampleRecords()
            }
        }
    }
    
    // Empty state
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.7))
                .padding(.bottom, 10)
            
            Text(searchText.isEmpty ? "No Records Found" : "No Matching Records")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(searchText.isEmpty ?
                "Your medical records will appear here" :
                "Try adjusting your search or filters")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !searchText.isEmpty || selectedFilter != "All" {
                Button(action: {
                    searchText = ""
                    selectedFilter = "All"
                }) {
                    Text("Clear Filters")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
        }
        .padding()
    }
    
    // Records list view
    var recordsListView: some View {
        List {
            ForEach(filteredAndSortedRecords) { record in
                RecordRow(record: record)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRecord = record
                    }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // Filtered records based on search and category
    var filteredRecords: [MedicalRecord] {
        var result = records
        
        // Apply category filter
        if selectedFilter != "All" {
            result = result.filter { $0.recordType.rawValue == selectedFilter }
        }
        
        // Apply search filter if search text isn't empty
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.doctor.lowercased().contains(searchText.lowercased()) ||
                $0.hospital.lowercased().contains(searchText.lowercased()) ||
                $0.content.lowercased().contains(searchText.lowercased())
            }
        }
        
        return result
    }
    
    // Sorted records based on selected sort option
    var filteredAndSortedRecords: [MedicalRecord] {
        let filtered = filteredRecords
        
        switch sortOrder {
        case .dateDescending:
            return filtered.sorted { $0.date > $1.date }
        case .dateAscending:
            return filtered.sorted { $0.date < $1.date }
        case .alphabetical:
            return filtered.sorted { $0.title < $1.title }
        case .type:
            return filtered.sorted { $0.recordType.rawValue < $1.recordType.rawValue }
        }
    }
    
    // Load sample records for demo
    private func loadSampleRecords() {
        records = [
            MedicalRecord(
                title: "Annual Blood Test",
                date: Date().addingTimeInterval(-30 * 24 * 3600),
                doctor: "Dr. Sarah Johnson",
                hospital: "City General Hospital",
                recordType: .labResult,
                content: "Blood count normal. Cholesterol: 185 mg/dL (borderline). Glucose: 92 mg/dL (normal). Blood pressure: 122/78 mmHg.",
                attachments: ["bloodtest.pdf"],
                isFavorite: true,
                tags: ["Annual", "Preventive"]
            ),
            MedicalRecord(
                title: "Lisinopril Prescription",
                date: Date().addingTimeInterval(-15 * 24 * 3600),
                doctor: "Dr. Michael Chen",
                hospital: "Riverside Medical Center",
                recordType: .prescription,
                content: "Lisinopril 10mg, Take once daily for hypertension. 30 day supply with 3 refills.",
                attachments: [],
                tags: ["Medication", "Hypertension"]
            ),
            MedicalRecord(
                title: "Chest X-Ray",
                date: Date().addingTimeInterval(-60 * 24 * 3600),
                doctor: "Dr. Emily Rodriguez",
                hospital: "University Hospital",
                recordType: .radiology,
                content: "No significant abnormalities detected. Lungs clear. Heart size normal.",
                attachments: ["xray.jpg"],
                tags: ["Imaging", "Respiratory"]
            ),
            MedicalRecord(
                title: "Cardiology Consultation",
                date: Date().addingTimeInterval(-10 * 24 * 3600),
                doctor: "Dr. James Wilson",
                hospital: "Heart & Vascular Institute",
                recordType: .doctorNote,
                content: "Patient presents with occasional chest discomfort. EKG normal. Recommend stress test and lipid panel follow-up. Continue current medication regimen.",
                attachments: ["ekg_results.pdf", "cardiologist_notes.pdf"],
                isFavorite: true,
                tags: ["Cardiology", "Follow-up"]
            ),
            MedicalRecord(
                title: "Covid-19 Vaccination",
                date: Date().addingTimeInterval(-90 * 24 * 3600),
                doctor: "Nurse Practitioner Williams",
                hospital: "Community Health Clinic",
                recordType: .vaccination,
                content: "COVID-19 Pfizer/BioNTech Booster. Batch #L455721. Site: Left deltoid.",
                attachments: ["vaccination_record.pdf"],
                tags: ["COVID", "Immunization"]
            ),
            MedicalRecord(
                title: "Endoscopy Procedure",
                date: Date().addingTimeInterval(-180 * 24 * 3600),
                doctor: "Dr. Lisa Thompson",
                hospital: "Digestive Health Center",
                recordType: .procedure,
                content: "Diagnostic upper endoscopy performed. Mild gastritis noted. Biopsy taken; results pending. Follow up in 2 weeks.",
                attachments: ["endoscopy_report.pdf"],
                tags: ["Gastroenterology", "Diagnostic"]
            )
        ]
    }
}

// Record row UI
struct RecordRow: View {
    let record: MedicalRecord
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            // Record type icon
            ZStack {
                Circle()
                    .fill(record.recordType.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: record.recordType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(record.recordType.color)
            }
            
            // Record info
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(record.doctor + " • " + record.hospital)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formattedDate(record.date))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    if record.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                    
                    if !record.attachments.isEmpty {
                        Image(systemName: "paperclip")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("\(record.attachments.count)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Tags
                if !record.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(record.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
        }
        .padding(.vertical, 8)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Filter chip component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 14))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// Add record view
struct AddRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var doctor = ""
    @State private var hospital = ""
    @State private var recordType: MedicalRecord.RecordType = .doctorNote
    @State private var content = ""
    @State private var date = Date()
    
    let onSave: (MedicalRecord) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Record Information")) {
                    TextField("Title", text: $title)
                    TextField("Doctor", text: $doctor)
                    TextField("Hospital/Clinic", text: $hospital)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Picker("Record Type", selection: $recordType) {
                        ForEach(MedicalRecord.RecordType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section(header: Text("Contents")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newRecord = MedicalRecord(
                            title: title,
                            date: date,
                            doctor: doctor,
                            hospital: hospital,
                            recordType: recordType,
                            content: content,
                            attachments: []
                        )
                        
                        onSave(newRecord)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty || doctor.isEmpty || hospital.isEmpty)
                }
            }
        }
    }
}

// Record detail view
struct RecordDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let record: MedicalRecord
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Record header with icon and title
                    HStack {
                        ZStack {
                            Circle()
                                .fill(record.recordType.color.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: record.recordType.icon)
                                .font(.system(size: 30))
                                .foregroundColor(record.recordType.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(record.title)
                                    .font(.system(size: 20, weight: .bold))
                                
                                if record.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            Text(record.recordType.rawValue)
                                .font(.subheadline)
                                .foregroundColor(record.recordType.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(record.recordType.color.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Information section
                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeader(title: "Information")
                        
                        DetailRow(iconName: "person.fill", title: "Doctor", value: record.doctor)
                        DetailRow(iconName: "building.2.fill", title: "Facility", value: record.hospital)
                        DetailRow(iconName: "calendar", title: "Date", value: formattedDate(record.date))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Content section
                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeader(title: "Record Details")
                        
                        Text(record.content)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Attachments section
                    if !record.attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Attachments")
                            
                            ForEach(record.attachments, id: \.self) { attachment in
                                AttachmentRow(fileName: attachment)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Tags section
                    if !record.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Tags")
                            
                            FlowLayout(spacing: 8) {
                                ForEach(record.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 14))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        ActionButton(title: "Share", iconName: "square.and.arrow.up", color: .blue) {
                            // Share functionality
                        }
                        
                        ActionButton(title: "Export", iconName: "arrow.down.doc", color: .green) {
                            // Export functionality
                        }
                        
                        ActionButton(title: "Print", iconName: "printer", color: .purple) {
                            // Print functionality
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Record Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// Section header component
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
    }
}

// Detail information row
struct DetailRow: View {
    let iconName: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
        }
    }
}

// Attachment row component
struct AttachmentRow: View {
    let fileName: String
    
    var fileIcon: String {
        let ext = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        
        switch ext {
        case "pdf": return "doc.text.fill"
        case "jpg", "jpeg", "png": return "photo.fill"
        case "doc", "docx": return "doc.fill"
        default: return "doc.circle"
        }
    }
    
    var fileColor: Color {
        let ext = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        
        switch ext {
        case "pdf": return .red
        case "jpg", "jpeg", "png": return .blue
        case "doc", "docx": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: {
            // Open attachment
        }) {
            HStack {
                Image(systemName: fileIcon)
                    .font(.system(size: 18))
                    .foregroundColor(fileColor)
                
                Text(fileName)
                    .font(.system(size: 15))
                
                Spacer()
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
}

// Action button component
struct ActionButton: View {
    let title: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(10)
                
                Text(title)
                    .font(.system(size: 14))
            }
        }
    }
}

// Flow layout for tags
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for (index, size) in sizes.enumerated() {
            if rowWidth + size.width > width {
                // Start a new row
                height += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                // Add to current row
                rowWidth += size.width + (index > 0 ? spacing : 0)
                rowHeight = max(rowHeight, size.height)
            }
        }
        
        // Add the last row
        height += rowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            if rowX + size.width > bounds.maxX {
                // Start a new row
                rowX = bounds.minX
                rowY += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: rowX, y: rowY),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            
            rowHeight = max(rowHeight, size.height)
            rowX += size.width + spacing
        }
    }
}

#Preview {
    NavigationView {
        MedicalRecordsView()
    }
}