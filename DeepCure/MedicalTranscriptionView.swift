//
//  MedicalTranscriptionView.swift
//  DeepCure
//
//  Created by Yaakulya Sabbani on 12/04/2025.
//

import SwiftUI
import AVFoundation
import Speech

struct MedicalTranscriptionView: View {
    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var recordingSession: AVAudioSession?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var speechRecognizer: SFSpeechRecognizer?
    @State private var audioEngine = AVAudioEngine()
    @State private var showingSaveDialog = false
    @State private var recordingTitle = ""
    @State private var processingTranslation = false
    @State private var translatedText = ""
    @State private var recordingDuration = 0
    @State private var recordingTimer: Timer?
    @State private var recordingVisualization: [CGFloat] = Array(repeating: 0, count: 30)
    @State private var selectedTab = 0
    @State private var savedRecordings: [Recording] = []
    @State private var permissionDenied = false
    @State private var permissionErrorMessage = ""
    
    // Sample medical terms for demonstration
    let medicalTerms = ["hypertension", "myocardial infarction", "atherosclerosis", "hypercholesterolemia"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View Mode", selection: $selectedTab) {
                Text("Record").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
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
    var recordingView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Recording visualization and control
                ZStack {
                    // Background card
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isRecording ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(height: 160)
                    
                    VStack(spacing: 16) {
                        // Audio visualization
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
                            Image(systemName: "waveform")
                                .font(.system(size: 40))
                                .foregroundColor(Color.gray.opacity(0.7))
                        }
                        
                        HStack(spacing: 20) {
                            // Record/Stop button
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
                            
                            // Recording status and timer
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
                
                // Transcription section with improved UI
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Transcription")
                            .font(.headline)
                        
                        Spacer()
                        
                        if !transcribedText.isEmpty {
                            Menu {
                                Button(action: {
                                    // Copy to clipboard
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
                        // Empty state
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
                        // Show transcribed text with highlighted medical terms
                        TranscriptionTextView(
                            text: transcribedText, 
                            highlightTerms: medicalTerms
                        )
                        .frame(minHeight: 150)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Bottom action buttons
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
                
                // Translation results section
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
    var recordingsHistoryView: some View {
        Group {
            if savedRecordings.isEmpty {
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
    
    // Permission denied view
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
    
    // Set up speech recognition
    private func setupSpeech() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(true, options: .notifyOthersOnDeactivation)
            
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            
            // Handle authorization status
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        print("Speech recognition authorized")
                        // Ready to record
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
    
    // Start recording and transcribing
    private func startRecording() {
        // Check speech recognizer availability
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer is not available")
            // Could show an alert to the user
            return
        }
        
        isRecording = true
        recordingDuration = 0
        
        // Generate visualization with animation
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1
            animateVisualization()
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            guard let recognitionRequest = recognitionRequest else {
                print("Unable to create recognition request")
                isRecording = false
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            // Start recognition task
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    isFinal = result.isFinal
                }
                
                if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    self.isRecording = false
                    return
                }
                
                if isFinal {
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
            }
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
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
    
    private func animateVisualization() {
        // Animate visualization bars randomly when recording
        for i in 0..<recordingVisualization.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                self.recordingVisualization[i] = CGFloat.random(in: 5...50)
            }
        }
    }
    
    // Stop recording
    private func stopRecording() {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingVisualization = Array(repeating: 0, count: 30)
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
    
    // Save the recording to Firebase (placeholder for now)
    private func saveRecording() {
        let newRecording = Recording(
            id: UUID(),
            title: recordingTitle,
            date: Date(),
            duration: recordingDuration,
            transcription: transcribedText,
            simplifiedText: translatedText
        )
        
        savedRecordings.append(newRecording)
        
        // Reset the title field
        recordingTitle = ""
        
        // In a real app, save to Firebase here
    }
    
    // Translate medical jargon (placeholder for GPT API integration)
    private func translateMedicalJargon() {
        processingTranslation = true
        
        // Simulate API call with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // This is where we would call the GPT API in a real implementation
            translatedText = "This patient appears to have high blood pressure (hypertension) and high cholesterol (hypercholesterolemia). These conditions can increase the risk of heart attack (myocardial infarction) and hardening of the arteries (atherosclerosis). Recommended lifestyle changes include a low-sodium, low-fat diet, regular exercise, and medication adherence."
            processingTranslation = false
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func deleteRecording(at offsets: IndexSet) {
        savedRecordings.remove(atOffsets: offsets)
        // In a real app, delete from Firebase here
    }
    
    // For demo purposes
    private func loadSampleRecordings() {
        if savedRecordings.isEmpty {
            savedRecordings = [
                Recording(
                    id: UUID(),
                    title: "Annual Checkup Notes",
                    date: Date().addingTimeInterval(-3 * 24 * 3600),
                    duration: 355,
                    transcription: "Patient presents with elevated blood pressure of 145/92. Pulse 72 bpm. Patient reports occasional chest discomfort after physical exertion. Recommend follow-up with cardiologist for further evaluation.",
                    simplifiedText: "Blood pressure is high at 145/92 (normal is below 120/80). Heart rate is normal at 72 beats per minute. Patient feels chest discomfort sometimes after exercise. Needs to see a heart doctor for more tests."
                ),
                Recording(
                    id: UUID(),
                    title: "Medication Review",
                    date: Date().addingTimeInterval(-1 * 24 * 3600),
                    duration: 245,
                    transcription: "Patient is currently taking Lisinopril 10mg once daily for hypertension and Atorvastatin 40mg nightly for hypercholesterolemia. Reports good medication adherence with no side effects.",
                    simplifiedText: "Patient takes Lisinopril 10mg once a day for high blood pressure and Atorvastatin 40mg at night for high cholesterol. They're taking their medicines as prescribed and don't have any side effects."
                )
            ]
        }
    }
}

// Recording model
struct Recording: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let duration: Int
    let transcription: String
    let simplifiedText: String
}

// Transcription text view with term highlighting
struct TranscriptionTextView: View {
    let text: String
    let highlightTerms: [String]
    
    var body: some View {
        Text(attributedString)
    }
    
    var attributedString: AttributedString {
        var attributedString = AttributedString(text)
        
        for term in highlightTerms {
            let pattern = "\\b\(term)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let nsrange = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, options: [], range: nsrange)
                
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

// Row for displaying a saved recording
struct RecordingRow: View {
    let recording: Recording
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recording.title)
                    .font(.headline)
                
                Spacer()
                
                Text(timeString(from: recording.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(dateString(from: recording.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(recording.transcription)
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        MedicalTranscriptionView()
    }
}