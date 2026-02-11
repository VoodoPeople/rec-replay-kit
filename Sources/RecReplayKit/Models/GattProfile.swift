import Foundation

// MARK: - GATT Profile

/// Static GATT profile structure defining services and characteristics.
///
/// ## Level-Scoped Detail
/// GATT-level fields (UUIDs, names, properties) are always present.
/// ATT-level handle information is grouped into optional `att` nested structs
/// on each service, characteristic, and descriptor — populated only when
/// recording at `--level att` or deeper. GATT-level consumers can ignore them.
public struct GattProfile: Codable, Sendable, Equatable {
    /// Negotiated MTU size
    public let mtu: Int?

    /// Services in the GATT profile
    public let services: [Service]

    public init(mtu: Int? = nil, services: [Service] = []) {
        self.mtu = mtu
        self.services = services
    }

    // MARK: - Service

    public struct Service: Codable, Sendable, Equatable {
        // -- GATT level (always present) --
        public let uuid: String
        public let name: String?
        public let type: String?
        public let characteristics: [Characteristic]?

        // -- ATT level (--level att or deeper) --
        /// ATT handle range for this service. Present only with ATT-level recording.
        public let att: ServiceATT?

        public init(
            uuid: String,
            name: String? = nil,
            type: String? = nil,
            characteristics: [Characteristic]? = nil,
            att: ServiceATT? = nil
        ) {
            self.uuid = uuid
            self.name = name
            self.type = type
            self.characteristics = characteristics
            self.att = att
        }
    }

    /// ATT-level handle information for a GATT service.
    public struct ServiceATT: Codable, Sendable, Equatable {
        /// ATT start handle of the service declaration
        public let handle: Int?

        /// ATT end handle of the service group
        public let endHandle: Int?

        public init(handle: Int? = nil, endHandle: Int? = nil) {
            self.handle = handle
            self.endHandle = endHandle
        }
    }

    // MARK: - Characteristic

    public struct Characteristic: Codable, Sendable, Equatable {
        // -- GATT level (always present) --
        public let uuid: String
        public let name: String?
        public let properties: [String]
        public let descriptors: [Descriptor]?

        /// Initial or default value of the characteristic (hex-encoded).
        /// Captured during recording by reading the characteristic.
        /// Used by mock/replay layers to provide default read responses.
        public let initialValue: String?

        // -- ATT level (--level att or deeper) --
        /// ATT handle information for this characteristic. Present only with ATT-level recording.
        public let att: CharacteristicATT?

        public init(
            uuid: String,
            name: String? = nil,
            properties: [String] = [],
            descriptors: [Descriptor]? = nil,
            initialValue: String? = nil,
            att: CharacteristicATT? = nil
        ) {
            self.uuid = uuid
            self.name = name
            self.properties = properties
            self.descriptors = descriptors
            self.initialValue = initialValue
            self.att = att
        }
    }

    /// ATT-level handle information for a GATT characteristic.
    public struct CharacteristicATT: Codable, Sendable, Equatable {
        /// ATT handle of the characteristic declaration
        public let handle: Int?

        /// ATT handle of the characteristic value attribute
        public let valueHandle: Int?

        public init(handle: Int? = nil, valueHandle: Int? = nil) {
            self.handle = handle
            self.valueHandle = valueHandle
        }
    }

    // MARK: - Descriptor

    public struct Descriptor: Codable, Sendable, Equatable {
        // -- GATT level (always present) --
        public let uuid: String
        public let name: String?

        /// Current value of the descriptor (hex-encoded).
        /// Captured during recording by reading the descriptor.
        public let value: String?

        // -- ATT level (--level att or deeper) --
        /// ATT handle information for this descriptor. Present only with ATT-level recording.
        public let att: DescriptorATT?

        public init(
            uuid: String,
            name: String? = nil,
            value: String? = nil,
            att: DescriptorATT? = nil
        ) {
            self.uuid = uuid
            self.name = name
            self.value = value
            self.att = att
        }
    }

    /// ATT-level handle information for a GATT descriptor.
    public struct DescriptorATT: Codable, Sendable, Equatable {
        /// ATT handle of the descriptor
        public let handle: Int?

        public init(handle: Int? = nil) {
            self.handle = handle
        }
    }
}
