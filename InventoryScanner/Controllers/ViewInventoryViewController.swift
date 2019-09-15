//
//  ViewInventoryViewController.swift
//  Inventory Scanner
//
//  Created by Ernie Dipko on 9/14/19.
//

import Foundation
import UIKit
import Toast_Swift


class ViewInventoryViewController: UITableViewController {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var fileUrl = URL(string: "");

    override func viewDidLoad() {
        super.viewDidLoad()
       
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        fileUrl = documentDirectoryUrl.appendingPathComponent(appDelegate.filename!)
        
        
        for inv in appDelegate.inventory {
            print("Item: \(inv)");
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appDelegate.inventory.count;
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customcell", for: indexPath as IndexPath)
        cell.textLabel?.text = appDelegate.inventory[indexPath.item] as? String
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12.0)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true;
    }
    
  
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // delete item at indexPath
            self.appDelegate.inventory.removeObject(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            tableView.reloadData()
            self.saveData()
        }

        delete.backgroundColor = UIColor.blue
        return [delete]
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
            self.view.makeToast("Data Saved", duration: 3.0, position: .center)
            
        } catch {
            print(error)
        }
    }
    
}

