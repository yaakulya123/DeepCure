import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    var attachments: [String] = []
}

struct AIGuidanceView: View {
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isTyping = false
    @State private var showSuggestions = true
    @State private var showAttachmentPicker = false
    @State private var selectedAttachments: [String] = []
    @State private var showingSettings = false
    
    // Suggested questions
    let suggestedQuestions = [
        "What could cause persistent headaches?",
        "How can I manage my diabetes better?",
        "Is this medication safe during pregnancy?",
        "What should I know about my high blood pressure?",
        "How to interpret my recent blood test results?"
    ]
    
    // AI assistant types
    let assistantTypes = ["General Medical", "Medication", "Nutrition", "Mental Health", "Chronic Care"]
    @State private var selectedAssistantType = "General Medical"
    
    var body: some View {
        VStack(spacing: 0) {
            // Assistant type selector
            assistantTypeSelector
                .padding(.top, 10)
            
            // Messages area
            messagesView
            
            // Suggestions area
            if showSuggestions && messages.isEmpty {
                suggestionsView
            }
            
            // Input area
            inputArea
        }
        .navigationTitle("AI Medical Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            if messages.isEmpty {
                // Add initial AI message
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    addAIMessage("Hello! I'm your DeepCure Medical Assistant. How can I help you today? Please note that I provide general information only and don't replace professional medical advice.")
                }
            }
        }
    }
    
    // Assistant type selector at the top
    var assistantTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(assistantTypes, id: \.self) { type in
                    Button(action: {
                        selectedAssistantType = type
                        // Optional: Add transition message when changing assistant type
                        if !messages.isEmpty {
                            addAIMessage("Switching to \(type) assistant. How can I help you?")
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: iconForAssistantType(type))
                                .font(.system(size: 22))
                                .foregroundColor(selectedAssistantType == type ? .white : .blue)
                                .frame(width: 50, height: 50)
                                .background(
                                    selectedAssistantType == type ? 
                                        colorForAssistantType(type) : 
                                        colorForAssistantType(type).opacity(0.15)
                                )
                                .cornerRadius(25)
                            
                            Text(type)
                                .font(.caption)
                                .fontWeight(selectedAssistantType == type ? .medium : .regular)
                                .foregroundColor(selectedAssistantType == type ? colorForAssistantType(type) : .primary)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
    
    // Messages area
    var messagesView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if isTyping {
                        TypingIndicator()
                            .id("typingIndicator")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)
            }
            .onChange(of: messages.count) { _ in
                withAnimation {
                    if let lastMessage = messages.last {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isTyping) { _ in
                withAnimation {
                    if isTyping {
                        scrollView.scrollTo("typingIndicator", anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // Suggestions view
    var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggested questions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(suggestedQuestions, id: \.self) { question in
                Button(action: {
                    messageText = question
                    sendMessage()
                }) {
                    HStack {
                        Text(question)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // Input area at the bottom
    var inputArea: some View {
        VStack(spacing: 0) {
            // Attachment preview if attachments selected
            if !selectedAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedAttachments, id: \.self) { attachment in
                            AttachmentPreview(fileName: attachment) {
                                if let index = selectedAttachments.firstIndex(of: attachment) {
                                    selectedAttachments.remove(at: index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGray6))
            }
            
            // Message input and buttons
            HStack(alignment: .bottom, spacing: 10) {
                Button(action: {
                    showAttachmentPicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                // Text field
                ZStack(alignment: .trailing) {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .padding(.trailing, 35)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .lineLimit(5)
                    
                    if !messageText.isEmpty {
                        Button(action: {
                            messageText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 10)
                        }
                    }
                }
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.systemGray5)),
                alignment: .top
            )
        }
    }
    
    // Helper functions
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let userMessage = Message(
            content: trimmedMessage,
            isUser: true,
            timestamp: Date(),
            attachments: selectedAttachments
        )
        
        withAnimation {
            messages.append(userMessage)
            messageText = ""
            selectedAttachments = []
            showSuggestions = false
        }
        
        // Simulate AI typing
        withAnimation {
            isTyping = true
        }
        
        // Generate AI response (simulated delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...3.0)) {
            generateAIResponse(to: trimmedMessage)
        }
    }
    
    func generateAIResponse(to message: String) {
        // Generate response based on assistant type and user message
        // This would connect to an actual AI service in a real app
        
        let responseOptions: [String: [String]] = [
            "General Medical": [
                "Based on what you've described, these symptoms could be related to several conditions. It would be best to consult with your healthcare provider for a proper diagnosis.",
                "I understand your concern. While I can provide general information, your healthcare provider would be the best person to evaluate your specific situation.",
                "This is a common health question. Here's what medical research suggests, though always consult with your doctor for personalized advice."
            ],
            "Medication": [
                "Regarding your medication question, it's important to understand potential interactions and side effects. Here's what I can tell you, though consult your pharmacist for specific advice.",
                "This medication typically works by [mechanism of action]. Common side effects may include [effects], but everyone's response can be different.",
                "When taking this medication, it's generally recommended to [administration advice]. Always follow your doctor's specific instructions."
            ],
            "Nutrition": [
                "For your nutritional needs, consider incorporating more foods rich in [nutrients]. These include [food examples].",
                "Based on current dietary guidelines, a balanced approach to your situation might include [recommendations].",
                "Nutritional research suggests that for your concern, focusing on [dietary approach] may be beneficial. Consider consulting with a registered dietitian."
            ],
            "Mental Health": [
                "What you're describing is something many people experience. Some strategies that might help include [coping strategies].",
                "Mental health is an important aspect of overall wellbeing. While I can offer general information, a mental health professional can provide personalized support.",
                "Practices like mindfulness, regular physical activity, and adequate sleep can support mental wellbeing. Professional guidance is also valuable."
            ],
            "Chronic Care": [
                "Managing chronic conditions often involves a multi-faceted approach. Regular monitoring of [parameters] can help track your progress.",
                "For ongoing management of your condition, consider discussing [management strategies] with your healthcare provider.",
                "Living well with chronic conditions often involves both medical management and lifestyle adjustments. Let's discuss some approaches that might help."
            ]
        ]
        
        let responses = responseOptions[selectedAssistantType] ?? responseOptions["General Medical"]!
        let aiResponse = responses.randomElement() ?? "I understand your concern and can provide some general information. For specific medical advice, please consult with your healthcare provider."
        
        withAnimation {
            isTyping = false
            addAIMessage(aiResponse)
        }
    }
    
    func addAIMessage(_ content: String) {
        let aiMessage = Message(
            content: content,
            isUser: false,
            timestamp: Date()
        )
        messages.append(aiMessage)
    }
    
    func iconForAssistantType(_ type: String) -> String {
        switch type {
        case "General Medical": return "heart.text.square.fill"
        case "Medication": return "pills.fill"
        case "Nutrition": return "leaf.fill"
        case "Mental Health": return "brain.head.profile"
        case "Chronic Care": return "chart.line.uptrend.xyaxis.circle.fill"
        default: return "stethoscope"
        }
    }
    
    func colorForAssistantType(_ type: String) -> Color {
        switch type {
        case "General Medical": return .blue
        case "Medication": return .purple
        case "Nutrition": return .green
        case "Mental Health": return .orange
        case "Chronic Care": return .teal
        default: return .blue
        }
    }
}

// Message bubble component
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(20)
                    .cornerRadius(20, corners: message.isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                
                // Attachments if any
                if !message.attachments.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(message.attachments, id: \.self) { attachment in
                            HStack(spacing: 8) {
                                Image(systemName: "paperclip")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(attachment)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Typing indicator for AI responses
struct TypingIndicator: View {
    @State private var animationOffset = 0.0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 7, height: 7)
                    .foregroundColor(Color(.systemGray3))
                    .offset(y: animationOffset - Double(index * 2))
            }
        }
        .padding(12)
        .background(Color(.systemGray5))
        .cornerRadius(20)
        .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                animationOffset = -5.0
            }
        }
    }
}

// Attachment preview component
struct AttachmentPreview: View {
    let fileName: String
    let onRemove: () -> Void
    
    var fileIcon: String {
        let ext = fileName.components(separatedBy: ".").last?.lowercased() ?? ""
        
        switch ext {
        case "pdf": return "doc.text.fill"
        case "jpg", "jpeg", "png": return "photo.fill"
        case "doc", "docx": return "doc.fill"
        default: return "paperclip"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: fileIcon)
                .font(.system(size: 15))
                .foregroundColor(.blue)
            
            Text(fileName.count > 15 ? String(fileName.prefix(15)) + "..." : fileName)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// Settings view
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var aiModelType = "Advanced"
    @State private var enableCitationLinks = true
    @State private var saveConversationHistory = true
    @State private var enableAutoSuggestions = true
    @State private var languagePreference = "English"
    
    let aiModelOptions = ["Standard", "Advanced", "Expert"]
    let languageOptions = ["English", "Spanish", "French", "German", "Chinese", "Japanese"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Assistant Settings")) {
                    Picker("AI Model", selection: $aiModelType) {
                        ForEach(aiModelOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    
                    Toggle("Enable Citation Links", isOn: $enableCitationLinks)
                    Toggle("Save Conversation History", isOn: $saveConversationHistory)
                    Toggle("Enable Auto-Suggestions", isOn: $enableAutoSuggestions)
                }
                
                Section(header: Text("Language & Display")) {
                    Picker("Language", selection: $languagePreference) {
                        ForEach(languageOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("AI Model Version")
                        Spacer()
                        Text("DeepCure v3.2.1")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text("April 12, 2025")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: PrivacyView()) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: TermsView()) {
                        Text("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
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
}

// Placeholder Views for Privacy and Terms
struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last updated: April 12, 2025")
                    .foregroundColor(.secondary)
                
                Text("This privacy policy describes how DeepCure collects, uses, and shares your personal information when you use our application.")
                
                Text("Information We Collect")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("• Medical data you provide\n• Conversation history with our AI\n• Device information\n• Usage statistics")
                
                Text("How We Use Your Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("DeepCure uses advanced encryption to protect your data. Your medical information is used only to provide you with personalized assistance and is never sold to third parties.")
                
                Text("DeepCure complies with HIPAA regulations and follows industry best practices for data security.")
            }
            .padding()
        }
    }
}

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Last updated: April 12, 2025")
                    .foregroundColor(.secondary)
                
                Text("DeepCure provides AI-assisted medical guidance but is not a substitute for professional medical advice, diagnosis, or treatment.")
                
                Text("By using this application, you agree to these terms and acknowledge that you should always consult with qualified healthcare providers for medical decisions.")
                
                Text("Medical Disclaimer")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("The information provided by DeepCure is for informational and educational purposes only. It is not intended to replace professional medical advice, diagnosis, or treatment.")
            }
            .padding()
        }
    }
}

// Helper extension for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationView {
        AIGuidanceView()
    }
}