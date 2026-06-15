import Foundation
import GRDB

final class DatabaseManager: Sendable {
    private let dbPool: DatabasePool

    init(inMemory: Bool = false) throws {
        if inMemory {
            // DatabasePool requires a file path; use a temp file for in-memory testing.
            let tempDir = FileManager.default.temporaryDirectory
            let uniqueName = "netscope-\(UUID().uuidString).db"
            let dbURL = tempDir.appendingPathComponent(uniqueName)
            var config = Configuration()
            config.prepareDatabase { db in
                try db.execute(sql: "PRAGMA foreign_keys=ON")
            }
            dbPool = try DatabasePool(path: dbURL.path, configuration: config)
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dbDir = appSupport.appendingPathComponent("NetScope", isDirectory: true)
            try FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
            let dbURL = dbDir.appendingPathComponent("netscope.db")
            var config = Configuration()
            config.prepareDatabase { db in
                try db.execute(sql: "PRAGMA journal_mode=WAL")
                try db.execute(sql: "PRAGMA foreign_keys=ON")
            }
            dbPool = try DatabasePool(path: dbURL.path, configuration: config)
        }
        try migrate()
    }

    func database() throws -> DatabasePool { dbPool }

    private func migrate() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "devices") { t in
                t.column("id", .text).primaryKey()
                t.column("ip", .text).notNull().unique()
                t.column("hostname", .text)
                t.column("mac_address", .text)
                t.column("vendor", .text)
                t.column("is_online", .integer).notNull().defaults(to: 0)
                t.column("first_seen", .datetime).notNull()
                t.column("last_seen", .datetime).notNull()
                t.column("notes", .text)
            }
            try db.create(table: "ports") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("device_id", .text).notNull().references("devices", onDelete: .cascade)
                t.column("port_number", .integer).notNull()
                t.column("protocol", .text).notNull()
                t.column("service", .text)
                t.column("state", .text).notNull()
            }
            try db.create(table: "metrics") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("device_id", .text).notNull().references("devices", onDelete: .cascade)
                t.column("latency_min", .double)
                t.column("latency_max", .double)
                t.column("latency_avg", .double)
                t.column("latency_median", .double)
                t.column("latency_stddev", .double)
                t.column("jitter", .double)
                t.column("packet_loss", .double)
                t.column("quality_score", .text).notNull()
                t.column("timestamp", .datetime).notNull()
            }
            try db.create(indexOn: "devices", columns: ["ip"])
            try db.create(indexOn: "devices", columns: ["last_seen"])
            try db.create(indexOn: "metrics", columns: ["device_id", "timestamp"])
            try db.create(indexOn: "ports", columns: ["device_id"])
        }

        migrator.registerMigration("v2") { db in
            try db.create(table: "scan_profiles") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("subnet", .text).notNull()
                t.column("scan_mode", .text).notNull()
                t.column("custom_ports", .text) // JSON array
                t.column("timeout", .double).notNull().defaults(to: 5.0)
            }
        }

        try migrator.migrate(dbPool)
    }
}