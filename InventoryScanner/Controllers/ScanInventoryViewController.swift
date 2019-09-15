//
//  ScanInventoryViewController.swift
//  Inventory Scanner
//
//  Created by Ernie Dipko 2019.09.12
//
//

import UIKit
import MTBBarcodeScanner


class ScanInventoryViewController: UIViewController, UITextFieldDelegate {
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanner = MTBBarcodeScanner(previewView: previewView)
        
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        fileUrl = documentDirectoryUrl.appendingPathComponent(appDelegate.filename!)
        
        self.txtBarCode.delegate = self;
        self.txtBarCode.inputView = UIView();
        
        self.txtQuantity.delegate = self;
        self.txtQuantity.keyboardType = .decimalPad;
        self.txtNotes.delegate = self;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.startScanning();

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
                                        if (itemArr.count > 0) {
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
        
        let output = "\(self.txtBarCode.text ?? "")|\(self.txtQuantity.text ?? "")|\(self.txtNotes.text ?? "")";
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
        
        self.startScanning();
        
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
        
        self.startScanning();
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
    
    
    
}
