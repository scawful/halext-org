//
//  DocumentScannerManager.swift
//  Cafe
//
//  Document scanning and OCR with Vision framework
//

import SwiftUI
import VisionKit
import Vision

@MainActor
@Observable
class DocumentScannerManager {
    static let shared = DocumentScannerManager()

    var scannedImages: [UIImage] = []
    var recognizedText = ""
    var isProcessing = false
    var errorMessage: String?

    private init() {}

    // MARK: - Document Scanner

    var isDocumentScannerAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    func scanDocument() {
        scannedImages = []
        recognizedText = ""
    }

    // MARK: - Text Recognition (OCR)

    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ScannerError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: ScannerError.recognitionFailed)
                    return
                }

                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func recognizeTextFromMultipleImages(_ images: [UIImage]) async throws -> String {
        var allText: [String] = []

        for image in images {
            let text = try await recognizeText(from: image)
            if !text.isEmpty {
                allText.append(text)
            }
        }

        return allText.joined(separator: "\n\n---\n\n")
    }

    // MARK: - Barcode/QR Code Detection

    func detectBarcodes(in image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw ScannerError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let codes = observations.compactMap { $0.payloadStringValue }
                continuation.resume(returning: codes)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Document Detection

    func detectDocumentRectangle(in image: UIImage) async throws -> VNRectangleObservation? {
        guard let cgImage = image.cgImage else {
            throw ScannerError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectDocumentSegmentationRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observation = request.results?.first else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: observation as? VNRectangleObservation)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Scanner Errors

enum ScannerError: LocalizedError {
    case invalidImage
    case recognitionFailed
    case scannerNotAvailable

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .recognitionFailed:
            return "Text recognition failed"
        case .scannerNotAvailable:
            return "Document scanner not available on this device"
        }
    }
}

// MARK: - Document Scanner View

struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onComplete: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                         didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []

            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                images.append(image)
            }

            parent.onComplete(images)
            parent.isPresented = false
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                         didFailWithError error: Error) {
            print("Document scanner error: \(error)")
            parent.isPresented = false
        }
    }
}

// MARK: - Document Scanner Button

struct DocumentScannerButton: View {
    @State private var isShowingScanner = false
    @State private var isProcessing = false
    @State private var scannerManager = DocumentScannerManager.shared
    let onTextRecognized: (String) -> Void

    var body: some View {
        Button(action: {
            if scannerManager.isDocumentScannerAvailable {
                isShowingScanner = true
            }
        }) {
            Label("Scan Document", systemImage: "doc.text.viewfinder")
        }
        .disabled(!scannerManager.isDocumentScannerAvailable || isProcessing)
        .sheet(isPresented: $isShowingScanner) {
            DocumentScannerView(isPresented: $isShowingScanner) { images in
                processScannedImages(images)
            }
        }
    }

    private func processScannedImages(_ images: [UIImage]) {
        isProcessing = true
        scannerManager.scannedImages = images

        _Concurrency.Task {
            do {
                let text = try await scannerManager.recognizeTextFromMultipleImages(images)
                scannerManager.recognizedText = text
                onTextRecognized(text)
            } catch {
                scannerManager.errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }
}

// MARK: - Scanned Document View

struct ScannedDocumentView: View {
    let images: [UIImage]
    let recognizedText: String
    let onDismiss: () -> Void
    let onUseText: () -> Void

    @State private var selectedImageIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image viewer
                TabView(selection: $selectedImageIndex) {
                    ForEach(images.indices, id: \.self) { index in
                        Image(uiImage: images[index])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 300)

                if images.count > 1 {
                    Text("Page \(selectedImageIndex + 1) of \(images.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }

                Divider()

                // Recognized text
                ScrollView {
                    Text(recognizedText.isEmpty ? "Processing..." : recognizedText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Scanned Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Text", action: onUseText)
                        .disabled(recognizedText.isEmpty)
                }
            }
        }
    }
}

// MARK: - QR Code Scanner Button

struct QRCodeScannerButton: View {
    @State private var isShowingScanner = false
    @State private var isProcessing = false
    let onCodeDetected: (String) -> Void

    var body: some View {
        Button(action: { isShowingScanner = true }) {
            Label("Scan QR Code", systemImage: "qrcode.viewfinder")
        }
        .sheet(isPresented: $isShowingScanner) {
            DocumentScannerView(isPresented: $isShowingScanner) { images in
                processScannedImages(images)
            }
        }
    }

    private func processScannedImages(_ images: [UIImage]) {
        guard let firstImage = images.first else { return }

        isProcessing = true

        _Concurrency.Task {
            do {
                let codes = try await DocumentScannerManager.shared.detectBarcodes(in: firstImage)
                if let code = codes.first {
                    onCodeDetected(code)
                }
            } catch {
                print("QR code detection error: \(error)")
            }
            isProcessing = false
        }
    }
}
