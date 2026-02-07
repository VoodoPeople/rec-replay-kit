import XCTest
@testable import RecReplayKit

final class DeviceDefinitionTests: XCTestCase {
    // MARK: - ADElement Tests

    func testADElementTypeConstants() {
        XCTAssertEqual(ADElement.typeFlags, 0x01)
        XCTAssertEqual(ADElement.typeCompleteLocalName, 0x09)
        XCTAssertEqual(ADElement.typeShortenedLocalName, 0x08)
        XCTAssertEqual(ADElement.typeManufacturerData, 0xFF)
        XCTAssertEqual(ADElement.typeTxPowerLevel, 0x0A)
        XCTAssertEqual(ADElement.typeAppearance, 0x19)
    }

    func testADElementClassification() {
        let manufacturerData = ADElement(type: 0xFF, data: "3905")
        XCTAssertTrue(manufacturerData.isManufacturerData)
        XCTAssertFalse(manufacturerData.isLocalName)

        let completeName = ADElement(type: 0x09, data: "416C65636B")
        XCTAssertTrue(completeName.isLocalName)
        XCTAssertFalse(completeName.isManufacturerData)

        let shortenedName = ADElement(type: 0x08, data: "416C65636B")
        XCTAssertTrue(shortenedName.isLocalName)

        let serviceUUIDs = ADElement(type: 0x03, data: "0F18")
        XCTAssertTrue(serviceUUIDs.isServiceUUIDList)
    }

    func testADElementFactoryMethods() {
        let name = ADElement.completeLocalName("Aleck")
        XCTAssertEqual(name.type, 0x09)
        XCTAssertEqual(name.data, "416C65636B")  // "Aleck" in hex

        let flags = ADElement.flags(0x06)
        XCTAssertEqual(flags.type, 0x01)
        XCTAssertEqual(flags.data, "06")

        let txPower = ADElement.txPowerLevel(4)
        XCTAssertEqual(txPower.type, 0x0A)
        XCTAssertEqual(txPower.data, "04")
    }

    func testADElementCodable() throws {
        let element = ADElement(type: 0x09, data: "416C65636B")

        let encoder = JSONEncoder()
        let data = try encoder.encode(element)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ADElement.self, from: data)

        XCTAssertEqual(element, decoded)
    }

    // MARK: - RawAdvertisementData Tests

    func testRawAdvertisementDataPDUTypes() {
        XCTAssertEqual(RawAdvertisementData.pduTypeAdvInd, "ADV_IND")
        XCTAssertEqual(RawAdvertisementData.pduTypeAdvNonconnInd, "ADV_NONCONN_IND")
        XCTAssertEqual(RawAdvertisementData.pduTypeScanRsp, "SCAN_RSP")
    }

    func testRawAdvertisementDataConnectable() {
        let connectable = RawAdvertisementData.connectable(adElements: [])
        XCTAssertTrue(connectable.isConnectable)
        XCTAssertFalse(connectable.isScanResponse)

        let nonConnectable = RawAdvertisementData.nonConnectable(adElements: [])
        XCTAssertFalse(nonConnectable.isConnectable)

        let scanResponse = RawAdvertisementData.scanResponse(adElements: [])
        XCTAssertTrue(scanResponse.isScanResponse)
        XCTAssertFalse(scanResponse.isConnectable)
    }

    func testRawAdvertisementDataElementAccess() {
        let elements = [
            ADElement(type: 0x01, data: "06"),
            ADElement(type: 0x09, data: "416C65636B"),
            ADElement(type: 0xFF, data: "3905416C65636B")
        ]
        let adv = RawAdvertisementData(pduType: "ADV_IND", adElements: elements)

        XCTAssertNotNil(adv.element(ofType: 0x09))
        XCTAssertNil(adv.element(ofType: 0x0A))
        XCTAssertTrue(adv.hasElement(ofType: 0xFF))
        XCTAssertNotNil(adv.manufacturerData)
        XCTAssertNotNil(adv.localNameElement)
    }

    func testRawAdvertisementDataCodable() throws {
        let elements = [
            ADElement(type: 0x01, data: "06"),
            ADElement(type: 0x09, data: "416C65636B")
        ]
        let adv = RawAdvertisementData(pduType: "ADV_IND", adElements: elements)

        let encoder = JSONEncoder()
        let data = try encoder.encode(adv)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RawAdvertisementData.self, from: data)

        XCTAssertEqual(adv, decoded)
    }

    // MARK: - DeviceDefinition Tests

    func testDeviceDefinitionCreation() {
        let adv = RawAdvertisementData.connectable(adElements: [
            ADElement.completeLocalName("Test Device")
        ])

        let definition = DeviceDefinition(
            id: "test-device-v1",
            advertisement: adv
        )

        XCTAssertEqual(definition.id, "test-device-v1")
        XCTAssertNil(definition.gattProfile)
        XCTAssertNil(definition.security)
        XCTAssertNil(definition.connectionParameters)
    }

    func testDeviceDefinitionWithAllProperties() {
        let adv = RawAdvertisementData.connectable(adElements: [])
        let gatt = GattProfile(mtu: 247, services: [])
        let security = SecurityConfiguration(authenticationRequired: true, securityLevel: "authenticated")
        let connParams = ConnectionParameters(preferredMTU: 247)

        let definition = DeviceDefinition(
            id: "full-device",
            advertisement: adv,
            gattProfile: gatt,
            security: security,
            connectionParameters: connParams
        )

        XCTAssertEqual(definition.preferredMTU, 247)
        XCTAssertTrue(definition.requiresAuthentication)
        XCTAssertTrue(definition.requiresEncryption)
    }

    func testDeviceDefinitionIdentifiable() {
        let adv = RawAdvertisementData.connectable(adElements: [])
        let definition = DeviceDefinition(id: "my-device", advertisement: adv)

        XCTAssertEqual(definition.id, "my-device")
    }

    func testDeviceDefinitionCodable() throws {
        let adv = RawAdvertisementData.connectable(adElements: [
            ADElement.completeLocalName("Test")
        ])
        let definition = DeviceDefinition(id: "test-v1", advertisement: adv)

        let encoder = JSONEncoder()
        let data = try encoder.encode(definition)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DeviceDefinition.self, from: data)

        XCTAssertEqual(definition, decoded)
    }
}
