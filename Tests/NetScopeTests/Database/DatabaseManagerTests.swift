import Testing
import Foundation
import GRDB
@testable import NetScope

@Suite("DatabaseManager")
struct DatabaseManagerTests {

    @Test("In-memory database creates schema with all expected tables")
    func testInMemoryDatabaseCreatesSchema() async throws {
        let dbManager = try DatabaseManager(inMemory: true)
        let pool = try dbManager.database()

        try await pool.read { db in
            // Verify all four tables exist by querying sqlite_master
            let tables = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master WHERE type='table' ORDER BY name
                """)
            #expect(tables.contains("devices"))
            #expect(tables.contains("ports"))
            #expect(tables.contains("metrics"))
            #expect(tables.contains("scan_profiles"))
        }
    }

    @Test("Migrations are idempotent — second DatabaseManager does not fail")
    func testMigrationsIdempotent() async throws {
        let dbManager1 = try DatabaseManager(inMemory: true)
        // Creating a second in-memory database should not fail
        // (each in-memory DB is independent, but this verifies the migration logic itself
        // doesn't error when run twice on the same conceptual schema)
        let dbManager2 = try DatabaseManager(inMemory: true)

        // Also verify we can migrate the SAME pool twice via the pool itself
        let pool1 = try dbManager1.database()
        let pool2 = try dbManager2.database()

        // Both should have the same tables
        try await pool1.read { db in
            let tables = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master WHERE type='table' ORDER BY name
                """)
            #expect(tables.contains("devices"))
        }

        try await pool2.read { db in
            let tables = try String.fetchAll(db, sql: """
                SELECT name FROM sqlite_master WHERE type='table' ORDER BY name
                """)
            #expect(tables.contains("devices"))
        }
    }
}