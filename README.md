# 🩺 DeepCure

![image](https://github.com/user-attachments/assets/decce3bd-eabf-43b1-be57-7336be0c2f4b)


DeepCure is a state-of-the-art healthcare management application built for iOS that leverages Apple HealthKit integration, AI-powered medical assistance, and advanced health tracking capabilities to provide users with a complete solution for managing their medical information and health data.

> **Note:** DeepCure is developed with a focus on data privacy, user-friendly interface, and providing actionable health insights.

## ✨ Features

### 🏠 Home Dashboard
- **Real-time health metrics visualization** with trend analysis
- **Activity and appointment tracking** with calendar integration
- **Personalized health insights** based on your unique health profile
- **Quick access to all app features** through an intuitive interface
- **Health status summaries** with daily, weekly, and monthly views

### 🎙️ Medical Transcription
- **Voice recording of medical conversations** with noise reduction
- **Real-time speech-to-text transcription** with medical terminology recognition
- **Medical jargon simplification** powered by advanced AI algorithms
- **Save, organize, and search** medical conversations by date, provider, or topic
- **Highlight important terms** for quick reference during review

### 📋 Medical Records
- **Store and organize medical records** by category, date, or provider
- **Track hospital visits, lab results, and prescriptions** in one secure location
- **Advanced filter and search functionality** to quickly find specific records
- **Attach documents and images** to records for comprehensive documentation
- **Timeline view** to visualize your medical history chronologically

### 🔄 QR Health Profile
- **Generate secure QR codes** containing vital health information
- **Share emergency health details** with medical providers instantly
- **Optional encryption** for enhanced privacy with customizable access control
- **Selective data sharing** - choose exactly what information to include
- **Automatic expiry dates** for temporary access to your information

### 🧠 AI Medical Guidance
- **AI-powered medical assistant** for answering health questions and concerns
- **Multiple specialized AI assistants** (General Medical, Medication Help, Nutrition, etc.)
- **Conversation history** with previous consultations for consistent care
- **Clear disclaimers and ethical AI usage** with transparent source citations
- **Medication interaction checking** to prevent adverse reactions

### 🔗 Apple HealthKit Integration
- **Seamless integration** with Apple Health for consolidated health data
- **Automatic health data synchronization** with real-time updates
- **Comprehensive monitoring** of vital signs (heart rate, blood pressure, etc.)
- **Activity and sleep analysis** with personalized recommendations
- **Medication adherence tracking** with customizable reminders

## 🛠️ Tech Stack

### Core Technologies
- **Swift 5 & SwiftUI**: Modern UI development with Apple's latest frameworks
- **HealthKit**: Deep integration with Apple's comprehensive health data framework
- **Speech Recognition**: Native iOS speech-to-text capabilities with medical focus
- **Core Image**: QR code generation and processing with encryption support
- **Combine**: Reactive programming for efficient data flow management and UI updates

### Backend & Services
- **Firebase**: Authentication, Firestore database, and cloud storage for secure data management
- **Google Sign-in**: OAuth authentication option for simplified user onboarding
- **OpenAI API**: GPT integration for medical text simplification and AI guidance with context awareness
- **FHIR Standard**: Support for healthcare interoperability standards

### Key Architectural Components
- **MVVM Architecture**: Clear separation of view, model, and view model components
- **ObservableObject Pattern**: Reactive data binding for real-time UI updates
- **Singleton Services**: Shared service instances for consistent data access
- **Dependency Injection**: Flexible and testable component design

## 📱 Screenshots

![image](https://github.com/user-attachments/assets/2d7fede3-9279-40fa-8c3a-5fbd2386d552)

![image](https://github.com/user-attachments/assets/be1d71b5-ed8d-4749-ad11-c43e67a11582)

![image](https://github.com/user-attachments/assets/66a880a1-786b-45c4-825d-0c4447053ee0)

![image](https://github.com/user-attachments/assets/213cfc1c-3b08-4cd9-b239-04ea5202b938)




## 📂 Project Structure

```
DeepCure/
├── DeepCureApp.swift            # Main app entry point
├── ContentView.swift            # Root view with tab navigation
├── AIGuidanceView.swift         # AI medical guidance interface
├── MedicalRecordsView.swift     # Medical records management
├── MedicalTranscriptionView.swift # Voice recording and transcription
├── QRHealthProfileView.swift    # Health profile QR generation
├── Models/
│   ├── APIConfig.swift          # API configuration
│   ├── AppointmentModel.swift   # Appointment data model
│   ├── DeepCureViewModel.swift  # Main view model
│   ├── GPTService.swift         # OpenAI integration service
│   ├── HealthKitManager.swift   # Apple HealthKit integration
│   └── UserModel.swift          # User data model
└── Assets.xcassets/             # App images and resources
```

## 🩺 Health Data Integration

DeepCure connects with HealthKit to access and monitor:

| Category | Data Points |
|----------|-------------|
| **Cardiovascular** | Heart rate, Heart rate variability, Blood pressure, Blood oxygen |
| **Activity** | Step count, Distance walked/run, Calories burned, Exercise minutes |
| **Sleep** | Sleep duration, Sleep stages, Sleep quality, Sleep trends |
| **Body Measurements** | Weight, Height, BMI, Body fat percentage |
| **Vitals** | Respiratory rate, Body temperature, Blood glucose levels |
| **Nutrition** | Water intake, Nutrition logging, Calorie tracking |

## 🚀 Getting Started

### Prerequisites
- iOS 18.2+ device or simulator
- Xcode 16.2+
- Apple Developer account for HealthKit capabilities
- Firebase project setup (for authentication and data storage)
- OpenAI API key for AI medical guidance features

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/DeepCure.git
   cd DeepCure
   ```

2. **Set up Firebase**
   - Create a Firebase project at [firebase.google.com](https://firebase.google.com)
   - Add iOS app to your Firebase project
   - Download `GoogleService-Info.plist` and add to the project
   - Enable Authentication, Firestore, and Storage services

3. **Configure API Keys**
   - Add your OpenAI API key in `Models/APIConfig.swift`

4. **Enable HealthKit**
   - In Xcode, go to your target's Signing & Capabilities tab
   - Add the HealthKit capability
   - Configure `Info.plist` with appropriate usage descriptions

5. **Build and Run**
   - Open `DeepCure.xcodeproj` in Xcode
   - Select your target device or simulator
   - Press Run (⌘R)

## 🔒 Privacy and Security

DeepCure prioritizes user privacy and data security with:

- **Local health data processing** whenever possible
- **End-to-end encryption** for sensitive medical information
- **Encrypted health profile QR codes** with access controls
- **Optional medical history storage** with user control
- **HIPAA-compliant design principles** throughout the application
- **Transparent data usage policies** with clear opt-in mechanisms
- **Automatic data purging** options for sensitive information

## 👥 Use Cases

- **Patients**: Track health metrics, store medical records, and get AI-assisted medical information
- **Medical Professionals**: Quick access to patient health information via QR codes
- **Caregivers**: Monitor health status of family members with permission-based access
- **Chronic Condition Management**: Track patterns in health data for better disease management
- **Emergency Situations**: Provide critical health information to first responders

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

DeepCure is designed to assist with medical information management but is not a substitute for professional medical advice, diagnosis, or treatment. Always consult qualified healthcare providers for medical decisions.

---

<div align="center">
  <p>
    Made with ❤️ by the DeepCure Team
  </p>
  <p>
    © 2025 DeepCure. All rights reserved.
  </p>
</div>
