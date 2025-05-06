//
//  QRHealthProfileView.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// Represents a user's health profile with all relevant medical information
/// This model is used to generate QR codes that can be shared with healthcare providers
struct HealthProfile {
    /// User's full name
    var name: String = ""
    
    /// User's date of birth
    var dateOfBirth: Date = Date()
    
    /// User's blood type (e.g., A+, O-, AB+)
    var bloodType: String = ""
    
    /// List of user's allergies
    var allergies: String = ""
    
    /// Current medications the user is taking
    var medications: String = ""
    
    /// Emergency contact information (name and phone number)
    var emergencyContact: String = ""
    
    /// Chronic or relevant medical conditions
    var medicalConditions: String = ""
    
    /// Health insurance provider and policy details
    var insuranceInfo: String = ""
    
    /// Date when the profile was last updated
    var lastUpdated: Date = Date()
    
    /// Convert profile to JSON string for QR code generation
    /// This string representation can be encoded in a QR code and later decoded
    /// - Returns: JSON string representation of the profile
    func toJSONString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        let profileDict: [String: String] = [
            "name": name,
            "dateOfBirth": formatter.string(from: dateOfBirth),
            "bloodType": bloodType,
            "allergies": allergies,
            "medications": medications,
            "emergencyContact": emergencyContact,
            "medicalConditions": medicalConditions,
            "insuranceInfo": insuranceInfo,
            "lastUpdated": formatter.string(from: lastUpdated)
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: profileDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{}"
    }
}

/// `QRHealthProfileView` allows users to create, view, and share a QR code
/// containing their essential medical information for emergency situations
/// or quick sharing with healthcare providers.
struct QRHealthProfileView: View {
    // MARK: - State Properties
    
    /// The user's health profile data
    @State private var healthProfile = HealthProfile()
    
    /// Controls visibility of QR code or profile view
    @State private var showingQRCode = false
    
    /// The generated QR code image
    @State private var generatedQRCode: UIImage?
    
    /// Controls visibility of the share sheet
    @State private var showingShareSheet = false
    
    /// Controls visibility of the profile editor
    @State private var showingEditProfile = false
    
    /// Whether to apply encryption to the QR code data
    @State private var encryptionEnabled = true
    
    /// Indicates if QR generation is in progress
    @State private var isGeneratingQR = false
    
    /// Controls the visibility of the success toast notification
    @State private var showingSuccessToast = false
    
    /// Currently selected tab (0 = Profile, 1 = QR Code)
    @State private var selectedTab = 0
    
    /// Selected information category in the profile view
    @State private var selectedInfoType: InfoType = .personal
    
    /// Represents the different categories of health profile information
    enum InfoType: String, CaseIterable {
        case personal = "Personal"
        case medical = "Medical"
        case emergency = "Emergency"
    }
    
    /// Controls visibility of the QR code context menu
    @State private var showingContextMenu = false
    
    // MARK: - QR Code Generation Properties
    
    /// Context for rendering CIImages to CGImages
    let context = CIContext()
    
    /// QR code generator filter from CoreImage
    let filter = CIFilter.qrCodeGenerator()
    
