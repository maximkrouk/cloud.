//
//  DropView.swift
//  mxCloudFS-client
//
//  Created by Maxim on 3/26/19.
//  Copyright © 2019 id.mxCat. All rights reserved.
//
import Cocoa

class DropView: NSVisualEffectView {
    
    var filePaths = [String]()
    var expectedExt = [String]()  //file extensions allowed for Drag&Drop (example: "jpg","png","docx", etc..)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.wantsLayer = true
        
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "DropViewDraggingEntered"), object: self))
        
        if checkExtension(sender) == true {
            return .copy
        } else {
            return NSDragOperation()
        }
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "DropViewDraggingExited"), object: self))
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "DropViewDraggingEnded"), object: self))
    }
    
    fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
        guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
            let path = board[0] as? String
            else { return false }
        
        if self.expectedExt.count == 0 {
            return true
        }
        
        let suffix = URL(fileURLWithPath: path).pathExtension
        for ext in self.expectedExt {
            if ext.lowercased() == suffix {
                return true
            }
        }
        return false
    }
    
    
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let paths = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? [String] else { return false }
        
        self.filePaths = paths
        
        return true
    }
}
