//
//  AppDelegate.swift
//  Basic Chat MVC
//
//  Created by Trevor Beaton on 2/3/21.
//

import UIKit
import CoreBluetooth
import ffmpegkit
import AVFAudio

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // Data
    private var centralManager: CBCentralManager!
    private var bluefruitPeripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    private var timer = Timer()
    private var count: Int = 0
    private var inProgress: Bool = false
    private var player: AVAudioPlayer?
    
    var inputUrl: URL?
    var outputUrl: URL?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.inputUrl = Bundle.main.url(forResource: "480x642-20s-HEVC", withExtension: "mp4")
        
        
        if (inputUrl == nil) {
            NSLog("Failed to initialize media paths")
        }
        
        NSLog("BLE Test: Finished launching")

        // Setup BT manager
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionRestoreIdentifierKey: "SaumyaApp"])
        
        
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSession.Category.playback,
                options: AVAudioSession.CategoryOptions.mixWithOthers
            )
        }   catch let error {
            NSLog("BLE Test: Error \(error)")
        }
        
        do {
            // Attempts to activate session so you can play audio,
            // if other sessions have priority this will fail
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            NSLog("BLE Test: Error \(error)")
        }
        
        let loopURL = Bundle.main.url(forResource: "loop", withExtension: "mp3")
        do {
            player = try AVAudioPlayer(contentsOf: loopURL!)
            player!.numberOfLoops = -1
            // UNCOMMENT THE NEXT LINE IF YOU WANT TO TEST TRANSCODING WITH AUDIO
            // player!.play()
        } catch let error {
            NSLog("BLE Test: Error \(error)")
        }
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func startScanning() -> Void {
        NSLog("BLE Test: Starting scan.")
        // Start Scanning
        centralManager?.scanForPeripherals(withServices: nil)//[CBUUIDs.BLEService_UUID])
        Timer.scheduledTimer(withTimeInterval: 15, repeats: false) {_ in
            self.stopScanning()
        }
    }
    
    func stopScanning() -> Void {
        centralManager?.stopScan()
    }
    
    func getOutputFileName() -> String {
        // Construct a name based on current time
        let now = Date()
        let formatter1 = DateFormatter()
        formatter1.dateFormat = "HH:mm:ss"
        return formatter1.string(from: now)
    }
    
    func transcodeVideo(hardwareDecode: Bool, hardwareEncode: Bool) {
        
        let outputName = getOutputFileName()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let outputPath = documentsDirectory!.appendingPathComponent("\(outputName).mp4" ).path
        let decoderFormat = hardwareDecode ? "-hwaccel videotoolbox -c:v hevc" : "-c:v hevc"
        let encoderFormat = hardwareEncode ? "-c:v h264_videotoolbox -b:v 2M" : "-c:v libx264"
        let command = String(format: "\(decoderFormat) -i \(self.inputUrl!.path) \(encoderFormat) -c:a copy \(outputPath)")
        NSLog("BLE Test: FFMPEG command: \(command)")
        // Start timer
        let startTime = CFAbsoluteTimeGetCurrent()
        FFmpegKit.executeAsync(command) { [self] session in
            guard let session = session else {
                NSLog("BLE Test: !! Invalid session")
                return
            }
            guard let returnCode = session.getReturnCode() else {
                NSLog("BLE Test: !! Invalid return code")
                return
            }
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            assert(returnCode.isValueSuccess())
            
            NSLog("BLE Test Transcode time for file \(outputName) = \(timeElapsed) s")
            self.inProgress = false
        } withLogCallback: { logs in
            // guard let message = logs?.getMessage() else { return }
            // NSLog("BLE Test Transcoding: \(message)")
        } withStatisticsCallback: { stats in
        }
    }
}

// MARK: - CBCentralManagerDelegate
// A protocol that provides updates for the discovery and management of peripheral devices.
extension AppDelegate: CBCentralManagerDelegate {
    
    // MARK: - Check
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOff:
            NSLog("BLE Test: Is Powered Off.")
            
        case .poweredOn:
            NSLog("BLE Test: Is Powered On.")
            if bluefruitPeripheral != nil {
                NSLog("Found peripheral, connecting.")
                centralManager?.connect(bluefruitPeripheral!, options: nil)
            } else {
                startScanning()
            }
        case .unsupported:
            NSLog("BLE Test: Is Unsupported.")
        case .unauthorized:
            NSLog("BLE Test: Is Unauthorized.")
        case .unknown:
            NSLog("BLE Test: Unknown")
        case .resetting:
            NSLog("BLE Test: Resetting")
        @unknown default:
            NSLog("BLE Test: Error")
        }
    }
    
    // MARK: - Discover
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        NSLog("Function: \(#function),Line: \(#line)")
        if peripheral.name != "raspberrypi" {
            return
        }
        
        bluefruitPeripheral = peripheral
        
        bluefruitPeripheral!.delegate = self
        centralManager?.connect(bluefruitPeripheral!, options: nil)
    }
    
    // MARK: - Connect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScanning()
        bluefruitPeripheral!.discoverServices([CBUUIDs.BLEService_UUID])
    }
    
    // MARK: - WillRestoreState
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        NSLog("BLE Test: Will restore")
        let peripherals: [CBPeripheral] = dict[
            CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        
        guard peripherals.count != 0 else {
            NSLog("BLE Test: Peripherals empty")
            return
        }
        
        if peripherals.count > 1 {
            NSLog("BLE Test Warning: willRestoreState called with >1 connection")
        }
        bluefruitPeripheral = peripherals[0]
        bluefruitPeripheral!.delegate = self
        
        if central.state == .poweredOn {
            NSLog("BLE Test: Powered on, Reconnecting")
            centralManager?.connect(bluefruitPeripheral!, options: nil)
        }
        NSLog("Need to wait for power")
    }
    
    
}

// MARK: - CBPeripheralDelegate
// A protocol that provides updates on the use of a peripheral’s services.
extension AppDelegate: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        for service in services {
            NSLog("Service Discovered: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
        BlePeripheral.connectedService = services[0]
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else {
            NSLog("Discovered lame characteristics")
            return
        }
        
        NSLog("Found \(characteristics.count) characteristics.")
        
        for characteristic in characteristics {
            
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Rx)  {
                
                rxCharacteristic = characteristic
                
                BlePeripheral.connectedRXChar = rxCharacteristic
                
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                peripheral.readValue(for: characteristic)
                
                NSLog("RX Characteristic: \(rxCharacteristic.uuid)")
            }
            
            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                BlePeripheral.connectedTXChar = txCharacteristic
                NSLog("TX Characteristic: \(txCharacteristic.uuid)")
            }
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        let characteristicASCIIValue = NSString()
        
        guard characteristic == rxCharacteristic else {return}
        
        let characteristicValue = characteristic.value
        let updatedValue = characteristicValue?.withUnsafeBytes( {(pointer: UnsafeRawBufferPointer) -> UInt8 in
            return pointer.load(as: UInt8.self)
        })
        
        NSLog("BLE Test: Value Recieved: \(updatedValue)")
        
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: "\((characteristicASCIIValue as String))")
        count+=1
        if(inProgress) {
            return
        }
        if(count % 10 == 0) {
            NSLog("BLE Test: Beginning Trancoding")
            inProgress = true
            transcodeVideo(hardwareDecode: false, hardwareEncode: false)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        peripheral.readRSSI()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            NSLog("Error discovering services: error")
            return
        }
        NSLog("Function: \(#function),Line: \(#line)")
        NSLog("Message sent")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            NSLog("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        } else {
            NSLog("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
}
