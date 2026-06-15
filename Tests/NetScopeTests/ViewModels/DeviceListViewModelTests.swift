import XCTest
@testable import NetScope

final class DeviceListViewModelTests: XCTestCase {

    func testInitialState() {
        let viewModel = DeviceListViewModel()

        XCTAssertTrue(viewModel.devices.isEmpty, "devices should be empty initially")
        XCTAssertFalse(viewModel.isScanning, "isScanning should be false initially")
        XCTAssertNil(viewModel.error, "error should be nil initially")
        XCTAssertEqual(viewModel.scanProgress, 0, "scanProgress should be 0 initially")
        XCTAssertNil(viewModel.selectedDevice, "selectedDevice should be nil initially")
    }
}