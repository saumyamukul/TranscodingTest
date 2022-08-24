//
//  CBUUIDs.swift
//  Basic Chat MVC
//
//  Created by Trevor Beaton on 2/3/21.
//

import Foundation
import CoreBluetooth

struct CBUUIDs{

    static let kBLEService_UUID = "0000180d-0000-1000-8000-00805f9b34fb"
    static let kBLE_Characteristic_uuid_Tx = "0x4567"
    static let kBLE_Characteristic_uuid_Rx = "00002a37-0000-1000-8000-00805f9b34fb"
    static let MaxCharacters = 20

    static let BLEService_UUID = CBUUID(string: kBLEService_UUID)
    static let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
    static let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)

}
