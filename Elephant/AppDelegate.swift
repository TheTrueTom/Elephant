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
            
            scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            
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
    
    @IBOutlet weak var speedLabel: NSTextField!
    @IBOutlet weak var trackIndexLabel: NSTextField!
    @IBOutlet weak var nbLoadedFilesLabel: NSTextField!
    @IBOutlet weak var loadedFileNameLabel: NSTextField!
    @IBOutlet weak var positionLabel: NSTextField!
    @IBOutlet weak var flippedLabel: NSTextField!
    @IBOutlet weak var pausedLabel: NSTextField!
    @IBOutlet weak var midiOnLabel: NSTextField!
    
    var mainScene: GameScene!
    
    var editModeEnabled: Bool = false
    var transparenceEnabled: Bool = false
    
    @IBAction func switchBackground(sender: AnyObject) {
        mainScene.switchBackground()
    }
    
    @IBAction func openButtonClicked(sender: AnyObject) {
        var openPanel: NSOpenPanel = NSOpenPanel()
        openPanel.prompt = "Ouvrir"
        openPanel.worksWhenModal = true
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = true
        openPanel.resolvesAliases = true
        openPanel.title = "Ouvrir"
        openPanel.message = "Ouvrir un fichier chanson"
        openPanel.allowedFileTypes = ["mid"]
        
        openPanel.runModal()
        
        if let folderPath = openPanel.URL {
            var enumerator = NSFileManager.defaultManager().enumeratorAtURL(folderPath, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles | NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants, errorHandler: nil)
            
            var i = 0
            
            mainScene.preloadedNotes.removeAll(keepCapacity: false)
            
            var fileList: [NSURL] = []
            
            while let file = enumerator?.nextObject() as? NSURL {
                if i < 11 && file.pathExtension == "mid" {
                    fileList.append(file)
                    i++
                }
            }
            
            for url in fileList {
                var tuple = MidiFile.readMidiFile(url)
                mainScene.preloadedNotes.append(tuple.0)
                mainScene.preloadedFlippedNotes.append(tuple.1)
                mainScene.fileNames.append("\(url.lastPathComponent!)")
            }
            
            if !mainScene.preloadedNotes.isEmpty {
                mainScene.loadNotes()
            }
            
            nbLoadedFilesLabel.stringValue = "\(mainScene.preloadedNotes.count)"
            
            println("\(mainScene.preloadedNotes.count) pistes chargées")
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
            
            self.skView!.showsFPS = true
            self.skView!.showsNodeCount = false
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}
