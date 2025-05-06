import SwiftUI

/// Represents a single message in the AI chat conversation
/// Contains the message content, sender information, timestamp, and any attachments
struct Message: Identifiable {
    /// Unique identifier for each message
    let id = UUID()
    
    /// The text content of the message
    let content: String
    
    /// Indicates if this message was sent by the user (true) or AI (false)
    let isUser: Bool
    
    /// When the message was sent
    let timestamp: Date
    
    /// Optional list of attachment filenames
    var attachments: [String] = []
}

/// `AIGuidanceView` provides a chat interface for interacting with different
/// types of medical AI assistants. Users can ask health-related questions and
/// receive evidence-based information.
struct AIGuidanceView: View {
    // MARK: - State Variables
    
    /// Text being composed by the user
    @State private var messageText = ""
    
    /// Conversation history between user and AI
    @State private var messages: [Message] = []
    
    /// Indicates when the AI is composing a response
    @State private var isTyping = false
    
    /// Controls the visibility of suggested questions
    @State private var showSuggestions = true
    
    /// Controls the visibility of the attachment picker
    @State private var showAttachmentPicker = false
    
    /// Files selected to attach to the message
    @State private var selectedAttachments: [String] = []
    
    /// Controls the visibility of the settings sheet
    @State private var showingSettings = false
    
    /// Pre-defined questions to help users get started
    let suggestedQuestions = [
        "What could cause persistent headaches?",
        "How can I manage my diabetes better?",
        "Is this medication safe during pregnancy?",
        "What should I know about my high blood pressure?",
        "How to interpret my recent blood test results?"
    ]
    
    /// The different types of specialized medical AI assistants available
    let assistantTypes = ["General Medical", "Medication", "Nutrition", "Mental Health", "Chronic Care"]
    
    /// Currently selected AI assistant type
    @State private var selectedAssistantType = "General Medical"
    
    // MARK: - Main View
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector for different AI assistant types
            assistantTypeSelector
                .padding(.top, 10)
            
            // Chat message history area
            messagesView
            
            // Suggested questions (shown only when conversation is empty)
            if showSuggestions && messages.isEmpty {
                suggestionsView
            }
            
