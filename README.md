Creates a bluetooth central device using your iPhone. Code for the peripheral role on a Mac resides here https://github.com/saumyamukul

Run your Mac code first so you have aa advertising peripheral. Once you build and run this on your phone, it will auto connect to the Mac and start receiving characteristic updates at a fixed interval. It is currently setup to transcode a video after every 3 events. The transcoded video is stored in the app's Documents folder. It currently overwrites any existing file. You can change that behavior by using `getOutputFileNameWithTimesstamp` instead of `getOutputFileName` in the code.

You're likely interested in the `func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)` which is invoked for each notification from the peripheral. Code quality is quite poor and a lot of it has been mashed together from multiple sources. 
