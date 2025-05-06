//
//  MedicalTranscriptionView.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI
import AVFoundation
import Speech

/// `MedicalTranscriptionView` provides the functionality to record, transcribe, and simplify
/// medical conversations. It uses iOS Speech Recognition for transcription and GPT for
/// medical terminology simplification.
struct MedicalTranscriptionView: View {
    // MARK: - State Variables
    
    /// Indicates whether audio recording is in progress
    @State private var isRecording = false
    
    /// Stores the text transcribed from speech
    @State private var transcribedText = ""
    
    /// Manages audio session configuration for recording
    @State private var recordingSession: AVAudioSession?
    
    /// Records audio to disk (not used in current implementation but kept for future use)
    @State private var audioRecorder: AVAudioRecorder?
    
    /// Processes real-time audio buffers for speech recognition
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// Manages the ongoing speech recognition task
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    /// The speech recognizer used for converting speech to text
    @State private var speechRecognizer: SFSpeechRecognizer?
    
    /// Manages audio processing for live speech recognition
    @State private var audioEngine = AVAudioEngine()
    
    /// Controls visibility of the save dialog
    @State private var showingSaveDialog = false
    
    /// Title for the recording when saving
    @State private var recordingTitle = ""
    
    /// Indicates whether AI simplification of medical terms is in progress
    @State private var processingTranslation = false
    
    /// Stores the simplified version of the medical text
    @State private var translatedText = ""
    
    /// Tracks the duration of the current recording in seconds
    @State private var recordingDuration = 0
    
    /// Timer for updating recording duration and visualization
    @State private var recordingTimer: Timer?
    
    /// Array of values representing the audio visualization bars
    @State private var recordingVisualization: [CGFloat] = Array(repeating: 0, count: 30)
    
    /// Controls which tab is currently shown (0 = Record, 1 = History)
    @State private var selectedTab = 0
    
    /// Collection of saved recordings
    @State private var savedRecordings: [Recording] = []
    
    /// Indicates whether microphone/speech permission has been denied
    @State private var permissionDenied = false
    
    /// User-friendly error message when permissions are denied
    @State private var permissionErrorMessage = ""
    
    // MARK: - Sample Data
    
    /// Sample medical terms to highlight in transcriptions
    /// This would be expanded in a production app with a comprehensive medical dictionary
    let medicalTerms = ["hypertension", "myocardial infarction", "atherosclerosis", "hypercholesterolemia"]
    
