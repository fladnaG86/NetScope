import Foundation
import GRDB

protocol MetricsRepositoryProtocol: Sendable {
    func save(_ metrics: NetworkMetrics) async throws
    func findByDevice(_ deviceId: UUID, limit: Int) async throws -> [NetworkMetrics]
    func deleteOlderThan(_ date: Date) async throws
}

final class MetricsRepository: MetricsRepositoryProtocol, Sendable {
    private let dbPool: DatabasePool

    init(dbManager: DatabaseManager) throws {
        self.dbPool = try dbManager.database()
    }

    func save(_ metrics: NetworkMetrics) async throws {
        let record = MetricsRecord(from: metrics)
        try await dbPool.write { db in
            try record.insert(db)
        }
    }

    func findByDevice(_ deviceId: UUID, limit: Int) async throws -> [NetworkMetrics] {
        try await dbPool.read { db in
            let records = try MetricsRecord
                .filter(Column("device_id") == deviceId.uuidString)
                .order(Column("timestamp").desc)
                .limit(limit)
                .fetchAll(db)
            return records.map { $0.toMetrics() }
        }
    }

    func deleteOlderThan(_ date: Date) async throws {
        _ = try await dbPool.write { db in
            try MetricsRecord
                .filter(Column("timestamp") < date)
                .deleteAll(db)
        }
    }
}