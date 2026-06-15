import Testing
import Foundation
@testable import NetScope

@Suite("MetricsRepository")
struct MetricsRepositoryTests {

    private func makeContext() throws -> (MetricsRepository, DeviceRepository, DatabaseManager) {
        let dbManager = try DatabaseManager(inMemory: true)
        let metricsRepo = try MetricsRepository(dbManager: dbManager)
        let deviceRepo = try DeviceRepository(dbManager: dbManager)
        return (metricsRepo, deviceRepo, dbManager)
    }

    private func sampleDevice(id: UUID = UUID()) -> Device {
        Device(
            id: id,
            ip: "10.0.0.\(Int.random(in: 1...254))",
            hostname: "test-host",
            macAddress: nil,
            vendor: nil,
            isOnline: true,
            firstSeen: Date(),
            lastSeen: Date(),
            ports: [],
            notes: nil
        )
    }

    private func sampleMetrics(
        deviceId: UUID = UUID(),
        timestamp: Date = Date(),
        qualityScore: QualityScore = .good
    ) -> NetworkMetrics {
        NetworkMetrics(
            id: nil,
            deviceId: deviceId,
            timestamp: timestamp,
            latency: LatencyStats(
                min: 1.0,
                max: 10.0,
                average: 5.0,
                median: 4.5,
                standardDeviation: 2.0
            ),
            jitter: 1.5,
            packetLoss: 0.01,
            qualityScore: qualityScore
        )
    }

    @Test("Save metrics and find by device")
    func testSaveAndFindByDevice() async throws {
        let (repo, deviceRepo, _) = try makeContext()
        let deviceId = UUID()
        try await deviceRepo.save(sampleDevice(id: deviceId))
        let metrics = sampleMetrics(deviceId: deviceId)

        try await repo.save(metrics)

        let found = try await repo.findByDevice(deviceId, limit: 10)
        #expect(found.count == 1)
        #expect(found[0].deviceId == deviceId)
        #expect(found[0].latency.min == 1.0)
        #expect(found[0].latency.max == 10.0)
        #expect(found[0].latency.average == 5.0)
        #expect(found[0].latency.median == 4.5)
        #expect(found[0].latency.standardDeviation == 2.0)
        #expect(found[0].jitter == 1.5)
        #expect(found[0].packetLoss == 0.01)
        #expect(found[0].qualityScore == .good)
    }

    @Test("Delete older than removes only old metrics")
    func testDeleteOlderThan() async throws {
        let (repo, deviceRepo, _) = try makeContext()
        let deviceId = UUID()
        try await deviceRepo.save(sampleDevice(id: deviceId))

        let oldDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        let newDate = Date()

        let oldMetrics = sampleMetrics(deviceId: deviceId, timestamp: oldDate, qualityScore: .poor)
        let newMetrics = sampleMetrics(deviceId: deviceId, timestamp: newDate, qualityScore: .excellent)

        try await repo.save(oldMetrics)
        try await repo.save(newMetrics)

        // Delete metrics older than 1 day ago
        let cutoff = Date().addingTimeInterval(-86400)
        try await repo.deleteOlderThan(cutoff)

        let remaining = try await repo.findByDevice(deviceId, limit: 10)
        #expect(remaining.count == 1)
        #expect(remaining[0].qualityScore == .excellent)
    }

    @Test("FindByDevice respects limit")
    func testFindByDeviceLimit() async throws {
        let (repo, deviceRepo, _) = try makeContext()
        let deviceId = UUID()
        try await deviceRepo.save(sampleDevice(id: deviceId))

        for i in 0..<5 {
            let metrics = sampleMetrics(
                deviceId: deviceId,
                timestamp: Date().addingTimeInterval(Double(i))
            )
            try await repo.save(metrics)
        }

        let found = try await repo.findByDevice(deviceId, limit: 3)
        #expect(found.count == 3)
    }

    @Test("FindByDevice returns empty for non-existent device")
    func testFindByDeviceNonExistent() async throws {
        let (repo, _, _) = try makeContext()

        let found = try await repo.findByDevice(UUID(), limit: 10)
        #expect(found.isEmpty)
    }
}