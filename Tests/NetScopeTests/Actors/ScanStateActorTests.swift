import XCTest
@testable import NetScope

final class ScanStateActorTests: XCTestCase {

    actor TestHelper {
        var collectedDevices: [Device] = []

        func collect(from state: ScanStateActor) async {
            collectedDevices = await state.devices
        }

        var devices: [Device] { collectedDevices }
    }

    func testAddDevice() async {
        let state = ScanStateActor()
        let device = Device(ip: "192.168.1.1")
        await state.addDevice(device)

        let devices = await state.devices
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices.first?.ip, "192.168.1.1")
    }

    func testProgressUpdates() async {
        let state = ScanStateActor()
        await state.startScan(totalHosts: 10)

        for _ in 0..<10 {
            await state.incrementScanned()
        }

        let progress = await state.progress
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    func testCancel() async {
        let state = ScanStateActor()

        let initiallyFalse = await state.isCancelled
        XCTAssertFalse(initiallyFalse)

        await state.cancel()

        let nowTrue = await state.isCancelled
        XCTAssertTrue(nowTrue)
    }

    func testUpsertByIP() async {
        let state = ScanStateActor()

        let device1 = Device(ip: "192.168.1.1", hostname: "first")
        await state.addDevice(device1)

        let device2 = Device(ip: "192.168.1.1", hostname: "updated")
        await state.addDevice(device2)

        let devices = await state.devices
        XCTAssertEqual(devices.count, 1, "Upsert should keep only one device per IP")
        XCTAssertEqual(devices.first?.hostname, "updated", "Upsert should update the existing entry")
    }
}