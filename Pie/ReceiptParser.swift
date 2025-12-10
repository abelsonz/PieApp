import Foundation
import UIKit
import Combine

class ReceiptParser: ObservableObject {
    // ⚠️ PASTE YOUR GEMINI API KEY HERE ⚠️
    private let apiKey = "AIzaSyDgMIs9XejLGh0PO-kdkUbb7j68cUujYE0"
    
    @Published var isParsing = false
    @Published var parsedItems: [BillItem] = []
    @Published var detectedTax: Double = 0.00
    @Published var errorMessage: String? = nil
    
    func scanImage(_ image: UIImage) {
        // 1. Validation
        if apiKey.contains("PASTE_YOUR") || apiKey.isEmpty {
            DispatchQueue.main.async {
                self.errorMessage = "Missing API Key in ReceiptParser.swift"
                self.isParsing = false
            }
            return
        }
        
        // 2. Prepare Image (Base64)
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            DispatchQueue.main.async { self.errorMessage = "Could not process image data." }
            return
        }
        let base64Image = imageData.base64EncodedString()
        
        DispatchQueue.main.async {
            self.isParsing = true
            self.errorMessage = nil
            self.parsedItems = []
        }
        
        // 3. The URL (UPDATED MODEL)
        // Switched to 'gemini-robotics-er-1.5-preview' per your request
        let modelName = "gemini-robotics-er-1.5-preview"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 4. The Prompt
        let promptText = """
        Analyze receipt. Return JSON: { "items": [{"name": "Item", "price": 0.00}], "tax": 0.00 }
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
                
                if let error = error {
                    self.errorMessage = "Network Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                self.parseGeminiResponse(data)
            }
        }.resume()
    }
    
    private func parseGeminiResponse(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // Check for API Errors
                if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
                    self.errorMessage = "Gemini Error: \(message)"
                    print("❌ Gemini Error: \(message)")
                    return
                }
                
                // Navigate the JSON structure
                if let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    
                    // Clean Markdown
                    let cleanJson = text.replacingOccurrences(of: "```json", with: "")
                                        .replacingOccurrences(of: "```", with: "")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let jsonData = cleanJson.data(using: .utf8) {
                        let result = try JSONDecoder().decode(GeminiResponse.self, from: jsonData)
                        self.parsedItems = result.items.map { BillItem(name: $0.name, price: $0.price) }
                        self.detectedTax = result.tax
                        print("✅ Success: Found \(self.parsedItems.count) items using model: gemini-robotics-er-1.5-preview")
                    } else {
                        self.errorMessage = "Could not parse response text."
                    }
                } else {
                    self.errorMessage = "Receipt not recognized."
                }
            }
        } catch {
            self.errorMessage = "Parsing Error: \(error.localizedDescription)"
            print("❌ Parsing Error: \(error)")
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
