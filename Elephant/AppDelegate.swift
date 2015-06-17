//
//  AppDelegate.swift
//  Elephant
//
//  Created by Thomas Brichart on 08/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//


import Cocoa
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : String, type: String) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            
            let scene: SKScene!
            
            if type == "Edit" {
                scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! EditScene
            } else {
                scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            }
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: ElWindow!
    @IBOutlet weak var skView: ElView!
    
    var mainScene: GameScene!
    var editScene: EditScene!
    
    var editModeEnabled: Bool = false
    var transparenceEnabled: Bool = false
    
    @IBAction func openButtonClicked(sender: AnyObject) {
        var openPanel: NSOpenPanel = NSOpenPanel()
        openPanel.prompt = "Ouvrir"
        openPanel.worksWhenModal = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.resolvesAliases = true
        openPanel.title = "Ouvrir"
        openPanel.message = "Ouvrir un fichier chanson"
        openPanel.allowedFileTypes = ["txt"]
        
        openPanel.runModal()
        
        if let chosenFile = openPanel.URL {
            
            mainScene.notes = Utils.notesFromFile(chosenFile.absoluteURL!)
            mainScene.endTime = Utils.getMaxKey(self.mainScene.notes)
            mainScene.endTime += 2 * UIConfig.realNoteDuration * Double(UIConfig.expectedFPS)
        
            editScene.notes = Utils.notesFromFile(chosenFile.absoluteURL!)
            editScene.loadNotes()
        }
    }
    
    @IBOutlet weak var editModeMenu: NSMenuItem!
    
    @IBAction func editModeClicked(sender: AnyObject) {
        editModeEnabled = !editModeEnabled
        saveButton.enabled = editModeEnabled
        
        if editModeEnabled {
            self.skView!.presentScene(editScene, transition: SKTransition.doorwayWithDuration(1))
        } else {
            self.skView!.presentScene(mainScene, transition: SKTransition.doorwayWithDuration(1))
        }
    }
    
    @IBOutlet weak var saveButton: NSMenuItem!
    
    @IBAction func saveButtonClicked(sender: AnyObject) {
        var savePanel: NSSavePanel = NSSavePanel()
        savePanel.prompt = "Enregistrer"
        savePanel.worksWhenModal = true
        savePanel.allowedFileTypes = ["txt"]
        savePanel.message = "Choisir l'emplacement pour sauver les données"
        savePanel.canCreateDirectories = true
        
        savePanel.runModal()
        
        if let chosenPath = savePanel.URL {
            Utils.saveFileFromNotes(chosenPath, notes: editScene.notes)
        }
    }
    
    @IBOutlet weak var transparenceButton: NSMenuItem!
    
    @IBAction func transparenceButtonClicked(sender: AnyObject) {
        transparenceEnabled = !transparenceEnabled
        
        if transparenceEnabled {
            mainScene.backgroundColor = NSColor.clearColor()
            transparenceButton.title = "Deactivate transparence"
        } else {
            mainScene.backgroundColor = NSColor.grayColor()
            transparenceButton.title = "Activate transparence"
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        /* Pick a size for the scene */
        if let scene = GameScene.unarchiveFromFile("GameScene", type: "Main") as? GameScene {
            /* Set the scale mode to scale to fit the window */
            
            mainScene = scene
            mainScene.scaleMode = .AspectFill
            
            self.skView!.presentScene(mainScene)
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            self.skView!.ignoresSiblingOrder = true
            
            #if DEBUG
            self.skView!.showsFPS = true
            self.skView!.showsNodeCount = true
            #endif
            
            self.skView!.allowsTransparency = true
            
            self.window.backgroundColor = NSColor.clearColor()
            self.window.opaque = false
        }
        
        if let scene = EditScene.unarchiveFromFile("GameScene", type: "Edit") as? EditScene {
            editScene = scene
            editScene.scaleMode = .AspectFill
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}
