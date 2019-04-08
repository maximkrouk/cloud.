//
//  SendFileViewController.swift
//  cloud.osx
//
//  Created by Maxim on 4/8/19.
//  Copyright © 2019 mxCat. All rights reserved.
//

import Cocoa

class SendFileViewController: NSViewController {
    
    var file: FileInfo!

    @IBOutlet weak var destinationUserIdTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func send(_ sender: Any) {
        guard let uuid = UUID(uuidString: destinationUserIdTextField.stringValue) else { return }
        Cloud.send(using: FileTransfer(fileID: file.id, userID: uuid), completion: nil)
        dismiss(self)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(self)
    }
}