    // MARK: - Main View
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector to switch between recording and history view
            Picker("View Mode", selection: $selectedTab) {
                Text("Record").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Show appropriate view based on permissions and selected tab
            if permissionDenied {
                permissionDeniedView
            } else if selectedTab == 0 {
                recordingView
            } else {
                recordingsHistoryView
            }
        }
        .navigationTitle("Medical Transcription")
        .onAppear {
            // Initialize speech recognition and load existing recordings when the view appears
            setupSpeech()
            loadSampleRecordings()
        }
        .alert("Save Recording", isPresented: $showingSaveDialog) {
            VStack {
                TextField("Title", text: $recordingTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical)
            }
            
            HStack {
                Button("Cancel", role: .cancel) {
                    recordingTitle = ""
                }
                
                Button("Save") {
                    saveRecording()
                }
                .disabled(recordingTitle.isEmpty)
            }
        } message: {
            Text("Enter a title for this recording")
        }
    }
    
    // MARK: - Recording View
    
    /// View for the recording tab with transcription functionality
    var recordingView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Instructions card to help users understand the feature
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("How to use")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    Text("Tap the microphone button when your doctor is speaking to record and transcribe the conversation. After recording, use the \"Simplify\" button to translate medical terminology into easier language.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                )
                .padding(.horizontal)
                
                // Recording visualization and control section
                ZStack {
                    // Background card changes color when recording
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isRecording ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(height: 160)
                    
                    VStack(spacing: 16) {
                        // Animated audio visualization when recording
                        if isRecording {
                            HStack(alignment: .center, spacing: 3) {
                                ForEach(recordingVisualization.indices, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.red)
                                        .frame(width: 3, height: max(3, recordingVisualization[index]))
                                        .animation(.linear(duration: 0.2), value: recordingVisualization[index])
                                }
                            }
                            .frame(height: 50)
                            .padding(.horizontal)
                        } else {
                            // Static waveform icon when not recording
                            Image(systemName: "waveform")
                                .font(.system(size: 40))
                                .foregroundColor(Color.gray.opacity(0.7))
                        }
                        
                        HStack(spacing: 20) {
                            // Record/Stop button that changes based on recording state
                            Button(action: {
                                if isRecording {
                                    stopRecording()
                                } else {
                                    startRecording()
                                }
                            }) {
                                Circle()
                                    .fill(isRecording ? Color.red : Color.blue)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                            
                            // Recording status text and timer
                            VStack(alignment: .leading, spacing: 5) {
                                Text(isRecording ? "Recording..." : "Ready to record")
                                    .font(.headline)
                                    .foregroundColor(isRecording ? .red : .primary)
                                
                                if isRecording {
                                    Text(timeString(from: recordingDuration))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Tap the mic to start")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                // Transcription section showing recognized speech
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Transcription")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Menu for text actions (only shown when there's transcribed text)
                        if !transcribedText.isEmpty {
                            Menu {
                                Button(action: {
                                    // Copy transcription to clipboard
                                    UIPasteboard.general.string = transcribedText
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                
                                Button(action: {
                                    showingSaveDialog = true
                                }) {
                                    Label("Save", systemImage: "square.and.arrow.down")
                                }
                                
                                Button(role: .destructive, action: {
                                    transcribedText = ""
                                    translatedText = ""
                                }) {
                                    Label("Clear", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 18))
                            }
                        }
                    }
                    
                    if transcribedText.isEmpty {
                        // Empty state placeholder when no text is transcribed
                        VStack(spacing: 10) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.bottom, 5)
                            
                            Text("Transcribed text will appear here")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        // Display transcribed text with medical terms highlighted
                        TranscriptionTextView(
                            text: transcribedText, 
                            highlightTerms: medicalTerms
                        )
                        .frame(minHeight: 150)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Action buttons for saving and simplifying text
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showingSaveDialog = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 14))
                                    Text("Save")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                translateMedicalJargon()
                            }) {
                                HStack {
                                    Image(systemName: "text.book.closed")
                                        .font(.system(size: 14))
                                    Text("Simplify")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(processingTranslation || transcribedText.isEmpty)
                            .opacity((processingTranslation || transcribedText.isEmpty) ? 0.5 : 1)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Section for displaying AI-simplified version of the medical text
                if processingTranslation || !translatedText.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "text.book.closed")
                                .foregroundColor(.green)
                            Text("Simplified Explanation")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        
                        if processingTranslation {
                            // Loading state while AI processes the text
                            HStack {
                                Spacer()
                                VStack(spacing: 10) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Processing medical terminology...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                        } else if !translatedText.isEmpty {
                            // Display the simplified text from the AI
                            Text(translatedText)
                                .padding()
                                .frame(minHeight: 100, alignment: .topLeading)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Recordings History View
    
    /// View for displaying the user's saved recordings
    var recordingsHistoryView: some View {
        Group {
            if savedRecordings.isEmpty {
                // Empty state when no recordings have been saved
                VStack(spacing: 20) {
                    Image(systemName: "waveform.circle")
                        .font(.system(size: 70))
                        .foregroundColor(.blue.opacity(0.7))
                        .padding(.bottom, 10)
                    
                    Text("No Saved Recordings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your saved transcriptions will appear here.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // List of saved recordings with swipe-to-delete functionality
                List {
                    ForEach(savedRecordings) { recording in
                        RecordingRow(recording: recording)
                    }
                    .onDelete(perform: deleteRecording)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    // MARK: - Permission Denied View
    
    /// View shown when microphone or speech recognition permissions are denied
    var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash.circle")
                .font(.system(size: 70))
                .foregroundColor(.red.opacity(0.8))
                .padding(.bottom, 10)
            
            Text("Microphone Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(permissionErrorMessage.isEmpty ? 
                 "DeepCure needs microphone and speech recognition permissions to transcribe medical conversations. Please enable these in your device settings." : 
                 permissionErrorMessage)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Button to take user directly to app settings
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    // MARK: - Speech Recognition Setup
    
    /// Configure the audio session and speech recognizer
    private func setupSpeech() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            // Configure audio session for recording and playback
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Initialize speech recognizer with US English locale
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            
            // Request speech recognition authorization
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        print("Speech recognition authorized")
                        // Ready to record - no action needed
                    case .denied:
                        print("Speech recognition authorization denied")
                        permissionDenied = true
                        permissionErrorMessage = "Speech recognition authorization denied. Please enable permissions in your device settings."
                    case .restricted, .notDetermined:
                        print("Speech recognition not authorized")
                        permissionDenied = true
                        permissionErrorMessage = "Speech recognition is restricted or not determined. Please check your device settings."
                    @unknown default:
                        print("Unknown authorization status")
                        permissionDenied = true
                        permissionErrorMessage = "Unknown authorization status. Please check your device settings."
                    }
                }
            }
        } catch {
            print("Failed to set up recording session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Recording Control
    
    /// Begin recording and transcribing speech
    private func startRecording() {
        // Verify speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer is not available")
            // Could show an alert to the user
            return
        }
        
        isRecording = true
        recordingDuration = 0
        
        // Start timer for updating duration and visualization
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1
            animateVisualization()
        }
        
        do {
            // Configure audio session specifically for recording
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Create recognition request to process audio buffers
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else {
                print("Unable to create recognition request")
                isRecording = false
                return
            }
            
            // Enable partial results for real-time transcription
            recognitionRequest.shouldReportPartialResults = true
            
            // Start recognition task
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                
                if let result = result {
                    // Update UI with latest transcription
                    self.transcribedText = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }
                
                // Handle recognition errors
                if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    self.isRecording = false
                    return
                }
                
                // Clean up when recognition is complete
                if isFinal {
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
            }
            
            // Install tap on the audio input to begin capturing audio
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            // Prepare and start the audio engine
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Recording failed: \(error.localizedDescription)")
            isRecording = false
            recordingTimer?.invalidate()
            recordingTimer = nil
            // Could show an alert to the user
        }
    }
    
    /// Create animated visualization bars to indicate recording activity
    private func animateVisualization() {
        // Animate visualization bars with randomized heights to simulate audio waveform
        for i in 0..<recordingVisualization.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                self.recordingVisualization[i] = CGFloat.random(in: 5...50)
            }
        }
    }
    
    /// Stop recording and transcribing
    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingVisualization = Array(repeating: 0, count: 30)
        
        // Stop audio processing
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
    
    // MARK: - Data Management
    
    /// Save the current transcription to the user's collection
    private func saveRecording() {
        // Create a new recording object with current data
        let newRecording = Recording(
            id: UUID(),
            title: recordingTitle,
            date: Date(),
            duration: recordingDuration,
            transcription: transcribedText,
            simplifiedText: translatedText
        )
        
        // Add to local collection
        savedRecordings.append(newRecording)
        
        // Reset the title field
        recordingTitle = ""
        
        // In a real app, this would also save to Firebase or another persistent storage
    }
    
    /// Process medical text through AI for simplification
    private func translateMedicalJargon() {
        processingTranslation = true
        
        // Call GPT service to simplify the text
        GPTService.shared.simplifyMedicalText(transcribedText) { result in
            DispatchQueue.main.async {
                self.processingTranslation = false
                
                switch result {
                case .success(let simplifiedText):
                    self.translatedText = simplifiedText
                case .failure(let error):
                    self.translatedText = "Sorry, I couldn't simplify the text. Error: \(error.localizedDescription)"
                    print("Translation error: \(error)")
                }
            }
        }
    }
    
    /// Format seconds into MM:SS string format
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    /// Remove recordings from the collection
    private func deleteRecording(at offsets: IndexSet) {
        savedRecordings.remove(atOffsets: offsets)
        // In a real app, this would also delete from Firebase
    }
    
    /// Load any existing recordings (placeholder for future database integration)
    private func loadSampleRecordings() {
        // No preloaded recordings - history will only show user's actual saved recordings
        // In a real app, this would load from Firebase or local storage
    }
}

// MARK: - Supporting Models and Views

/// Model representing a saved recording
struct Recording: Identifiable {
    /// Unique identifier
    let id: UUID
    
    /// User-assigned title
    let title: String
    
    /// When the recording was made
    let date: Date
    
    /// Recording length in seconds
    let duration: Int
    
    /// Original transcribed text
    let transcription: String
    
    /// AI-simplified version of the text (if available)
    let simplifiedText: String
}

/// Custom view that displays text with highlighted medical terms
struct TranscriptionTextView: View {
    /// The text to display
    let text: String
    
    /// Medical terms to highlight within the text
    let highlightTerms: [String]
    
    var body: some View {
        Text(attributedString)
    }
    
    /// Create attributed string with highlighted medical terms
    var attributedString: AttributedString {
        var attributedString = AttributedString(text)
        
        // Search for each medical term in the text
        for term in highlightTerms {
            let pattern = "\\b\(term)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let nsrange = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: nsrange)
                
                // Apply blue color and bold styling to each match
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let stringRange = AttributedString(text).range(of: text[range])
                        
                        if let stringRange = stringRange {
                            attributedString[stringRange].foregroundColor = .blue
                            attributedString[stringRange].font = .system(.body, design: .default).bold()
                        }
                    }
                }
            }
        }
        
        return attributedString
    }
}

/// Custom view for displaying a saved recording in the history list
struct RecordingRow: View {
    /// The recording to display
    let recording: Recording
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recording.title)
                    .font(.headline)
                
                Spacer()
                
                // Duration badge
                Text(timeString(from: recording.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Date indicator
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(dateString(from: recording.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Preview of transcription text
            Text(recording.transcription)
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
    
    /// Format seconds into MM:SS string format
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    /// Format date into human-readable string
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview Provider
#Preview {
    NavigationView {
        MedicalTranscriptionView()
    }
}