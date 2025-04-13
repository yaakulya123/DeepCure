import SwiftUI
import CoreImage.CIFilterBuiltins

struct HealthProfile {
    var name: String = ""
    var dateOfBirth: Date = Date()
    var bloodType: String = ""
    var allergies: String = ""
    var medications: String = ""
    var emergencyContact: String = ""
    var medicalConditions: String = ""
    var insuranceInfo: String = ""
    var lastUpdated: Date = Date()
    
    // Convert profile to JSON string for QR code generation
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

struct QRHealthProfileView: View {
    @State private var healthProfile = HealthProfile()
    @State private var showingQRCode = false
    @State private var generatedQRCode: UIImage?
    @State private var showingShareSheet = false
    @State private var showingEditProfile = false
    @State private var encryptionEnabled = true
    @State private var isGeneratingQR = false
    @State private var showingSuccessToast = false
    @State private var selectedTab = 0
    @State private var selectedInfoType: InfoType = .personal
    
    enum InfoType: String, CaseIterable {
        case personal = "Personal"
        case medical = "Medical"
        case emergency = "Emergency"
    }
    
    // Context menu options for QR code
    @State private var showingContextMenu = false
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View Mode", selection: $selectedTab) {
                Text("Profile").tag(0)
                Text("QR Code").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
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
            // For demo, pre-populate with sample data
            if healthProfile.name.isEmpty {
                healthProfile = createSampleProfile()
            }
            
            // Generate QR code
            generateQRCode()
        }
        .overlay(
            successToastView
                .opacity(showingSuccessToast ? 1 : 0)
                .animation(.easeInOut, value: showingSuccessToast)
        )
    }
    
    // MARK: - Profile View
    var profileView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile header
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Text(healthProfile.name.first?.uppercased() ?? "")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    
                    Text(healthProfile.name)
                        .font(.system(size: 24, weight: .bold))
                    
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
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Info categories selector
                VStack(alignment: .leading, spacing: 15) {
                    Text("Health Information")
                        .font(.headline)
                        .padding(.horizontal)
                    
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
                
                // Profile info based on selected category
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedInfoType {
                    case .personal:
                        InfoSection(title: "Personal Information", items: [
                            InfoItem(title: "Full Name", value: healthProfile.name),
                            InfoItem(title: "Date of Birth", value: formattedDate(healthProfile.dateOfBirth)),
                            InfoItem(title: "Blood Type", value: healthProfile.bloodType)
                        ])
                        
                    case .medical:
                        InfoSection(title: "Medical Information", items: [
                            InfoItem(title: "Allergies", value: healthProfile.allergies),
                            InfoItem(title: "Medications", value: healthProfile.medications),
                            InfoItem(title: "Medical Conditions", value: healthProfile.medicalConditions)
                        ])
                        
                    case .emergency:
                        InfoSection(title: "Emergency Information", items: [
                            InfoItem(title: "Emergency Contact", value: healthProfile.emergencyContact),
                            InfoItem(title: "Insurance", value: healthProfile.insuranceInfo)
                        ])
                    }
                    
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
                
                // Generate QR button
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
    var qrCodeView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // QR card
                VStack(spacing: 15) {
                    if isGeneratingQR {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(50)
                    } else if let qrImage = generatedQRCode {
                        Text("\(healthProfile.name)'s Health Profile")
                            .font(.title3)
                            .fontWeight(.medium)
                        
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
                        Text("Failed to generate QR code")
                            .foregroundColor(.secondary)
                            .padding(50)
                    }
                    
                    // QR code settings
                    VStack(spacing: 10) {
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
                
                // Sharing options
                VStack(alignment: .leading, spacing: 15) {
                    Text("Share Options")
                        .font(.headline)
                        .padding(.leading)
                    
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
                
                // Health profile summary
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
    
    // Toast message view for success notifications
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
                if showingSuccessToast {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showingSuccessToast = false
                    }
                }
            }
        }
    }
    
    // MARK: - Utility functions
    
    private func generateQRCode() {
        isGeneratingQR = true
        
        // Apply encryption if enabled (simplified for demo)
        let profileData = healthProfile.toJSONString()
        let finalData = encryptionEnabled ? "ENCRYPTED:\(profileData)" : profileData
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let data = finalData.data(using: .ascii) else {
                isGeneratingQR = false
                return
            }
            
            self.filter.setValue(data, forKey: "inputMessage")
            
            if let outputImage = self.filter.outputImage {
                if let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent) {
                    // Create a bigger QR code with better resolution
                    let qrCode = UIImage(cgImage: cgImage)
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 3.0
                    
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: qrCode.size.width * 3, height: qrCode.size.height * 3), format: format)
                    self.generatedQRCode = renderer.image { _ in
                        qrCode.draw(in: CGRect(origin: .zero, size: CGSize(width: qrCode.size.width * 3, height: qrCode.size.height * 3)))
                    }
                }
            }
            
            isGeneratingQR = false
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var expiryDate: String {
        let expiryDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: expiryDate)
    }
    
    private func saveQRCodeToPhotos() {
        // In a real app, this would save to the photo library
        // Would require photo library permission
        showSuccessToast("Saved to Photos")
    }
    
    private func showSuccessToast(_ message: String = "Success") {
        showingSuccessToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showingSuccessToast = false
        }
    }
    
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
    
    private func createSampleProfile() -> HealthProfile {
        var profile = HealthProfile()
        profile.name = "John Doe"
        profile.dateOfBirth = Calendar.current.date(from: DateComponents(year: 1980, month: 6, day: 15))!
        profile.bloodType = "O+"
        profile.allergies = "Penicillin, Peanuts"
        profile.medications = "Lisinopril 10mg, Metformin 500mg"
        profile.emergencyContact = "Jane Doe: (555) 123-4567"
        profile.medicalConditions = "Type 2 Diabetes, Hypertension"
        profile.insuranceInfo = "BlueCross #12345678"
        profile.lastUpdated = Date()
        return profile
    }
}