    // MARK: - Main View
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector to switch between Profile and QR Code views
            Picker("View Mode", selection: $selectedTab) {
                Text("Profile").tag(0)
                Text("QR Code").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Show either the profile view or QR code view based on selected tab
            if selectedTab == 0 {
                profileView
            } else {
                qrCodeView
            }
        }
        .navigationTitle("Health Profile QR")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditProfile = true
                }) {
                    Text("Edit")
                        .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditHealthProfileView(profile: $healthProfile)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let qrCode = generatedQRCode {
                ShareSheet(items: [qrCode])
            }
        }
        .onAppear {
            // Generate QR code when the view appears
            generateQRCode()
        }
        .overlay(
            // Success toast notification overlay
            successToastView
                .opacity(showingSuccessToast ? 1 : 0)
                .animation(.easeInOut, value: showingSuccessToast)
        )
    }
    
    // MARK: - Profile View
    /// Profile view showing the user's health information in a structured format
    var profileView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile header with user avatar and basic info
                VStack(spacing: 15) {
                    // Avatar circle with user's initial
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Text(healthProfile.name.first?.uppercased() ?? "")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    // User's name
                    Text(healthProfile.name)
                        .font(.system(size: 24, weight: .bold))
                    
                    // Date of birth and blood type info
                    HStack {
                        Label {
                            Text(formattedDate(healthProfile.dateOfBirth))
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                            .frame(width: 20)
                        
                        Label {
                            Text(healthProfile.bloodType.isEmpty ? "Not specified" : healthProfile.bloodType)
                                .foregroundColor(healthProfile.bloodType.isEmpty ? .secondary : .primary)
                        } icon: {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(
                    // Card styling with shadow
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Information category selector
                VStack(alignment: .leading, spacing: 15) {
                    Text("Health Information")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Horizontal scrolling category buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(InfoType.allCases, id: \.self) { type in
                                CategoryButton(
                                    title: type.rawValue,
                                    imageName: iconForCategory(type),
                                    isSelected: selectedInfoType == type,
                                    action: {
                                        selectedInfoType = type
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Dynamic content based on selected information category
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedInfoType {
                    case .personal:
                        // Personal information section (name, DOB, blood type)
                        InfoSection(title: "Personal Information", items: [
                            InfoItem(title: "Full Name", value: healthProfile.name),
                            InfoItem(title: "Date of Birth", value: formattedDate(healthProfile.dateOfBirth)),
                            InfoItem(title: "Blood Type", value: healthProfile.bloodType)
                        ])
                        
                    case .medical:
                        // Medical information section (allergies, medications, conditions)
                        InfoSection(title: "Medical Information", items: [
                            InfoItem(title: "Allergies", value: healthProfile.allergies),
                            InfoItem(title: "Medications", value: healthProfile.medications),
                            InfoItem(title: "Medical Conditions", value: healthProfile.medicalConditions)
                        ])
                        
                    case .emergency:
                        // Emergency information section (contacts, insurance)
                        InfoSection(title: "Emergency Information", items: [
                            InfoItem(title: "Emergency Contact", value: healthProfile.emergencyContact),
                            InfoItem(title: "Insurance", value: healthProfile.insuranceInfo)
                        ])
                    }
                    
                    // Last updated timestamp
                    HStack {
                        Spacer()
                        Text("Last updated: \(formattedDate(healthProfile.lastUpdated))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Call-to-action button to generate and view QR code
                Button(action: {
                    selectedTab = 1
                    generateQRCode()
                }) {
                    HStack {
                        Image(systemName: "qrcode")
                            .font(.system(size: 18))
                        Text("Generate QR Code")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - QR Code View
    /// View showing the generated QR code with sharing options
    var qrCodeView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // QR code display card
                VStack(spacing: 15) {
                    if isGeneratingQR {
                        // Loading indicator while generating QR code
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(50)
                    } else if let qrImage = generatedQRCode {
                        // QR code title
                        Text("\(healthProfile.name)'s Health Profile")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        // QR code image with context menu
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .padding(15)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .onTapGesture {
                                showingContextMenu = true
                            }
                            .contextMenu {
                                // Context menu options for QR code
                                Button(action: {
                                    showingShareSheet = true
                                }) {
                                    Label("Share QR Code", systemImage: "square.and.arrow.up")
                                }
                                
                                Button(action: {
                                    saveQRCodeToPhotos()
                                }) {
                                    Label("Save to Photos", systemImage: "photo")
                                }
                            }
                    } else {
                        // Error message if QR generation fails
                        Text("Failed to generate QR code")
                            .foregroundColor(.secondary)
                            .padding(50)
                    }
                    
                    // QR code security settings
                    VStack(spacing: 10) {
                        // Security toggle switch
                        Toggle(isOn: $encryptionEnabled) {
                            Label {
                                Text("Enhanced Security")
                                    .font(.subheadline)
                            } icon: {
                                Image(systemName: "lock.shield")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .onChange(of: encryptionEnabled) { _ in
                            // Re-generate QR code when encryption setting changes
                            generateQRCode()
                        }
                        
                        // Expiration notice
                        Text("QR code is valid until \(expiryDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Sharing options card
                VStack(alignment: .leading, spacing: 15) {
                    Text("Share Options")
                        .font(.headline)
                        .padding(.leading)
                    
                    // Row of sharing option buttons
                    HStack(spacing: 20) {
                        SharingOptionButton(
                            title: "Share",
                            systemName: "square.and.arrow.up",
                            color: .blue
                        ) {
                            showingShareSheet = true
                        }
                        
                        SharingOptionButton(
                            title: "Email",
                            systemName: "envelope.fill",
                            color: Color(red: 0.2, green: 0.6, blue: 0.9)
                        ) {
                            // Would launch email in a real app
                            showSuccessToast("Email sharing initiated")
                        }
                        
                        SharingOptionButton(
                            title: "Message",
                            systemName: "message.fill",
                            color: .green
                        ) {
                            // Would launch messages in a real app
                            showSuccessToast("Message sharing initiated")
                        }
                        
                        SharingOptionButton(
                            title: "Save",
                            systemName: "square.and.arrow.down",
                            color: .purple
                        ) {
                            saveQRCodeToPhotos()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Health profile summary card
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Profile Summary")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            selectedTab = 0
                        }) {
                            Text("View Full Profile")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Quick summary of key profile information
                    VStack(alignment: .leading, spacing: 10) {
                        SummaryRow(
                            icon: "person.crop.circle.fill",
                            color: .blue,
                            title: "Name",
                            value: healthProfile.name
                        )
                        
                        Divider()
                        
                        SummaryRow(
                            icon: "drop.fill",
                            color: .red,
                            title: "Blood Type",
                            value: healthProfile.bloodType.isEmpty ? "Not specified" : healthProfile.bloodType
                        )
                        
                        Divider()
                        
                        SummaryRow(
                            icon: "cross.case.fill",
                            color: .green,
                            title: "Allergies",
                            value: healthProfile.allergies.isEmpty ? "None" : healthProfile.allergies,
                            isMultiline: true
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Supporting Views
    
    /// Toast message view for success notifications
    var successToastView: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                
                Text("Saved to Photos")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.green)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
            )
            .padding(.bottom, 30)
            .onAppear {
                // Auto-dismiss toast after delay
                if showingSuccessToast {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showingSuccessToast = false
                    }
                }
            }
        }
    }
    
    // MARK: - Utility functions
    
    /// Generates a QR code from the user's health profile data
    /// Uses CoreImage's QR code generator filter
    private func generateQRCode() {
        isGeneratingQR = true
        
        // Apply encryption if enabled (simplified for demo)
        let profileData = healthProfile.toJSONString()
        let finalData = encryptionEnabled ? "ENCRYPTED:\(profileData)" : profileData
        
        // Simulate processing delay with async execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let data = finalData.data(using: .ascii) else {
                isGeneratingQR = false
                return
            }
            
            // Input data to QR code generator
            self.filter.setValue(data, forKey: "inputMessage")
            
            if let outputImage = self.filter.outputImage {
                if let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent) {
                    // Create a bigger QR code with better resolution
                    let qrCode = UIImage(cgImage: cgImage)
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 3.0
                    
                    // Scale up the QR code for better readability
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: qrCode.size.width * 3, height: qrCode.size.height * 3), format: format)
                    self.generatedQRCode = renderer.image { _ in
                        qrCode.draw(in: CGRect(origin: .zero, size: CGSize(width: qrCode.size.width * 3, height: qrCode.size.height * 3)))
                    }
                }
            }
            
            isGeneratingQR = false
        }
    }
    
    /// Format date to medium style (e.g., Jan 12, 2025)
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Calculate the expiration date for the QR code (3 months from now)
    /// - Returns: Formatted date string for expiration
    private var expiryDate: String {
        let expiryDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: expiryDate)
    }
    
    /// Simulates saving the QR code to the photo library
    /// In a real app, would request permissions and save the image
    private func saveQRCodeToPhotos() {
        // In a real app, this would save to the photo library
        // Would require photo library permission
        showSuccessToast("Saved to Photos")
    }
    
    /// Shows a temporary toast notification
    /// - Parameter message: The message to display
    private func showSuccessToast(_ message: String = "Success") {
        showingSuccessToast = true
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingSuccessToast = false
        }
    }
    
    /// Returns SF Symbol icon name for each info category
    /// - Parameter type: The information category
    /// - Returns: SF Symbol icon name
    private func iconForCategory(_ type: InfoType) -> String {
        switch type {
        case .personal:
            return "person.fill"
        case .medical:
            return "heart.fill"
        case .emergency:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - UI Components

/// Button component for sharing options in the QR view
struct SharingOptionButton: View {
    /// Button label
    let title: String
    
    /// SF Symbol icon name
    let systemName: String
    
    /// Button color
    let color: Color
    
    /// Action to perform when tapped
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(12)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
            }
        }
    }
}

/// Toggleable button for category selection
struct CategoryButton: View {
    /// Button label
    let title: String
    
    /// SF Symbol icon name
    let imageName: String
    
    /// Whether this button is currently selected
    let isSelected: Bool
    
    /// Action to perform when tapped
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: imageName)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(12)
                
                Text(title)
                    .font(.system(size: 12))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
    }
}

/// Section component for displaying grouped information items
struct InfoSection: View {
    /// Section title
    let title: String
    
    /// Items to display in the section
    let items: [InfoItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                ForEach(items, id: \.title) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(item.value.isEmpty ? "Not provided" : item.value)
                            .font(.body)
                    }
                    
                    if items.last?.title != item.title {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

/// Represents a single information item with title and value
struct InfoItem: Identifiable {
    /// Unique identifier derived from title
    var id: String { title }
    
    /// Item label
    let title: String
    
    /// Item value
    let value: String
}

/// Row component for displaying items in the profile summary
struct SummaryRow: View {
    /// SF Symbol icon name
    let icon: String
    
    /// Icon color
    let color: Color
    
    /// Row label
    let title: String
    
    /// Row value
    let value: String
    
    /// Whether to allow multiple lines for value
    var isMultiline: Bool = false
    
    var body: some View {
        HStack(alignment: isMultiline ? .top : .center, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .lineLimit(isMultiline ? nil : 1)
            }
        }
    }
}

// MARK: - System Integration Components

/// UIKit wrapper for the system share sheet
struct ShareSheet: UIViewControllerRepresentable {
    /// Items to share (images, text, URLs, etc)
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Form view for editing the health profile
struct EditHealthProfileView: View {
    @Binding var profile: HealthProfile
    @Environment(\.presentationMode) var presentationMode
    
    /// Temporary state for editing profile without affecting the original until saved
    @State private var tempProfile: HealthProfile
    
    init(profile: Binding<HealthProfile>) {
        self._profile = profile
        self._tempProfile = State(initialValue: profile.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Personal Information section
                    SectionCard(title: "Personal Information") {
                        VStack(spacing: 15) {
                            FormField(title: "Full Name", text: $tempProfile.name)
                            
                            FormDateField(title: "Date of Birth", date: $tempProfile.dateOfBirth)
                            
                            FormField(title: "Blood Type", text: $tempProfile.bloodType, placeholder: "e.g., A+, O-, AB+")
                        }
                    }
                    
                    // Medical Information section
                    SectionCard(title: "Medical Information") {
                        VStack(spacing: 15) {
                            FormField(title: "Allergies", text: $tempProfile.allergies, placeholder: "e.g., Penicillin, Peanuts", isMultiline: true)
                            
                            FormField(title: "Medications", text: $tempProfile.medications, placeholder: "List current medications", isMultiline: true)
                            
                            FormField(title: "Medical Conditions", text: $tempProfile.medicalConditions, placeholder: "List any medical conditions", isMultiline: true)
                        }
                    }
                    
                    // Emergency Information section
                    SectionCard(title: "Emergency Information") {
                        VStack(spacing: 15) {
                            FormField(title: "Emergency Contact", text: $tempProfile.emergencyContact, placeholder: "Name and phone number")
                            
                            FormField(title: "Insurance Information", text: $tempProfile.insuranceInfo, placeholder: "Provider and policy number")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Health Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                // Save button
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Update last modified date when saved
                        tempProfile.lastUpdated = Date()
                        profile = tempProfile
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

/// Card container for form sections
struct SectionCard<Content: View>: View {
    /// Card title
    let title: String
    
    /// Card content
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}

/// Text input field component for forms
struct FormField: View {
    /// Field label
    let title: String
    
    /// Binding to text value
    @Binding var text: String
    
    /// Placeholder text
    var placeholder: String = ""
    
    /// Whether this is a multi-line text field
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if isMultiline {
                // Multi-line text editor with placeholder
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: 80)
                        .padding(4)
                    
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(Color(.placeholderText))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            } else {
                // Single-line text field
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
        }
    }
}

/// Date input field component for forms
struct FormDateField: View {
    /// Field label
    let title: String
    
    /// Binding to date value
    @Binding var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}

#Preview {
    QRHealthProfileView()
}