//
//  ViewController.swift
//  CloudDemo
//
//  Created by Gabriel Theodoropoulos on 9/4/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit
import CloudKit

class ListNotesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, EditNoteViewControllerDelegate {

    @IBOutlet weak var tblNotes: UITableView!
    
    var arrNotes: Array<CKRecord> = []
    var selectedNoteIndex: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tblNotes.delegate = self
        tblNotes.dataSource = self
        tblNotes.hidden = true
        fetchNotes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: UITableView method implementation
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrNotes.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("idCellNote", forIndexPath: indexPath) as! UITableViewCell
        
        let noteRecord: CKRecord = arrNotes[indexPath.row]
        
        cell.textLabel?.text = noteRecord.valueForKey("noteTitle") as? String
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy, hh:mm"
        cell.detailTextLabel?.text = dateFormatter.stringFromDate(noteRecord.valueForKey("noteEditedDate") as! NSDate)
        
        let imageAsset: CKAsset = noteRecord.valueForKey("noteImage") as! CKAsset
        cell.imageView?.image = UIImage(contentsOfFile: imageAsset.fileURL.path!)
        cell.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedNoteIndex = indexPath.row
        performSegueWithIdentifier("idSegueEditNote", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "idSegueEditNote" {
            let editNoteViewController = segue.destinationViewController as! EditNoteViewController
            editNoteViewController.delegate = self
            if let index = selectedNoteIndex {
                editNoteViewController.editedNoteRecord = arrNotes[index]
            }
        }
    }
    
    func fetchNotes() {
        let container = CKContainer.defaultContainer()
        let privateDatabase = container.privateCloudDatabase
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "Notes", predicate: predicate)
        privateDatabase.performQuery(query, inZoneWithID: nil) { (results, error) -> Void in
            if error != nil {
                println(error)
            }
            else {
                println(results)
                
                for result in results {
                    self.arrNotes.append(result as! CKRecord)
                }
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.tblNotes.reloadData()
                    self.tblNotes.hidden = false
                })
            }
        }
    }
    
    func didSaveNote(noteRecord: CKRecord, wasEditingNote: Bool) {
        if !wasEditingNote {
            arrNotes.append(noteRecord)
        }
        else {
            arrNotes.insert(noteRecord, atIndex: selectedNoteIndex)
            arrNotes.removeAtIndex(selectedNoteIndex + 1)
            selectedNoteIndex = nil
        }
        
        
        if tblNotes.hidden {
            tblNotes.hidden = false
        }
        
        tblNotes.reloadData()
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let selectedRecordID = arrNotes[indexPath.row].recordID
            
            let container = CKContainer.defaultContainer()
            let privateDatabase = container.privateCloudDatabase
            
            privateDatabase.deleteRecordWithID(selectedRecordID, completionHandler: { (recordID, error) -> Void in
                if error != nil {
                    println(error)
                }
                else {
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.arrNotes.removeAtIndex(indexPath.row)
                        self.tblNotes.reloadData()
                    })
                }
            })
        }
    }
}

