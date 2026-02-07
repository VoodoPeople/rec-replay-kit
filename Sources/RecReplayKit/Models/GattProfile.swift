import Foundation

// MARK: - GATT Profile

/// Static GATT profile structure defining services and characteristics.
///
/// ## ATT Handle Fields
/// ATT handle fields (`handle`, `endHandle`, `valueHandle`) are optional and
/// populated only when ATT-level recording is available (e.g., via HCI monitor
/// or embedded stacks). GATT-level recordings (e.g., BlueZ D-Bus) use UUID-based
/// addressing and omit handles entirely. Both representations are valid.
public struct GattProfile: Codable, Sendable, Equatable {
    /// Negotiated MTU size
    public let mtu: Int?

    /// Services in the GATT profile
    public let services: [Service]

    public init(mtu: Int? = nil, services: [Service] = []) {
        self.mtu = mtu
        self.services = services
    }

    // MARK: - Nested Types

    public struct Service: Codable, Sendable, Equatable {
        public let uuid: String
        public let name: String?
        public let type: String?
        public let characteristics: [Characteristic]?

        /// ATT start handle of the service declaration.
        /// Populated only when ATT-level recording is available.
        public let handle: Int?

        /// ATT end handle of the service group.
        /// Populated only when ATT-level recording is available.
        public let endHandle: Int?

        public init(
            uuid: String,
            name: String? = nil,
            type: String? = nil,
            characteristics: [Characteristic]? = nil,
            handle: Int? = nil,
            endHandle: Int? = nil
        ) {
            self.uuid = uuid
            self.name = name
            self.type = type
            self.characteristics = characteristics
            self.handle = handle
            self.endHandle = endHandle
        }
    }

    public struct Characteristic: Codable, Sendable, Equatable {
        public let uuid: String
        public let name: String?
        public let properties: [String]
        public let descriptors: [Descriptor]?

        /// ATT handle of the characteristic declaration.
        /// Populated only when ATT-level recording is available.
        public let handle: Int?

        /// ATT handle of the characteristic value attribute.
        /// Populated only when ATT-level recording is available.
        public let valueHandle: Int?

        /// Initial or default value of the characteristic (hex-encoded).
        /// Captured during recording by reading the characteristic.
        /// Used by mock/replay layers to provide default read responses.
        public let initialValue: String?

        public init(
            uuid: String,
            name: String? = nil,
            properties: [String] = [],
            descriptors: [Descriptor]? = nil,
            handle: Int? = nil,
            valueHandle: Int? = nil,
            initialValue: String? = nil
        ) {
            self.uuid = uuid
            self.name = name
            self.properties = properties
            self.descriptors = descriptors
            self.handle = handle
            self.valueHandle = valueHandle
            self.initialValue = initialValue
        }
    }

    public struct Descriptor: Codable, Sendable, Equatable {
        public let uuid: String
        public let name: String?

        /// ATT handle of the descriptor.
        /// Populated only when ATT-level recording is available.
        public let handle: Int?

        /// Current value of the descriptor (hex-encoded).
        /// Captured during recording by reading the descriptor.
        public let value: String?

        public init(
            uuid: String,
            name: String? = nil,
            handle: Int? = nil,
            value: String? = nil
        ) {
            self.uuid = uuid
            self.name = name
            self.handle = handle
            self.value = value
        }
    }
}
