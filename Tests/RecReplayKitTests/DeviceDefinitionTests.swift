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

    // MARK: - RawAdvertisementPDU Tests

    func testRawAdvertisementPDUTypeConstants() {
        XCTAssertEqual(RawAdvertisementPDU.pduTypeAdvInd, "ADV_IND")
        XCTAssertEqual(RawAdvertisementPDU.pduTypeAdvNonconnInd, "ADV_NONCONN_IND")
        XCTAssertEqual(RawAdvertisementPDU.pduTypeScanRsp, "SCAN_RSP")
    }

    func testRawAdvertisementPDUConnectable() {
        let connectable = RawAdvertisementPDU.connectable(adElements: [])
        XCTAssertTrue(connectable.isConnectable)
        XCTAssertFalse(connectable.isScanResponse)

        let nonConnectable = RawAdvertisementPDU.nonConnectable(adElements: [])
        XCTAssertFalse(nonConnectable.isConnectable)

        let scanResponse = RawAdvertisementPDU.scanResponse(adElements: [])
        XCTAssertTrue(scanResponse.isScanResponse)
        XCTAssertFalse(scanResponse.isConnectable)
    }

    func testRawAdvertisementPDUElementAccess() {
        let elements = [
            ADElement(type: 0x01, data: "06"),
            ADElement(type: 0x09, data: "416C65636B"),
            ADElement(type: 0xFF, data: "3905416C65636B")
        ]
        let pdu = RawAdvertisementPDU(pduType: "ADV_IND", adElements: elements)

        XCTAssertNotNil(pdu.element(ofType: 0x09))
        XCTAssertNil(pdu.element(ofType: 0x0A))
        XCTAssertTrue(pdu.hasElement(ofType: 0xFF))
        XCTAssertNotNil(pdu.manufacturerData)
        XCTAssertNotNil(pdu.localNameElement)
    }

    func testRawAdvertisementPDUCodable() throws {
        let elements = [
            ADElement(type: 0x01, data: "06"),
            ADElement(type: 0x09, data: "416C65636B")
        ]
        let pdu = RawAdvertisementPDU(pduType: "ADV_IND", adElements: elements)

        let encoder = JSONEncoder()
        let data = try encoder.encode(pdu)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RawAdvertisementPDU.self, from: data)

        XCTAssertEqual(pdu, decoded)
    }

    // MARK: - AdvertisementData Tests (Level-Scoped)

    func testAdvertisementDataGattLevelOnly() {
        // At GATT level: only parsed properties, no raw data
        let adv = AdvertisementData(
            localName: "Snow Core [C34]",
            serviceUUIDs: ["0000180F-0000-1000-8000-00805F9B34FB"],
            txPowerLevel: 4,
            isConnectable: true
        )

        XCTAssertEqual(adv.localName, "Snow Core [C34]")
        XCTAssertEqual(adv.serviceUUIDs?.count, 1)
        XCTAssertEqual(adv.isConnectable, true)
        XCTAssertEqual(adv.txPowerLevel, 4)
        XCTAssertNil(adv.raw)
        XCTAssertNil(adv.rawScanResponse)
        XCTAssertFalse(adv.hasRawData)
        XCTAssertFalse(adv.hasScanResponse)
    }

    func testAdvertisementDataHCILevel() {
        // At HCI level: parsed properties + raw PDU detail
        let rawPDU = RawAdvertisementPDU.connectable(adElements: [
            ADElement.flags(0x06),
            ADElement.completeLocalName("Snow Core [C34]")
        ])
        let scanRsp = RawAdvertisementPDU.scanResponse(adElements: [
            ADElement.completeLocalName("Snow Core [C34]")
        ])
        let adv = AdvertisementData(
            localName: "Snow Core [C34]",
            isConnectable: true,
            raw: rawPDU,
            rawScanResponse: scanRsp
        )

        XCTAssertEqual(adv.localName, "Snow Core [C34]")
        XCTAssertTrue(adv.hasRawData)
        XCTAssertTrue(adv.hasScanResponse)
        XCTAssertEqual(adv.raw?.pduType, "ADV_IND")
        XCTAssertEqual(adv.rawScanResponse?.pduType, "SCAN_RSP")
    }

    func testAdvertisementDataCodable() throws {
        let adv = AdvertisementData(
            localName: "Test",
            serviceUUIDs: ["180F"],
            manufacturerData: "3905FF",
            isConnectable: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(adv)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AdvertisementData.self, from: data)

        XCTAssertEqual(adv, decoded)
    }

    func testAdvertisementDataCodableWithRaw() throws {
        let rawPDU = RawAdvertisementPDU.connectable(adElements: [
            ADElement.completeLocalName("Test")
        ])
        let adv = AdvertisementData(
            localName: "Test",
            isConnectable: true,
            raw: rawPDU
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(adv)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AdvertisementData.self, from: data)

        XCTAssertEqual(adv, decoded)
        XCTAssertNotNil(decoded.raw)
        XCTAssertEqual(decoded.raw?.adElements.count, 1)
    }

    // MARK: - DeviceDefinition Tests

    func testDeviceDefinitionCreation() {
        // GATT level: just parsed advertisement properties
        let adv = AdvertisementData(
            localName: "Test Device",
            isConnectable: true
        )

        let definition = DeviceDefinition(
            id: "test-device-v1",
            advertisement: adv
        )

        XCTAssertEqual(definition.id, "test-device-v1")
        XCTAssertEqual(definition.localName, "Test Device")
        XCTAssertNil(definition.gattProfile)
        XCTAssertNil(definition.security)
        XCTAssertNil(definition.connectionParameters)
    }

    func testDeviceDefinitionWithAllProperties() {
        let adv = AdvertisementData(localName: "Full Device", isConnectable: true)
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
        let definition = DeviceDefinition(id: "my-device")

        XCTAssertEqual(definition.id, "my-device")
    }

    func testDeviceDefinitionCodable() throws {
        let adv = AdvertisementData(
            localName: "Test",
            isConnectable: true
        )
        let definition = DeviceDefinition(id: "test-v1", advertisement: adv)

        let encoder = JSONEncoder()
        let data = try encoder.encode(definition)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DeviceDefinition.self, from: data)

        XCTAssertEqual(definition, decoded)
    }

    func testDeviceDefinitionMinimal() {
        // Minimum viable DeviceDefinition: just an ID
        let definition = DeviceDefinition(id: "bare-device")

        XCTAssertEqual(definition.id, "bare-device")
        XCTAssertNil(definition.advertisement)
        XCTAssertNil(definition.gattProfile)
        XCTAssertNil(definition.localName)
        XCTAssertFalse(definition.hasRawAdvertisement)
    }

    func testDeviceDefinitionWithHCIAdvertisement() {
        // Full HCI-level recording with raw PDU and scan response
        let rawPDU = RawAdvertisementPDU.connectable(adElements: [
            ADElement.flags(0x06),
            ADElement.completeLocalName("Snow Core"),
            ADElement.manufacturerData(companyId: 0x0539, data: "FF416C65636B")
        ])
        let scanRsp = RawAdvertisementPDU.scanResponse(adElements: [
            ADElement.completeLocalName("Snow Core [C34]")
        ])

        let adv = AdvertisementData(
            localName: "Snow Core [C34]",
            serviceUUIDs: ["0000180F-0000-1000-8000-00805F9B34FB"],
            manufacturerData: "3905FF416C65636B",
            isConnectable: true,
            raw: rawPDU,
            rawScanResponse: scanRsp
        )

        let definition = DeviceDefinition(id: "snow-core-v1", advertisement: adv)

        XCTAssertEqual(definition.localName, "Snow Core [C34]")
        XCTAssertTrue(definition.hasRawAdvertisement)
        XCTAssertEqual(definition.advertisement?.raw?.adElements.count, 3)
        XCTAssertEqual(definition.advertisement?.rawScanResponse?.pduType, "SCAN_RSP")
    }
}
