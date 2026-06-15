import Foundation

struct MacVendorService: MacVendorServiceProtocol {
    private let ouiDatabase: [String: String]

    init() {
        var database: [String: String] = [:]

        if let url = Bundle.main.url(forResource: "oui_database", withExtension: "txt", subdirectory: "Resources"),
           let data = try? Data(contentsOf: url),
           let content = String(data: data, encoding: .utf8)
        {
            database = Self.parseOuiDatabase(content: content)
        }

        self.ouiDatabase = database
    }

    init(ouiDatabase: [String: String] = [:]) {
        self.ouiDatabase = ouiDatabase
    }

    func lookup(macAddress: String) -> String? {
        // Extract first 3 octets (6 hex characters), stripping separators
        let cleaned = macAddress
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ".", with: "")
            .uppercased()

        guard cleaned.count >= 6 else { return nil }

        let prefix = String(cleaned.prefix(6))
        return ouiDatabase[prefix]
    }

    // MARK: - Private Helpers

    private static func parseOuiDatabase(content: String) -> [String: String] {
        var database: [String: String] = [:]

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let fields = trimmed.split(separator: "|", omittingEmptySubsequences: false)
            guard fields.count >= 2 else { continue }

            let prefix = String(fields[0]).trimmingCharacters(in: .whitespaces).uppercased()
            let vendor = String(fields[1]).trimmingCharacters(in: .whitespaces)

            guard prefix.count == 6, prefix.allSatisfy(\.isHexDigit) else { continue }

            database[prefix] = vendor
        }

        return database
    }
}