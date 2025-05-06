//
//  MedicalRecordsView.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

/// Represents a medical record with its associated metadata and content
/// Medical records can include various types such as lab results, prescriptions, or doctor's notes
struct MedicalRecord: Identifiable {
    /// Unique identifier for the record
    let id = UUID()
    
    /// Title/name of the medical record
    let title: String
    
    /// Date when the medical event occurred
    let date: Date
    
    /// Name of the healthcare provider
    let doctor: String
    
    /// Name of the medical facility
    let hospital: String
    
    /// Category of medical record (lab, prescription, etc)
    let recordType: RecordType
    
    /// Text content of the medical record
    let content: String
    
    /// Files attached to this record (PDFs, images, etc)
    let attachments: [Attachment]
    
    /// Whether the user has marked this record as important
    var isFavorite: Bool = false
    
    /// User-defined labels for organization and searching
    var tags: [String] = []
    
    /// Enumeration of different medical record categories
    enum RecordType: String, CaseIterable {
        case labResult = "Lab Result"
        case prescription = "Prescription"
        case doctorNote = "Doctor's Note"
        case radiology = "Radiology"
        case procedure = "Procedure"
        case vaccination = "Vaccination"
        
        /// SF Symbol icon name for each record type
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
        
        /// Color associated with each record type for visual differentiation
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

/// Represents a file attached to a medical record
struct Attachment: Identifiable {
    /// Unique identifier for the attachment
    var id = UUID()
    
    /// Name of the file
    var fileName: String
    
    /// Type of file (PDF, image, document)
    var fileType: FileType
    
    /// Binary data of the file, if loaded in memory
    var fileData: Data?
    
    /// URL to the file, if stored on disk
    var fileURL: URL?
    
    /// Enumeration of different attachment file types
    enum FileType: String {
        case pdf = "pdf"
        case image = "image"
        case document = "document"
        
        /// SF Symbol icon name for each file type
        var icon: String {
            switch self {
            case .pdf: return "doc.text.fill"
            case .image: return "photo.fill"
            case .document: return "doc.fill"
            }
        }
        
        /// Color associated with each file type for visual differentiation
        var color: Color {
            switch self {
            case .pdf: return .red
            case .image: return .blue
            case .document: return .green
            }
        }
    }
}

/// `MedicalRecordsView` is the main interface for viewing, organizing,
/// and managing a user's medical records. It provides filtering, sorting,
/// and search capabilities to help users find records quickly.
struct MedicalRecordsView: View {
    // MARK: - State Variables
    
    /// Text to filter records by
    @State private var searchText = ""
    
    /// Currently selected category filter
    @State private var selectedFilter: String = "All"
    
    /// Record selected for detailed viewing
    @State private var selectedRecord: MedicalRecord?
    
    /// Controls visibility of record detail sheet
    @State private var showingRecordDetail = false
    
    /// Collection of all user's medical records
    @State private var records: [MedicalRecord] = []
    
    /// Controls visibility of add record sheet
    @State private var showingAddRecord = false
    
    /// Controls visibility of sort options menu
    @State private var showingSortOptions = false
    
    /// Current sort order for records
    @State private var sortOrder = SortOrder.dateDescending
    
    /// Available sort options for records
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case alphabetical = "A to Z"
        case type = "By Type"
        
        /// SF Symbol icon name for each sort order
        var systemImage: String {
            switch self {
            case .dateDescending: return "arrow.down.circle"
            case .dateAscending: return "arrow.up.circle"
            case .alphabetical: return "textformat.abc"
            case .type: return "tag"
            }
        }
    }
    
    /// All available filter options, combining "All" with each record type
    let filterOptions = ["All"] + MedicalRecord.RecordType.allCases.map { $0.rawValue }
    
