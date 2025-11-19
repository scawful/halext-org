//
//  ShareViewController.swift
//  CafeShareExtension
//
//  Share Extension for creating tasks from shared content
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    // UI Elements
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let taskTitleField = UITextField()
    private let descriptionTextView = UITextView()
    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // Shared data
    private var sharedURL: URL?
    private var sharedText: String?
    private var sharedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        extractSharedContent()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // Container
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Title
        titleLabel.text = "Add to Cafe"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Task title field
        taskTitleField.placeholder = "Task title"
        taskTitleField.borderStyle = .roundedRect
        taskTitleField.font = .systemFont(ofSize: 16)
        taskTitleField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(taskTitleField)

        // Description text view
        descriptionTextView.layer.borderColor = UIColor.separator.cgColor
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.font = .systemFont(ofSize: 14)
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionTextView)

        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)

        // Create button
        createButton.setTitle("Create Task", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = .systemBlue
        createButton.layer.cornerRadius = 8
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(createButton)

        // Activity indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicator)

        // Layout
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),

            taskTitleField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            taskTitleField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            taskTitleField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            taskTitleField.heightAnchor.constraint(equalToConstant: 44),

            descriptionTextView.topAnchor.constraint(equalTo: taskTitleField.bottomAnchor, constant: 12),
            descriptionTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 120),

            cancelButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 100),

            createButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            createButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            createButton.widthAnchor.constraint(equalToConstant: 120),
            createButton.heightAnchor.constraint(equalToConstant: 44),

            activityIndicator.centerXAnchor.constraint(equalTo: createButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: createButton.centerYAnchor)
        ])
    }

    // MARK: - Extract Shared Content

    private func extractSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            return
        }

        // Check for URL
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                if let url = item as? URL {
                    self?.sharedURL = url
                    DispatchQueue.main.async {
                        self?.populateFields()
                    }
                }
            }
        }
        // Check for text
        else if itemProvider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
                if let text = item as? String {
                    self?.sharedText = text
                    DispatchQueue.main.async {
                        self?.populateFields()
                    }
                }
            }
        }
        // Check for image
        else if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
                if let url = item as? URL,
                   let imageData = try? Data(contentsOf: url),
                   let image = UIImage(data: imageData) {
                    self?.sharedImage = image
                    DispatchQueue.main.async {
                        self?.populateFields()
                    }
                }
            }
        }
    }

    private func populateFields() {
        if let url = sharedURL {
            taskTitleField.text = url.host ?? "Link"
            descriptionTextView.text = url.absoluteString
        } else if let text = sharedText {
            // Use first line as title, rest as description
            let lines = text.components(separatedBy: .newlines)
            if let firstLine = lines.first {
                taskTitleField.text = String(firstLine.prefix(100))
                if lines.count > 1 {
                    descriptionTextView.text = lines.dropFirst().joined(separator: "\n")
                }
            }
        } else if sharedImage != nil {
            taskTitleField.text = "Image Task"
            descriptionTextView.text = "Task created from shared image"
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "CafeShareExtension", code: 0))
    }

    @objc private func createTapped() {
        guard let title = taskTitleField.text, !title.isEmpty else {
            showError("Please enter a task title")
            return
        }

        activityIndicator.startAnimating()
        createButton.setTitle("", for: .normal)
        createButton.isEnabled = false

        // Create task data
        let taskData: [String: Any] = [
            "title": title,
            "description": descriptionTextView.text ?? "",
            "url": sharedURL?.absoluteString ?? "",
            "timestamp": Date().timeIntervalSince1970
        ]

        // Save to shared container
        saveToSharedContainer(taskData)

        // Send to main app via URL scheme
        openMainApp(with: taskData)
    }

    private func saveToSharedContainer(_ taskData: [String: Any]) {
        guard let sharedDefaults = UserDefaults(suiteName: "group.org.halext.cafe") else {
            return
        }

        var pendingTasks = sharedDefaults.array(forKey: "pendingSharedTasks") as? [[String: Any]] ?? []
        pendingTasks.append(taskData)
        sharedDefaults.set(pendingTasks, forKey: "pendingSharedTasks")
        sharedDefaults.synchronize()

        print("📱 Saved task to shared container")
    }

    private func openMainApp(with taskData: [String: Any]) {
        // Encode task data for URL
        if let jsonData = try? JSONSerialization.data(withJSONObject: taskData),
           let base64 = jsonData.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "cafe://share?data=\(base64)") {

            // Open main app
            var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.perform(#selector(openURL(_:)), with: url)
                    break
                }
                responder = responder?.next
            }
        }

        // Complete the extension
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    @objc private func openURL(_ url: URL) {
        // This is called via perform selector
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
