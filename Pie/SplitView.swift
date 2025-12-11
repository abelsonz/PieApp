import SwiftUI
import PhotosUI

struct SplitView: View {
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isProcessing = false
    @State private var navigateToSlicing = false
    @State private var showError = false
    @State private var showTutorial = false // NEW STATE
    
    @StateObject private var parser = ReceiptParser()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pieCream.ignoresSafeArea()
                
                if isProcessing {
                    VStack(spacing: 25) {
                        ProgressView()
                            .scaleEffect(2.0)
                            .tint(.pieCrust)
                        Text("Reading Receipt...")
                            .pieFont(.headline)
                            .foregroundColor(.pieCoffee)
                    }
                } else {
                    VStack(spacing: 0) {
                        // MARK: - 1. Unified Header
                        HStack {
                            Text("Split")
                                .pieFont(.largeTitle, weight: .heavy)
                                .foregroundColor(.pieCoffee)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                        
                        Spacer()
                        
                        // MARK: - 2. Main Content
                        VStack(spacing: 40) {
                            
                            // Illustration & Text
                            VStack(spacing: 20) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 90))
                                    .foregroundColor(.pieCrust.opacity(0.5))
                                
                                VStack(spacing: 8) {
                                    Text("Ready to Split?")
                                        .pieFont(.title2, weight: .bold)
                                        .foregroundColor(.pieCoffee)
                                    
                                    Text("Snap a photo or upload a receipt.")
                                        .pieFont(.body)
                                        .foregroundColor(.pieCoffee)
                                        .opacity(0.6)
                                }
                            }
                            
                            // Buttons Row
                            VStack(spacing: 20) { // Wrapped in VStack to add Tutorial button below
                                HStack(spacing: 15) {
                                    Button(action: { showCamera = true }) {
                                        HStack {
                                            Image(systemName: "camera.fill")
                                            Text("Camera")
                                                .pieFont(.headline, weight: .bold)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(Color.pieCrust)
                                        .clipShape(Capsule())
                                        .shadow(color: Color.pieCrust.opacity(0.4), radius: 10, y: 6)
                                    }
                                    
                                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                        HStack {
                                            Image(systemName: "photo.on.rectangle")
                                            Text("Upload")
                                                .pieFont(.headline, weight: .bold)
                                    }
                                    .foregroundColor(.pieCoffee)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                                    }
                                    .onChange(of: selectedPhotoItem) { oldValue, newItem in
                                        processPhoto(newItem)
                                    }
                                }
                                
                                // NEW: Tutorial Button
                                Button(action: { showTutorial = true }) {
                                    Text("How it Works")
                                        .pieFont(.subheadline, weight: .semibold)
                                        .foregroundColor(.pieCoffee.opacity(0.5))
                                        .underline()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                        Spacer()
                    }
                    .padding(.bottom, 130)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    processUIImage(image)
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $navigateToSlicing) {
                SlicingView(initialItems: parser.parsedItems, initialTax: parser.detectedTax)
            }
            .alert("Oops!", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(parser.errorMessage ?? "Something went wrong.")
            }
            // NEW: Tutorial Sheet
            .sheet(isPresented: $showTutorial) {
                OnboardingView()
            }
        }
    }
    
    // Logic
    func processPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        isProcessing = true
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    processUIImage(uiImage)
                    selectedPhotoItem = nil
                }
            } else {
                DispatchQueue.main.async {
                    isProcessing = false
                    selectedPhotoItem = nil
                }
            }
        }
    }
    
    func processUIImage(_ image: UIImage) {
        isProcessing = true
        parser.scanImage(image)
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !parser.isParsing {
                timer.invalidate()
                isProcessing = false
                if let _ = parser.errorMessage {
                    showError = true
                } else if !parser.parsedItems.isEmpty {
                    navigateToSlicing = true
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (UIImage) -> Void
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImagePicked(image) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}