    // MARK: - Main View
    var body: some View {
        VStack(spacing: 0) {
            // MARK: Search and Filter Bar
            
            // Search field and category filter chips
            VStack(spacing: 12) {
                // Search input field with clear button
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
                
                // Horizontal scrolling filter chips
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
            
            // MARK: Records List / Empty State
            
            // Show empty state or records list based on filter results
            if filteredRecords.isEmpty {
                emptyStateView
            } else {
                recordsListView
            }
        }
        .navigationTitle("Medical Records")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Sort menu button
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
                // Add new record button
                Button(action: {
                    showingAddRecord = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            // Form for creating a new medical record
            AddRecordView(onSave: { newRecord in
                records.append(newRecord)
            })
        }
        .sheet(item: $selectedRecord) { record in
            // Detailed view of a selected record
            RecordDetailView(record: record)
        }
    }
    
    // MARK: - View Components
    
    /// Empty state view shown when no records match the current filters
    var emptyStateView: some View {
        VStack(spacing: 20) {
            // Empty state icon
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.7))
                .padding(.bottom, 10)
            
            // Primary message varies based on search/filter state
            Text(searchText.isEmpty ? "No Records Found" : "No Matching Records")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Secondary explanatory message
            Text(searchText.isEmpty ?
                "Your medical records will appear here" :
                "Try adjusting your search or filters")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Clear filters button (only shown when filters are active)
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
    
    /// List view showing filtered and sorted medical records
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
    
    // MARK: - Helper Methods
    
    /// Returns records filtered by category and search term
    var filteredRecords: [MedicalRecord] {
        var result = records
        
        // Apply category filter if not showing "All"
        if selectedFilter != "All" {
            result = result.filter { $0.recordType.rawValue == selectedFilter }
        }
        
        // Apply search filter if search text exists
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
    
    /// Returns records sorted according to the current sort order
    var filteredAndSortedRecords: [MedicalRecord] {
        let filtered = filteredRecords
        
        switch sortOrder {
        case .dateDescending:
            // Newest records first
            return filtered.sorted { $0.date > $1.date }
        case .dateAscending:
            // Oldest records first
            return filtered.sorted { $0.date < $1.date }
        case .alphabetical:
            // Alphabetical by title
            return filtered.sorted { $0.title < $1.title }
        case .type:
            // Grouped by record type
            return filtered.sorted { $0.recordType.rawValue < $1.recordType.rawValue }
        }
    }
}

// MARK: - Supporting UI Components

/// Component for displaying a single record in the list
struct RecordRow: View {
    /// The medical record to display
    let record: MedicalRecord
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            // Record type icon with colored background
            ZStack {
                Circle()
                    .fill(record.recordType.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: record.recordType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(record.recordType.color)
            }
            
            // Record information column
            VStack(alignment: .leading, spacing: 4) {
                // Record title
                Text(record.title)
                    .font(.system(size: 16, weight: .medium))
                
                // Doctor and hospital info
                Text(record.doctor + " • " + record.hospital)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Record metadata indicators
                HStack {
                    // Date indicator
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(formattedDate(record.date))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    // Favorite indicator (if favorited)
                    if record.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                    
                    // Attachment count indicator (if has attachments)
                    if !record.attachments.isEmpty {
                        Image(systemName: "paperclip")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("\(record.attachments.count)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Tags row (if has tags)
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
            
            // Chevron indicator for navigation
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
        }
        .padding(.vertical, 8)
    }
    
    /// Format date to medium style (e.g., Jan 12, 2025)
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

/// Toggleable filter chip component
struct FilterChip: View {
    /// Label text for the chip
    let title: String
    
    /// Whether this chip is currently selected
    let isSelected: Bool
    
    /// Action to perform when tapped
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

/// Form for adding a new medical record
struct AddRecordView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Form fields
    @State private var title = ""
    @State private var doctor = ""
    @State private var hospital = ""
    @State private var recordType: MedicalRecord.RecordType = .doctorNote
    @State private var content = ""
    @State private var date = Date()
    @State private var attachments: [Attachment] = []
    
    // Sheet control
    @State private var showingDocumentPicker = false
    @State private var showingAttachmentOptions = false
    
    /// Callback to execute when a record is saved
    let onSave: (MedicalRecord) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: Basic Information Section
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
                
                // MARK: Content Section
                Section(header: Text("Contents")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
                
                // MARK: Attachments Section
                Section(header: Text("Attachments")) {
                    if attachments.isEmpty {
                        // Add first attachment button
                        Button(action: {
                            showingAttachmentOptions = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Add Attachment")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        // List of current attachments
                        ForEach(attachments) { attachment in
                            HStack {
                                Image(systemName: attachment.fileType.icon)
                                    .foregroundColor(attachment.fileType.color)
                                
                                Text(attachment.fileName)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                // Remove attachment button
                                Button(action: {
                                    if let index = attachments.firstIndex(where: { $0.id == attachment.id }) {
                                        attachments.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Add additional attachment button
                        Button(action: {
                            showingAttachmentOptions = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Add Another Attachment")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                // Save button (disabled if required fields are empty)
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newRecord = MedicalRecord(
                            title: title,
                            date: date,
                            doctor: doctor,
                            hospital: hospital,
                            recordType: recordType,
                            content: content,
                            attachments: attachments
                        )
                        
                        onSave(newRecord)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.isEmpty || doctor.isEmpty || hospital.isEmpty)
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(attachments: $attachments)
            }
            .actionSheet(isPresented: $showingAttachmentOptions) {
                ActionSheet(
                    title: Text("Add Attachment"),
                    message: Text("Choose attachment type"),
                    buttons: [
                        .default(Text("PDF Document")) {
                            showingDocumentPicker = true
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
}

/// UIDocumentPicker wrapper for selecting PDF files
struct DocumentPicker: UIViewControllerRepresentable {
    /// Binding to update with selected attachments
    @Binding var attachments: [Attachment]
    @Environment(\.presentationMode) var presentationMode
    
    /// Creates the document picker controller
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    /// Creates the coordinator to handle delegate callbacks
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator class to handle document picker delegate methods
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        /// Called when the user selects documents in the picker
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                // Create a file URL in the app's documents directory
                let fileName = url.lastPathComponent
                let fileType: Attachment.FileType = fileName.hasSuffix(".pdf") ? .pdf : .document
                
                do {
                    // Read the file data
                    let fileData = try Data(contentsOf: url)
                    
                    // Add to attachments
                    let attachment = Attachment(
                        fileName: fileName,
                        fileType: fileType,
                        fileData: fileData,
                        fileURL: url
                    )
                    
                    parent.attachments.append(attachment)
                } catch {
                    print("Error loading document: \(error.localizedDescription)")
                }
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

/// Detailed view of a medical record
struct RecordDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    /// The record to display
    let record: MedicalRecord
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // MARK: Record Header
                    
                    // Icon and title header
                    HStack {
                        // Type icon with colored background
                        ZStack {
                            Circle()
                                .fill(record.recordType.color.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: record.recordType.icon)
                                .font(.system(size: 30))
                                .foregroundColor(record.recordType.color)
                        }
                        
                        // Title and type info
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(record.title)
                                    .font(.system(size: 20, weight: .bold))
                                
                                if record.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            // Record type badge
                            Text(record.recordType.rawValue)
                                .font(.subheadline)
                                .foregroundColor(record.recordType.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(record.recordType.color.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // MARK: Information Section
                    
                    // Basic metadata card
                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeader(title: "Information")
                        
                        DetailRow(iconName: "person.fill", title: "Doctor", value: record.doctor)
                        DetailRow(iconName: "building.2.fill", title: "Facility", value: record.hospital)
                        DetailRow(iconName: "calendar", title: "Date", value: formattedDate(record.date))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // MARK: Content Section
                    
                    // Main record content
                    VStack(alignment: .leading, spacing: 15) {
                        SectionHeader(title: "Record Details")
                        
                        Text(record.content)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // MARK: Attachments Section
                    
                    // Attachments list (if any)
                    if !record.attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "Attachments")
                            
                            ForEach(record.attachments) { attachment in
                                AttachmentRow(attachment: attachment)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // MARK: Tags Section
                    
                    // Tags display (if any)
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
                    
                    // MARK: Action Buttons
                    
                    // Row of action buttons
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
    
    /// Format date to long style (e.g., January 12, 2025)
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - UI Helper Components

/// Section title component
struct SectionHeader: View {
    /// Title text to display
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
    }
}

/// Component for displaying a labeled data field
struct DetailRow: View {
    /// SF Symbol icon name
    let iconName: String
    
    /// Field label
    let title: String
    
    /// Field value
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

/// Component for displaying an attachment with preview capability
struct AttachmentRow: View {
    /// The attachment to display
    let attachment: Attachment
    
    /// Controls visibility of PDF viewer
    @State private var showingPDFViewer = false
    
    var body: some View {
        Button(action: {
            if attachment.fileType == .pdf {
                showingPDFViewer = true
            }
        }) {
            HStack {
                Image(systemName: attachment.fileType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(attachment.fileType.color)
                
                Text(attachment.fileName)
                    .font(.system(size: 15))
                
                Spacer()
                
                Image(systemName: "eye")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingPDFViewer) {
            if let pdfData = attachment.fileData {
                PDFViewer(data: pdfData, fileName: attachment.fileName)
            }
        }
    }
}

/// PDF document viewer component
struct PDFViewer: UIViewRepresentable {
    /// Binary data of the PDF
    let data: Data
    
    /// Name of the PDF file
    let fileName: String
    
    func makeUIView(context: Context) -> PDFKitView {
        let pdfView = PDFKitView()
        pdfView.backgroundColor = .systemBackground
        
        // Load PDF data
        pdfView.loadPDF(data: data)
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFKitView, context: Context) {}
    
    // Navigation view with toolbar for PDF viewer
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: PDFViewer
        
        init(_ parent: PDFViewer) {
            self.parent = parent
        }
    }
}

/// UIKit wrapper for displaying PDF documents with PDFKit
class PDFKitView: UIView {
    private let pdfView = PDFView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPDFView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPDFView()
    }
    
    /// Configure the PDF view with standard settings
    private func setupPDFView() {
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.pageShadowsEnabled = true
        
        addSubview(pdfView)
        
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    /// Load a PDF document from Data
    /// - Parameter data: PDF file data
    func loadPDF(data: Data) {
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
    }
}

/// Button component for record actions
struct ActionButton: View {
    /// Button label
    let title: String
    
    /// SF Symbol icon name
    let iconName: String
    
    /// Button color
    let color: Color
    
    /// Action to perform when tapped
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

/// Custom layout for wrapping tags in multiple rows
struct FlowLayout: Layout {
    /// Spacing between items
    let spacing: CGFloat
    
    /// Calculate the size needed to fit all subviews
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for (index, size) in sizes.enumerated() {
            if rowWidth + size.width > width {
                // Start a new row when the current row is full
                height += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                // Add to current row
                rowWidth += size.width + (index > 0 ? spacing : 0)
                rowHeight = max(rowHeight, size.height)
            }
        }
        
        // Add the height of the last row
        height += rowHeight
        
        return CGSize(width: width, height: height)
    }
    
    /// Position all subviews in a flow layout
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            if rowX + size.width > bounds.maxX {
                // Start a new row when we reach the right edge
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

// MARK: - Preview
#Preview {
    NavigationView {
        MedicalRecordsView()
    }
}