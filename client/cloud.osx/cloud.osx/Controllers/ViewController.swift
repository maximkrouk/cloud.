//
//  ViewController.swift
//  cloud.osx
//
//  Created by Maxim on 4/3/19.
//  Copyright © 2019 mxCat. All rights reserved.
//

import Cocoa
import Alamofire

// MARK: - Init
class ViewController: NSViewController {
    
    var fileList: FileList = FileList(files: [FileInfo]()) {
        didSet {
            tableView.reloadData()
        }
    }
    
    let contextMenu = NSMenu(title: "Menu")
    
    @IBOutlet var dropView: DropView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var dropTitleLabel: NSTextField!
    @IBOutlet weak var dropDetailLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Cloud.login()
        
        loadFileList()
        setupTableView()
        setupObservers()
    }
    
    @IBAction func refreshButtonClick(_ sender: Any) {
        loadFileList()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "DropViewDraggingEntered"), object: dropView)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "DropViewDraggingExited"), object: dropView)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "DropViewDraggingEnded"), object: dropView)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "UserDidAuthenticated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "UserDidDeauthenticated"), object: nil)
    }
}

// MARK: - Setup
extension ViewController {
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.menu = contextMenu
        tableView.doubleAction = #selector(handleTableViewDoubleAction(_:))
        
        setupMenu()
    }
    
    private func setupMenu() {
        var menuItems: [NSMenuItem] = [NSMenuItem]()
        var item: NSMenuItem
        
        item = NSMenuItem(title: "Download", action: #selector(handleDownload), keyEquivalent: "s")
        item.keyEquivalentModifierMask = NSEvent.ModifierFlags.control
        menuItems.append(item)
        
        item = NSMenuItem(title: "Download as", action: nil, keyEquivalent: "s")
        item.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: NSEvent.ModifierFlags.control.rawValue | NSEvent.ModifierFlags.option.rawValue)
        menuItems.append(item)
        
        item = NSMenuItem(title: "Copy", action: nil, keyEquivalent: "c")
        item.keyEquivalentModifierMask = NSEvent.ModifierFlags.control
        menuItems.append(item)
        
        item = NSMenuItem(title: "Send", action: nil, keyEquivalent: "s")
        item.keyEquivalentModifierMask = NSEvent.ModifierFlags.option
        menuItems.append(item)
        
        item = NSMenuItem(title: "Duplicate", action: nil, keyEquivalent: "d")
        item.keyEquivalentModifierMask = NSEvent.ModifierFlags.control
        menuItems.append(item)
        
        item = NSMenuItem(title: "Delete", action: #selector(handleDelete), keyEquivalent: "d")
        item.keyEquivalentModifierMask = NSEvent.ModifierFlags.option
        menuItems.append(item)
        
        for item in menuItems {
            contextMenu.addItem(item)
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDraggingBegun),
                                               name: Notification.Name(rawValue: "DropViewDraggingEntered"),
                                               object: dropView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDraggingCanceled),
                                               name: Notification.Name(rawValue: "DropViewDraggingExited"),
                                               object: dropView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDraggingDone),
                                               name: Notification.Name(rawValue: "DropViewDraggingEnded"),
                                               object: dropView)
        NotificationCenter.default.addObserver(self, selector: #selector(loadFileList),
                                               name: Notification.Name(rawValue: "UserDidAuthenticated"),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadFileList),
                                               name: Notification.Name(rawValue: "UserDidDeauthenticated"),
                                               object: nil)
    }
    
}

// MARK: - NSTableViewDataSource
extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileList.files.count
    }
    
}

// MARK: - NSTableViewDelegate
extension ViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCellID"
        static let SizeCell = "SizeCellID"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        
        let item = fileList.files[row]
        
        if tableColumn == tableView.tableColumns[0] {
            //image = item.icon
            text = item.name
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = "\(item.size) bytes"
            cellIdentifier = CellIdentifiers.SizeCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image
            return cell
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, shouldShowCellExpansionFor tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print(tableView.selectedRow)
    }
    
}

// MARK: - Handlers
extension ViewController {
    
    @objc func loadFileList() {
        Cloud.list { fileList, error in
            if error == nil {
                self.fileList = fileList!
            } else {
                self.fileList = FileList(files: [FileInfo]())
                print(error!)
            }
        }
    }
    
    @objc func handleDraggingBegun() {
        tableView.alphaValue = 0.1
        dropTitleLabel.alphaValue = 1
        dropDetailLabel.alphaValue = 1
    }
    
    @objc func handleDraggingCanceled() {
        tableView.alphaValue = 1
        dropTitleLabel.alphaValue = 0
        dropDetailLabel.alphaValue = 0
    }

    @objc func handleDraggingDone() {
        tableView.alphaValue = 1
        dropTitleLabel.alphaValue = 0
        dropDetailLabel.alphaValue = 0
        print(dropView.filePaths)
        for path in dropView.filePaths {
            Cloud.upload(fileAt: path) { response in
                guard let data = response.data else { return }
                let decoder = JSONDecoder()
                guard let fileInfo = try? decoder.decode(FileInfo.self, from: data) else { return }
                self.fileList.files.append(fileInfo)
            }
        }
    }
    
    @objc func handleDownload() {
        Cloud.download(file: fileList.files[tableView.selectedRow]) { _ in  }
    }
    
    @objc func handleDelete() {
        Cloud.delete(file: fileList.files[tableView.selectedRow]) { error in
            self.loadFileList()
        }
    }
    
    @objc func handleTableViewDoubleAction(_ sender:AnyObject) {
        
        guard tableView.selectedRow >= 0 else { return }
        
        let item = fileList.files[tableView.selectedRow]
        
        print(item)
    }

}
