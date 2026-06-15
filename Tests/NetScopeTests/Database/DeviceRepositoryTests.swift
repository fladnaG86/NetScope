import Testing
import Foundation
@testable import NetScope

@Suite("DeviceRepository")
struct DeviceRepositoryTests {

    private func makeRepo() throws -> DeviceRepository {
        let dbManager = try DatabaseManager(inMemory: true)
        return try DeviceRepository(dbManager: dbManager)
    }

    private func sampleDevice(ip: String = "192.168.1.1", ports: [PortInfo] = []) -> Device {
        Device(
            id: UUID(),
            ip: ip,
            hostname: "test-host",
            macAddress: "AA:BB:CC:DD:EE:FF",
            vendor: "TestVendor",
            isOnline: true,
            firstSeen: Date(),
            lastSeen: Date(),
            ports: ports,
            notes: "Test device"
        )
    }

    @Test("Save and find a device by ID")
    func testSaveAndFind() async throws {
        let repo = try makeRepo()
        let device = sampleDevice()

        try await repo.save(device)

        let found = try await repo.findById(device.id)
        #expect(found != nil)
        #expect(found?.id == device.id)
        #expect(found?.ip == device.ip)
        #expect(found?.hostname == device.hostname)
        #expect(found?.macAddress == device.macAddress)
        #expect(found?.vendor == device.vendor)
        #expect(found?.isOnline == device.isOnline)
        #expect(found?.notes == device.notes)
    }

    @Test("Find all returns all saved devices")
    func testFindAll() async throws {
        let repo = try makeRepo()
        let device1 = sampleDevice(ip: "192.168.1.1")
        let device2 = sampleDevice(ip: "192.168.1.2")

        try await repo.save(device1)
        try await repo.save(device2)

        let all = try await repo.findAll()
        #expect(all.count == 2)
    }

    @Test("Delete removes a device")
    func testDelete() async throws {
        let repo = try makeRepo()
        let device = sampleDevice()

        try await repo.save(device)
        let found = try await repo.findById(device.id)
        #expect(found != nil)

        try await repo.delete(device.id)
        let deleted = try await repo.findById(device.id)
        #expect(deleted == nil)
    }

    @Test("Save device with ports and retrieve them")
    func testSaveWithPorts() async throws {
        let repo = try makeRepo()
        let ports: [PortInfo] = [
            PortInfo(id: 80, number: 80, transport: .tcp, service: "http", state: .open),
            PortInfo(id: 443, number: 443, transport: .tcp, service: "https", state: .open),
            PortInfo(id: 53, number: 53, transport: .udp, service: "dns", state: .open),
        ]
        let device = sampleDevice(ports: ports)

        try await repo.save(device)

        let found = try await repo.findById(device.id)
        #expect(found != nil)
        #expect(found!.ports.count == 3)
        #expect(found!.ports[0].number == 80)
        #expect(found!.ports[0].transport == .tcp)
        #expect(found!.ports[0].service == "http")
        #expect(found!.ports[0].state == .open)
        #expect(found!.ports[1].number == 443)
        #expect(found!.ports[2].transport == .udp)
    }

    @Test("Save updates existing device (upsert)")
    func testUpsert() async throws {
        let repo = try makeRepo()
        let device = sampleDevice(ip: "10.0.0.1")

        try await repo.save(device)
        var updated = device
        updated.hostname = "updated-host"
        try await repo.save(updated)

        let found = try await repo.findById(device.id)
        #expect(found?.hostname == "updated-host")
        let all = try await repo.findAll()
        #expect(all.count == 1)
    }
}