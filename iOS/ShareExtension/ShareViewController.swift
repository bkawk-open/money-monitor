import UIKit
import SwiftData
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            close()
            return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.pdf.identifier) { [weak self] item, error in
                    guard let url = item as? URL else {
                        self?.close()
                        return
                    }
                    self?.importPDF(from: url)
                }
                return
            }

            if attachment.hasItemConformingToTypeIdentifier(UTType.commaSeparatedText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.commaSeparatedText.identifier) { [weak self] item, error in
                    guard let url = item as? URL else {
                        self?.close()
                        return
                    }
                    self?.importCSV(from: url)
                }
                return
            }
        }

        close()
    }

    private func importPDF(from url: URL) {
        do {
            let container = try makeContainer()
            let context = ModelContext(container)
            let imported = try PDFImporter.importFile(url: url, into: context)
            DispatchQueue.main.async {
                self.showResult(imported: imported)
            }
        } catch {
            DispatchQueue.main.async {
                self.showError(error.localizedDescription)
            }
        }
    }

    private func importCSV(from url: URL) {
        do {
            let container = try makeContainer()
            let context = ModelContext(container)
            let imported = try CSVImporter.importFile(url: url, into: context)
            DispatchQueue.main.async {
                self.showResult(imported: imported)
            }
        } catch {
            DispatchQueue.main.async {
                self.showError(error.localizedDescription)
            }
        }
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Transaction.self, Category.self, AppSettings.self])
        let config = ModelConfiguration("MoneyMonitor", groupContainer: .identifier("group.com.bkawk.MoneyMonitor"))
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func showResult(imported: Int) {
        let message = imported > 0 ? "Imported \(imported) transactions" : "No new transactions"
        let alert = UIAlertController(title: "Money Monitor", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            self.close()
        })
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Import Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.close()
        })
        present(alert, animated: true)
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
