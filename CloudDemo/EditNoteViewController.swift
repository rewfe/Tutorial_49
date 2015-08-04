//
//  EditNoteViewController.swift
//  CloudDemo
//
//  Created by Gabriel Theodoropoulos on 9/4/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit
import QuartzCore
import CloudKit

protocol EditNoteViewControllerDelegate {
    func didSaveNote(noteRecord: CKRecord, wasEditingNote: Bool)
}


class EditNoteViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{

    @IBOutlet weak var txtNoteTitle: UITextField!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var btnSelectPhoto: UIButton!
    
    @IBOutlet weak var btnRemoveImage: UIButton!
    
    @IBOutlet weak var viewWait: UIView!
    
    var imageURL: NSURL!
    var editedNoteRecord: CKRecord!
    
    let documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
    let tempImageName = "temp_image.jpg"
    
    var delegate: EditNoteViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        imageView.hidden = true
        btnRemoveImage.hidden = true
        viewWait.hidden = true
        
        let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipeDownGestureRecognizer:")
        swipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Down
        view.addGestureRecognizer(swipeDownGestureRecognizer)
        if let editedNote = editedNoteRecord {
            txtNoteTitle.text = editedNote.valueForKey("noteTitle") as! String
            textView.text = editedNote.valueForKey("noteText") as! String
            let imageAsset: CKAsset = editedNote.valueForKey("noteImage") as! CKAsset
            imageView.image = UIImage(contentsOfFile: imageAsset.fileURL.path!)
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            
            imageURL = imageAsset.fileURL
            
            imageView.hidden = false
            btnRemoveImage.hidden = false
            btnSelectPhoto.hidden = true
        }
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        textView.layer.cornerRadius = 10.0
        btnSelectPhoto.layer.cornerRadius = 5.0
        btnRemoveImage.layer.cornerRadius = btnRemoveImage.frame.size.width/2
        
        navigationItem.setHidesBackButton(true, animated: false)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: IBAction method implementation
    
    @IBAction func pickPhoto(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.allowsEditing = false
            presentViewController(imagePicker, animated: true, completion: nil)
        }
    
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        imageView.contentMode = UIViewContentMode.ScaleAspectFit
        
        saveImageLocally()
        
        imageView.hidden = false
        btnRemoveImage.hidden = false
        btnSelectPhoto.hidden = true
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func saveImageLocally() {
        let imageData: NSData = UIImageJPEGRepresentation(imageView.image, 0.8)
        let path = documentsDirectoryPath.stringByAppendingPathComponent(tempImageName)
        imageURL = NSURL(fileURLWithPath: path)
        imageData.writeToURL(imageURL, atomically: true)
    }
    
    @IBAction func unsetImage(sender: AnyObject) {
        imageView.image = nil
        
        imageView.hidden = true
        btnRemoveImage.hidden = true
        btnSelectPhoto.hidden = false
        
        imageURL = nil
    
    }
    
    
    @IBAction func saveNote(sender: AnyObject) {
        if txtNoteTitle.text == "" || textView.text == "" {
            return
        }
        
        viewWait.hidden = false
        view.bringSubviewToFront(viewWait)
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        var noteRecord: CKRecord!
        var isEditingNote: Bool!
        
        if let editedNote = editedNoteRecord {
            noteRecord = editedNote
            isEditingNote = true
        }
        else {
            let timestampAsString = String(format: "%f", NSDate.timeIntervalSinceReferenceDate())
            let timestampParts = timestampAsString.componentsSeparatedByString(".")
            let noteID = CKRecordID(recordName: timestampParts[0])
            
            noteRecord = CKRecord(recordType: "Notes", recordID: noteID)
            
            isEditingNote = false
        }
        
        noteRecord.setObject(txtNoteTitle.text, forKey: "noteTitle")
        noteRecord.setObject(textView.text, forKey: "noteText")
        noteRecord.setObject(NSDate(), forKey: "noteEditedDate")
        
        if let url = imageURL {
            let imageAsset = CKAsset(fileURL: url)
            noteRecord.setObject(imageAsset, forKey: "noteImage")
        }
        else {
            let fileURL = NSBundle.mainBundle().URLForResource("no_image", withExtension: "png")
            let imageAsset = CKAsset(fileURL: fileURL)
            noteRecord.setObject(imageAsset, forKey: "noteImage")
        }
        
        let container = CKContainer.defaultContainer()
        let privateDatabase = container.privateCloudDatabase
        
        privateDatabase.saveRecord(noteRecord, completionHandler: { (record, error) -> Void in
            if (error != nil) {
                println(error)
            }
            else {
                self.delegate.didSaveNote(noteRecord, wasEditingNote: isEditingNote)
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.viewWait.hidden = true
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            })
        })

    
    }
    
    
    @IBAction func dismiss(sender: AnyObject) {
        if let url = imageURL {
            let fileManager = NSFileManager()
            if fileManager.fileExistsAtPath(url.absoluteString!) {
                fileManager.removeItemAtURL(url, error: nil)
            }
        }
        
        navigationController?.popViewControllerAnimated(true)
    
    }
    
    
    // MARK: Custom method implementation
    
    func handleSwipeDownGestureRecognizer(swipeGestureRecognizer: UISwipeGestureRecognizer) {
        txtNoteTitle.resignFirstResponder()
        textView.resignFirstResponder()
    }
    
}
