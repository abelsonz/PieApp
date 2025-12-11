import Foundation
import UIKit
import Combine

class ReceiptParser: ObservableObject {
    
    // MARK: - Secure API Key Access
    // This reads the key from the Info.plist, which gets it from Secrets.xcconfig
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GeminiAPIKey") as? String else {
            return ""
        }
        return key
    }
    
    @Published var isParsing = false
    @Published var parsedItems: [BillItem] = []
    @Published var detectedTax: Double = 0.00
    @Published var errorMessage: String? = nil
    
    func scanImage(_ image: UIImage) {
        // 1. Validation
        if apiKey.isEmpty || apiKey.contains("AIza") == false { // Simple check for likely invalid key
            DispatchQueue.main.async {
                self.errorMessage = "The scanner isn't configured correctly. Please check your API Key setup."
                self.isParsing = false
            }
            return
        }
        
        // 2. Prepare Image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            DispatchQueue.main.async { self.errorMessage = "We couldn't process that image. Please try again." }
            return
        }
        let base64Image = imageData.base64EncodedString()
        
        DispatchQueue.main.async {
            self.isParsing = true
            self.errorMessage = nil
            self.parsedItems = []
        }
        
        // 3. The URL
        let modelName = "gemini-robotics-er-1.5-preview"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        // 4. The Prompt (Updated for User Friendliness)
        // We now ask it to explicitly flag non-receipts using "isReceipt": false
        let promptText = """
        Analyze this image.
        If it IS a receipt, return JSON: { "items": [{"name": "Item Name", "price": 0.00}], "tax": 0.00 }.
        If it is NOT a receipt (e.g. a selfie, a cat, a landscape), return JSON: { "isReceipt": false }.
        """
        
        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": promptText],
                    [
                        "inline_data": [
                            "mime_type": "image/jpeg",
                            "data": base64Image
                        ]
                    ]
                ]
            ]]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // 5. Execute
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isParsing = false
                
                if let _ = error {
                    self.errorMessage = "We're having trouble connecting. Please check your internet."
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "The scanner didn't respond. Please try again."
                    return
                }
                
                self.parseGeminiResponse(data)
            }
        }.resume()
    }
    
    private func parseGeminiResponse(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // Check for API Errors (e.g. Quota limits)
                if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
                    print("❌ Gemini Error: \(message)")
                    self.errorMessage = "Debug Error: \(message)"
                    return
                }
                
                // Navigate the JSON structure
                if let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    
                    // Clean Markdown if present
                    let cleanJson = text.replacingOccurrences(of: "```json", with: "")
                                        .replacingOccurrences(of: "```", with: "")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard let jsonData = cleanJson.data(using: .utf8) else {
                        self.errorMessage = "We couldn't read the data from this receipt. Please retake the photo."
                        return
                    }
                    
                    // 1. Check if it's a valid receipt
                    if let result = try? JSONDecoder().decode(GeminiResponse.self, from: jsonData) {
                        self.parsedItems = result.items.map { BillItem(name: $0.name, price: $0.price) }
                        self.detectedTax = result.tax
                        
                        if self.parsedItems.isEmpty {
                            self.errorMessage = "We couldn't find any items on this receipt. Try moving closer."
                        }
                        return
                    }
                    
                    // 2. Check if AI explicitly rejected it
                    if let rejection = try? JSONDecoder().decode(GeminiRejection.self, from: jsonData), rejection.isReceipt == false {
                        self.errorMessage = "That doesn't look like a receipt. Please ensure the receipt is clearly visible."
                        return
                    }
                    
                    // 3. Fallback
                    self.errorMessage = "We couldn't understand this image. Please make sure the receipt is flat and well-lit."
                    
                } else {
                    self.errorMessage = "We couldn't find a receipt in this image. Please try again."
                }
            }
        } catch {
            print("❌ Parsing Error: \(error)")
            self.errorMessage = "Something went wrong reading the receipt. Please try again."
        }
    }
}

// Helpers
struct GeminiResponse: Codable {
    let items: [GeminiItem]
    let tax: Double
}

struct GeminiItem: Codable {
    let name: String
    let price: Double
}

// New helper for explicit rejections
struct GeminiRejection: Codable {
    let isReceipt: Bool
}
