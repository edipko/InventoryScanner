//
//  InventoryScannerViewController.swift
//  Inventory Scanner
//
//  Created by Ernie Dipko on 9/14/19.
//

import Foundation
import UIKit
import Toast_Swift


class MenuViewController: UITableViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var fileUrl = URL(string: "");
    
    @IBOutlet weak var lblViewInventory: UILabel!
    @IBOutlet weak var lblLoadData: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        fileUrl = documentDirectoryUrl.appendingPathComponent(appDelegate.filename!)
        
        // Hide the load data - we don't need it now
        lblLoadData.isHidden = true
        
        // Load the existing datafile if it exists
        self.loadData()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        self.lblViewInventory.text = "View Inventory (\(self.appDelegate.inventory.count))"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 2:
            self.saveToiCloud()
        case 3:
           // self.loadData()
            //self.view.makeToast("Data Loaded")
            print("Taking no action");
        case 4:
            let alert = UIAlertController(title: "Type 'Delete Data' if you are sure:", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            alert.addTextField(configurationHandler: { textField in
                textField.placeholder = "Delete Data"
            })
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
                if let code = alert.textFields?.first?.text {
                    if code == "Delete Data" {
                        print("Deleting data");
                        self.appDelegate.clearInventory()
                        self.saveData()
                        self.loadData()
                        self.view.makeToast("Data Cleared", duration: 3.0, position: .bottom)
                    } else {
                        print("Not Deleting data");
                    }
                }
            }))
            
            self.present(alert, animated: true)
        default:
            print("Taking no action");
        }
    }
    
    func loadData() {
        do {
            if fileUrl?.path != nil {
                let data = try String(contentsOfFile: fileUrl!.path, encoding: .utf8)
                let line = data.components(separatedBy: .newlines)
                for l in line {
                    if l.count > 0 {
                        self.appDelegate.inventory.add(l)
                    }
                }
                self.view.makeToast("Previous session loaded", duration: 2.0, position: .center)
                self.lblViewInventory.text = "View Inventory (\(self.appDelegate.inventory.count))"
            }
        } catch {
            print(error)
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
        } catch {
            print(error)
        }
        
    }
    
    
    @IBAction func saveToiCloud() {
        
       // let activityController = (UIActivityViewController(activityItems: [fileUrl!], applicationActivities: nil));
       //     present(activityController, animated: true, completion: nil);
        
        let activityViewController = UIActivityViewController(activityItems: [fileUrl!], applicationActivities: nil)
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            popoverController.sourceView = self.view
            popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        }
        
        self.present(activityViewController, animated: true, completion: nil)
        
        
        
    }
}
