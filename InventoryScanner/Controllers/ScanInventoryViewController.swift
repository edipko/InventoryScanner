//
//  ScanInventoryViewController.swift
//  Inventory Scanner
//
//  Created by Ernie Dipko 2019.09.12
//
//

import UIKit
import MTBBarcodeScanner
import SKTCapture


class ScanInventoryViewController: UIViewController, UITextFieldDelegate, CaptureHelperDevicePresenceDelegate,
CaptureHelperDeviceDecodedDataDelegate
 {
  
    
    
    @IBOutlet var txtBarCode: UITextField!
    @IBOutlet var txtNotes: UITextField!
    @IBOutlet weak var txtQuantity: UITextField! {
        didSet { txtQuantity?.addDoneCancelToolbar() }
    }
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet var previewView: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var switchCamera: UIImageView!
    @IBOutlet weak var butTorch: UIBarButtonItem!
    @IBOutlet weak var lblType: UILabel!
   
    var scanner: MTBBarcodeScanner?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var fileUrl = URL(string: "");
    
    var torchState = 0;
    var haveScanner = false;
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanner = MTBBarcodeScanner(previewView: previewView)
        
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        fileUrl = documentDirectoryUrl.appendingPathComponent(appDelegate.filename!)
        
        self.txtBarCode.delegate = self;
        self.txtBarCode.inputView = UIView();
        
        self.txtQuantity.delegate = self;
        self.txtNotes.delegate = self;
        
        
        // to make all the capture helper delegates and completion handlers able to
        // update the UI without the app having to dispatch the UI update code,
        // set the dispatchQueue property to the DispatchQueue.main
        CaptureHelper.sharedInstance.dispatchQueue = DispatchQueue.main

        // there is a stack of delegates the last push is the
        // delegate active, when a new view requiring notifications from the
        // scanner, then push its delegate and pop its delegate when the
        // view is done
        CaptureHelper.sharedInstance.pushDelegate(self)

        let appInfo = SKTAppInfo();
        appInfo.developerID = "dd42ea3f-41df-e911-a983-000d3a3638df"
        appInfo.appID = "ios:com.spotonresponse.PCInventoryScanner"
        appInfo.appKey = "MC4CFQCXGm+vgyyVN9JRx0crw9XiHizOCQIVALj8ZkSCCwirk7XP+8fJmPteZTQn"
        CaptureHelper.sharedInstance.openWithAppInfo(appInfo, withCompletionHandler: { (result) in
            print("Result of Capture initialization: \(result.rawValue)")
        })
        
        let deviceManagers = CaptureHelper.sharedInstance.getDeviceManagers()
        if deviceManagers.count > 0 {
            let deviceManager = deviceManagers[0];
            deviceManager.startDiscoveryWithTimeout(5000) { (result) in
                print("start discovery returns result \(result.rawValue)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.txtQuantity.keyboardType = UIKeyboardType.phonePad
        self.txtQuantity.reloadInputViews()
        if (!haveScanner) {
           self.startScanning();
        }

    }
    
    func startScanning() {
        MTBBarcodeScanner.requestCameraPermission(success: { success in
            if success {
                do {
                    // Start scanning with the front camera
                    try self.scanner?.startScanning(
                        with: .back,
                        resultBlock: { codes in
                            if let codes = codes {
                                for code in codes {
                                    let rawCode = code.type.rawValue;
                                    self.lblType.text = rawCode;
                                    
                                    let stringValue = code.stringValue!
                                    self.scanner?.stopScanning();
                                    print("Found code: \(stringValue)")
                                    
                                    // Add the code to the barCode Field
                                    self.txtBarCode.text = stringValue;
                                    
                                    // Put name on top so it is noticeable if possible
                                    if ((rawCode == "org.iso.PDF417") || (rawCode == "org.iso.DataMatrix")) {
                                        
                                        var itemArr = stringValue.components(separatedBy: "|")
                                        var itemName = "";
                                        if (itemArr.count > 1) {
                                            itemName = itemArr[1];
                                        } else {
                                            itemName = ""
                                        }
                                        self.lblName.text = itemName;
                                        
                                    }
                                    
                                    
                                }
                            }
                            self.txtQuantity.becomeFirstResponder();
                    })
                } catch {
                    NSLog("Unable to start scanning")
                }
            } else {
                let alertController = UIAlertController(title: "Scanning Unavailable", message: "This app does not have permission to access the camera", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        })
    }
    
    
  
    
    @IBAction func toggleTorchTapped(_ sender: Any) {
        if self.torchState == 0 {
            self.torchState = 1;
            butTorch.title = "Torch Off"
        } else {
            self.torchState = 0;
            butTorch.title = "Torch On"
        }
        self.scanner?.toggleTorch()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.scanner?.stopScanning()
        
        super.viewWillDisappear(animated)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func swtchCameraTapped(_ sender: UIButton) {
        self.scanner?.flipCamera()
    }
    
    @IBAction func addInventoryClick(_ sender: Any) {
        
        let output = "\(self.txtQuantity.text ?? "")|\(self.txtNotes.text ?? "")|\(self.txtBarCode.text ?? "")";
        appDelegate.inventory.add(output);
        
        print("Added: \(output)");
        
        // Save to file so nothing gets lost
        self.saveData()
        
        // Reset the form and start the scanner for the next entry
        self.txtNotes.text = "";
        self.txtQuantity.text = "";
        self.txtBarCode.text = "";
        self.lblName.text = "";
        self.lblType.text = "";
        
        self.txtNotes.resignFirstResponder()
        self.txtQuantity.resignFirstResponder()
        self.txtBarCode.becomeFirstResponder()
        
        if (!haveScanner) {
           self.startScanning();
        }
        
    }
    
    
    @IBAction func clearEntryClick(_ sender: Any) {
        // Reset the form and start the scanner for the next entry
        self.txtNotes.text = "";
        self.txtQuantity.text = "";
        self.txtBarCode.text = "";
        self.lblName.text = "";
        self.lblType.text = "";
        
        self.txtNotes.resignFirstResponder()
        self.txtQuantity.resignFirstResponder()
        self.txtBarCode.becomeFirstResponder()
        
        if (!haveScanner) {
           self.startScanning();
        }
    }
    
    func saveData() {
        // Transform array into data and save it into file
        var data = ""
        do {
            for item in self.appDelegate.inventory {
                let temp = item as! String + "\n"
                data.append(contentsOf: temp)
            }
            try data.write(to: fileUrl!, atomically: true, encoding: String.Encoding.utf8)
            
            print("Write file: \(fileUrl?.absoluteString ?? "")")
            self.view.makeToast("Data Saved", duration: 3.0, position: .bottom)
        } catch {
            print(error)
        }
    }
    
    // MARK: - CaptureHelperDevicePresenceDelegate

    func didNotifyArrivalForDevice(_ device: CaptureHelperDevice, withResult result: SKTResult) {
        print("Main view device arrival:\(String(describing: device.deviceInfo.name))")
        haveScanner = true;
        self.scanner?.stopScanning();
    }

    func didNotifyRemovalForDevice(_ device: CaptureHelperDevice, withResult result: SKTResult) {
        print("Main view device removal:\(device.deviceInfo.name!)")
        haveScanner = false;
    }

    // MARK: - CaptureHelperDeviceDecodedDataDelegate

    // This delegate is called each time a decoded data is read from the scanner
    // It has a result field that should be checked before using the decoded
    // data.
    // It would be set to SKTCaptureErrors.E_CANCEL if the user taps on the
    // cancel button in the SoftScan View Finder
    func didReceiveDecodedData(_ decodedData: SKTCaptureDecodedData?, fromDevice device: CaptureHelperDevice, withResult result: SKTResult) {

        if result == SKTCaptureErrors.E_NOERROR {
           let code = decodedData?.stringFromDecodedData()!
            let stringValue = code.unsafelyUnwrapped
            print("Decoded Data \(stringValue)")
            
            // Add the code to the barCode Field
            self.txtBarCode.text = stringValue;
            
            // Put name on top so it is noticeable if possible
            if ((decodedData?.dataSourceName == "Pdf417") || (decodedData?.dataSourceName == "Data Matrix")) {
                
                var itemArr = stringValue.components(separatedBy: "|")
                var itemName = "";
                if (itemArr.count > 1) {
                    itemName = itemArr[1];
                } else {
                    itemName = ""
                }
                self.lblName.text = itemName;
            }
            self.txtQuantity.becomeFirstResponder();
            self.lblType.text = decodedData?.dataSourceName;
        }
    }
    
    func didDiscoverDevice(_ device: String, fromDeviceManager deviceManager: CaptureHelperDeviceManager){
        let data  = device.data(using: .utf8)
        let deviceInfo = try! PropertyListSerialization.propertyList(from:data!, options: [], format: nil) as! [String:Any]
        print("device discover: \(deviceInfo)")
        deviceManager.setFavoriteDevices(deviceInfo["identifierUUID"] as! String) { (result) in
            print("setting the favorite devices returns: \(result.rawValue)")
        }
        
        haveScanner = true;
        self.scanner?.stopScanning();
        
    }
    





    
    
}
