import Foundation
import GRDB

protocol DeviceRepositoryProtocol: Sendable {
    func save(_ device: Device) async throws
    func findById(_ id: UUID) async throws -> Device?
    func findAll() async throws -> [Device]
    func delete(_ id: UUID) async throws
    func deleteAll() async throws
}

final class DeviceRepository: DeviceRepositoryProtocol, Sendable {
    private let dbPool: DatabasePool

    init(dbManager: DatabaseManager) throws {
        self.dbPool = try dbManager.database()
    }

    func save(_ device: Device) async throws {
        let record = DeviceRecord(from: device)
        let portRecords = device.ports.map { PortRecord(from: $0, deviceId: device.id) }

        try await dbPool.write { db in
            try record.save(db)
            // Delete old ports for this device, then insert new ones
            try PortRecord
                .filter(Column("device_id") == device.id.uuidString)
                .deleteAll(db)
            for portRecord in portRecords {
                try portRecord.insert(db)
            }
        }
    }

    func findById(_ id: UUID) async throws -> Device? {
        try await dbPool.read { db in
            guard let record = try DeviceRecord
                .filter(Column("id") == id.uuidString)
                .fetchOne(db)
            else {
                return nil
            }
            let portRecords = try PortRecord
                .filter(Column("device_id") == id.uuidString)
                .fetchAll(db)
            let ports = portRecords.map { $0.toPortInfo() }
            return record.toDevice(ports: ports)
        }
    }

    func findAll() async throws -> [Device] {
        try await dbPool.read { db in
            let records = try DeviceRecord.fetchAll(db)
            return try records.map { record in
                let portRecords = try PortRecord
                    .filter(Column("device_id") == record.id)
                    .fetchAll(db)
                let ports = portRecords.map { $0.toPortInfo() }
                return record.toDevice(ports: ports)
            }
        }
    }

    func delete(_ id: UUID) async throws {
        _ = try await dbPool.write { db in
            try DeviceRecord
                .filter(Column("id") == id.uuidString)
                .deleteAll(db)
            // CASCADE handles ports deletion, but be explicit for safety
            try PortRecord
                .filter(Column("device_id") == id.uuidString)
                .deleteAll(db)
        }
    }

    func deleteAll() async throws {
        _ = try await dbPool.write { db in
            try DeviceRecord.deleteAll(db)
            // CASCADE handles ports, but explicit for safety
            try PortRecord.deleteAll(db)
        }
    }
}