            // Message composition and submission area
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
                // Display welcome message when first opening the assistant
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    addAIMessage("Hello! I'm your DeepCure Medical Assistant. How can I help you today? Please note that I provide general information only and don't replace professional medical advice.")
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    /// Horizontal scrolling selector for different AI assistant types
    /// Each type has a specialized knowledge domain and visual styling
    var assistantTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(assistantTypes, id: \.self) { type in
                    Button(action: {
                        selectedAssistantType = type
                        // Notify the user when changing assistant type mid-conversation
                        if !messages.isEmpty {
                            addAIMessage("Switching to \(type) assistant. How can I help you?")
                        }
                    }) {
                        VStack(spacing: 6) {
                            // Icon with appropriate medical symbol for each assistant type
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
                            
                            // Assistant type label
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
            // Subtle divider line at the bottom
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
    
    /// Scrollable area displaying the conversation history
    /// Uses ScrollViewReader to auto-scroll to the latest message
    var messagesView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Display all messages in the conversation
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    // Show animated typing indicators when AI is composing response
                    if isTyping {
                        TypingIndicator()
                            .id("typingIndicator")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)
            }
            // Auto-scroll when new messages appear
            .onChange(of: messages.count) { _ in
                withAnimation {
                    if let lastMessage = messages.last {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            // Auto-scroll when typing indicator appears
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
    
    /// Grid of suggested questions to help users get started
    /// Only visible when conversation is empty
    var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggested questions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Display each suggested question as a tappable button
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
    
    /// Message composition area at the bottom of the screen
    /// Includes attachment previews, text input, and send button
    var inputArea: some View {
        VStack(spacing: 0) {
            // Show attachment previews if files are selected
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
            
            // Message composition controls
            HStack(alignment: .bottom, spacing: 10) {
                // Attachment button
                Button(action: {
                    showAttachmentPicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                // Text input field with clear button
                ZStack(alignment: .trailing) {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .padding(.trailing, 35)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .lineLimit(5)
                    
                    // Clear text button (only visible when text exists)
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
                // Subtle divider line at the top
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.systemGray5)),
                alignment: .top
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Process and send the user's message to the AI assistant
    /// Also triggers the AI response generation
    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create and add the user's message to the conversation
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
        
        // Show typing indicator while waiting for AI response
        withAnimation {
            isTyping = true
        }
        
        // Request AI response from GPT service
        GPTService.shared.getAIMedicalGuidance(query: trimmedMessage, assistantType: selectedAssistantType) { result in
            DispatchQueue.main.async {
                // Hide typing indicator
                withAnimation {
                    self.isTyping = false
                }
                
                // Process the AI response or handle errors
                switch result {
                case .success(let response):
                    self.addAIMessage(response)
                case .failure(let error):
                    self.addAIMessage("I'm sorry, I encountered an issue while processing your question. Please try again. Error: \(error.localizedDescription)")
                    print("AI Response error: \(error)")
                }
            }
        }
    }
    
    /// Adds an AI response message to the conversation
    /// - Parameter content: The text content of the AI's response
    func addAIMessage(_ content: String) {
        let aiMessage = Message(
            content: content,
            isUser: false,
            timestamp: Date()
        )
        messages.append(aiMessage)
    }
    
    /// Returns the appropriate SF Symbol name for each assistant type
    /// - Parameter type: The assistant type
    /// - Returns: Name of the SF Symbol icon
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
    
    /// Returns the appropriate color for each assistant type
    /// - Parameter type: The assistant type
    /// - Returns: Color for visual differentiation
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

// MARK: - Supporting UI Components

/// Speech bubble component for displaying individual messages in the conversation
struct MessageBubble: View {
    /// The message to display
    let message: Message
    
    var body: some View {
        HStack {
            // Position user messages on the right, AI messages on the left
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Message content bubble
                Text(message.content)
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(20)
                    .cornerRadius(20, corners: message.isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                
                // Display attachments if present
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
                
                // Message timestamp
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
    
    /// Format the timestamp to a user-friendly time string
    /// - Parameter date: The message's timestamp
    /// - Returns: Formatted time string (e.g., "2:30 PM")
    func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Animated dots to indicate that the AI is typing a response
struct TypingIndicator: View {
    /// Controls the animation offset for the bouncing dots
    @State private var animationOffset = 0.0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            // Three animated dots that move up and down
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
            // Start continuous animation when indicator appears
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) {
                animationOffset = -5.0
            }
        }
    }
}

/// Preview for attachment files selected by the user
struct AttachmentPreview: View {
    /// Name of the attached file
    let fileName: String
    
    /// Callback for removing the attachment
    let onRemove: () -> Void
    
    /// Determine appropriate icon based on file extension
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
            // File type icon
            Image(systemName: fileIcon)
                .font(.system(size: 15))
                .foregroundColor(.blue)
            
            // Truncate long filenames with ellipsis
            Text(fileName.count > 15 ? String(fileName.prefix(15)) + "..." : fileName)
                .font(.caption)
                .lineLimit(1)
            
            // Remove attachment button
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

// MARK: - Settings Views

/// View for configuring AI assistant preferences and settings
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    /// Selected AI model complexity/capabilities
    @State private var aiModelType = "Advanced"
    
    /// Whether to include citation links in responses
    @State private var enableCitationLinks = true
    
    /// Whether to save conversations for future reference
    @State private var saveConversationHistory = true
    
    /// Whether to show suggestion chips during conversation
    @State private var enableAutoSuggestions = true
    
    /// UI language preference
    @State private var languagePreference = "English"
    
    /// Available AI model options
    let aiModelOptions = ["Standard", "Advanced", "Expert"]
    
    /// Available language options
    let languageOptions = ["English", "Spanish", "French", "German", "Chinese", "Japanese"]
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: AI Assistant Configuration
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
                
                // MARK: Language Settings
                Section(header: Text("Language & Display")) {
                    Picker("Language", selection: $languagePreference) {
                        ForEach(languageOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }
                
                // MARK: App Information
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

/// View displaying the app's privacy policy
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

/// View displaying the app's terms of service
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

// MARK: - Utility Extensions

/// Extension to support rounded corners on specific sides of a view
extension View {
    /// Apply corner radius to specific corners of a view
    /// - Parameters:
    ///   - radius: The corner radius value
    ///   - corners: Which corners to round (e.g., [.topLeft, .topRight])
    /// - Returns: Modified view with specified corners rounded
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

/// Custom shape for applying rounded corners to specific corners
struct RoundedCorner: Shape {
    /// The radius of the rounded corners
    var radius: CGFloat = .infinity
    
    /// Which corners to apply rounding to
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

// MARK: - Preview
#Preview {
    NavigationView {
        AIGuidanceView()
    }
}