// MARK: - Supporting UI Components

struct SharingOptionButton: View {
    let title: String
    let systemName: String
    let color: Color
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

struct CategoryButton: View {
    let title: String
    let imageName: String
    let isSelected: Bool
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

struct InfoSection: View {
    let title: String
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

struct InfoItem: Identifiable {
    var id: String { title }
    let title: String
    let value: String
}

struct SummaryRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
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

// UI components for other views
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct EditHealthProfileView: View {
    @Binding var profile: HealthProfile
    @Environment(\.presentationMode) var presentationMode
    
    // Temporary state for editing
    @State private var tempProfile: HealthProfile
    
    init(profile: Binding<HealthProfile>) {
        self._profile = profile
        self._tempProfile = State(initialValue: profile.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Personal Information
                    SectionCard(title: "Personal Information") {
                        VStack(spacing: 15) {
                            FormField(title: "Full Name", text: $tempProfile.name)
                            
                            FormDateField(title: "Date of Birth", date: $tempProfile.dateOfBirth)
                            
                            FormField(title: "Blood Type", text: $tempProfile.bloodType, placeholder: "e.g., A+, O-, AB+")
                        }
                    }
                    
                    // Medical Information
                    SectionCard(title: "Medical Information") {
                        VStack(spacing: 15) {
                            FormField(title: "Allergies", text: $tempProfile.allergies, placeholder: "e.g., Penicillin, Peanuts", isMultiline: true)
                            
                            FormField(title: "Medications", text: $tempProfile.medications, placeholder: "List current medications", isMultiline: true)
                            
                            FormField(title: "Medical Conditions", text: $tempProfile.medicalConditions, placeholder: "List any medical conditions", isMultiline: true)
                        }
                    }
                    
                    // Emergency Information
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        tempProfile.lastUpdated = Date()
                        profile = tempProfile
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
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

struct FormField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if isMultiline {
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

struct FormDateField: View {
    let title: String
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