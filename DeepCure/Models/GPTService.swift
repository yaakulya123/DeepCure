import Foundation

/// `GPTService` handles all interactions with OpenAI's API for AI-powered features
/// including medical text simplification and personalized health guidance.
/// This service uses OpenAI's GPT models to process medical language.
class GPTService {
    /// Use a more affordable and efficient model version
    /// gpt-4o-mini offers good performance with lower latency and cost
    private let apiModel = "gpt-4o-mini"
    
    /// OpenAI API key for authentication
    /// This is retrieved from APIConfig to avoid hardcoding secrets
    /// SECURITY WARNING: In a production environment, this key should be stored securely
    /// using a service like AWS Secrets Manager, Azure Key Vault, or similar
    private let apiKey = APIConfig.openAIAPIKey
    
    /// OpenAI API endpoint for chat completions
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    /// Singleton instance for app-wide access
    /// This ensures we maintain a single point of access to the GPT service
    static let shared = GPTService()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Medical Transcription Simplification
    
    /// Simplifies complex medical terminology into patient-friendly language
    /// This function takes medical text, such as doctor's notes or medical reports,
    /// and translates it into simpler language that patients can understand
    ///
    /// - Parameters:
    ///   - text: The medical text to be simplified
    ///   - completion: A closure that receives the simplified text or an error
    func simplifyMedicalText(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
        The following is a medical transcription. Please translate it into simple, patient-friendly language:
        
        \(text)
        
        Please explain medical terms in plain English and organize the information in a clear format.
        """
        
        sendRequest(
            messages: [
                ["role": "system", "content": "You are a medical assistant that specializes in explaining complex medical information in simple terms that patients can understand."],
                ["role": "user", "content": prompt]
            ],
            completion: completion
        )
    }
    
    // MARK: - AI Medical Guidance
    
    /// Provides AI-powered medical guidance based on user queries
    /// Different assistant types provide specialized knowledge in various health domains
    ///
    /// - Parameters:
    ///   - query: The user's health-related question
    ///   - assistantType: The type of medical assistant to use (General Medical, Medication, etc.)
    ///   - completion: A closure that receives the AI response or an error
    func getAIMedicalGuidance(query: String, assistantType: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Select the appropriate system prompt based on the assistant type
        // Each assistant type has specialized knowledge and boundaries
        let systemPrompt: String
        
        switch assistantType {
        case "General Medical":
            systemPrompt = "You are a general medical information assistant. Provide helpful, accurate health information while clearly stating limitations and encouraging professional medical consultation when appropriate."
            
        case "Medication":
            systemPrompt = "You are a medication information assistant. Provide general information about medications, potential side effects, and usage guidelines, while emphasizing the importance of following doctor and pharmacist instructions."
            
        case "Nutrition":
            systemPrompt = "You are a nutrition information assistant. Provide evidence-based dietary advice and nutritional information, while acknowledging individual needs vary."
            
        case "Mental Health":
            systemPrompt = "You are a mental health information assistant. Provide supportive, evidence-based information about mental health topics while encouraging professional help when needed."
            
        case "Chronic Care":
            systemPrompt = "You are a chronic care information assistant. Provide information to help people understand and manage chronic conditions, while emphasizing the importance of regular medical care."
            
        default:
            systemPrompt = "You are a medical information assistant. Provide helpful, accurate health information while clearly stating limitations and encouraging professional medical consultation."
        }
        
        // Construct the messages array with system instructions and the user's query
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "system", "content": "Always provide a disclaimer that your information is not a substitute for professional medical advice. Keep responses concise and helpful."],
            ["role": "user", "content": query]
        ]
        
        sendRequest(messages: messages, completion: completion)
    }
    
    // MARK: - Generic API Request Method
    
    /// Sends a request to the OpenAI API with the specified messages
    /// This is a generic method used by all GPT-based features in the app
    ///
    /// - Parameters:
    ///   - messages: An array of message objects with role (system/user/assistant) and content
    ///   - completion: A closure that receives the API response or an error
    private func sendRequest(messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        // Create and validate the API URL
        guard let url = URL(string: endpoint) else {
            completion(.failure(GPTError.invalidURL))
            return
        }
        
        // Set up HTTP request with appropriate headers
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare the request body with model settings and messages
        let requestBody: [String: Any] = [
            "model": apiModel,
            "messages": messages,
            "temperature": 0.7,         // Controls randomness (0.0-2.0), 0.7 offers a good balance
            "max_tokens": 1000          // Limits response length to control costs and response time
        ]
        
        // Serialize the request body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Execute the API request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Handle network errors
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // Ensure we received data
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(GPTError.noData))
                }
                return
            }
            
            // Parse the response JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    // Process successful response on main thread
                    DispatchQueue.main.async {
                        // Clean up any markdown formatting from the response
                        let cleanedContent = self.removeMarkdownFormatting(content)
                        completion(.success(cleanedContent))
                    }
                } else {
                    // Try to extract error details from the response
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        DispatchQueue.main.async {
                            completion(.failure(GPTError.apiError(message)))
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(.failure(GPTError.parsingError))
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    // MARK: - Helper Methods
    
    /// Removes markdown formatting characters from the API response
    /// This helps ensure the text appears clean in the UI
    ///
    /// - Parameter text: The text containing markdown formatting
    /// - Returns: Cleaned text with markdown formatting removed
    private func removeMarkdownFormatting(_ text: String) -> String {
        // Remove bold/italic markdown formatting
        // A more comprehensive implementation would handle more markdown elements
        return text.replacingOccurrences(of: "\\*\\*|\\*", with: "", options: .regularExpression)
    }
}

// MARK: - Custom Errors

/// Custom error types for GPT API interactions
/// These provide more specific error information than generic Error types
enum GPTError: Error, LocalizedError {
    /// The API URL is invalid
    case invalidURL
    
    /// No data was received from the API
    case noData
    
    /// The API response couldn't be parsed as expected
    case parsingError
    
    /// The API returned an error message
    case apiError(String)
    
    /// Human-readable error descriptions for UI presentation
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .noData:
            return "No data received from API"
        case .parsingError:
            return "Failed to parse API response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}