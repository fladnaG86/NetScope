import Foundation

actor DeviceCacheActor {
    private var cache: [String: Device] = [:]
    private var insertionOrder: [String] = []
    private let maxSize: Int

    init(maxSize: Int = 256) {
        self.maxSize = maxSize
    }

    func get(ip: String) -> Device? {
        cache[ip]
    }

    func set(_ device: Device) {
        let ip = device.ip
        if cache[ip] != nil {
            // Update existing entry (keep its position in order)
            cache[ip] = device
        } else {
            // Evict oldest if at capacity
            if cache.count >= maxSize {
                if let oldestIP = insertionOrder.first {
                    cache.removeValue(forKey: oldestIP)
                    insertionOrder.removeFirst()
                }
            }
            cache[ip] = device
            insertionOrder.append(ip)
        }
    }

    func remove(ip: String) {
        if cache.removeValue(forKey: ip) != nil {
            insertionOrder.removeAll { $0 == ip }
        }
    }

    func clear() {
        cache.removeAll()
        insertionOrder.removeAll()
    }

    var count: Int {
        cache.count
    }
}