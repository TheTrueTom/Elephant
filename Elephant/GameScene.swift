//
//  GameScene.swift
//  Elephant
//
//  Created by Thomas Brichart on 08/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import SpriteKit

var UIConfig = UIPreferences()
var tracks: [Track] = []

class GameScene: SKScene {
    
    // MARK: - PROPERTIES
    let loadKeyCodes: [UInt16] = [50, 6, 7, 8, 9, 11, 45, 46, 43, 47, 44]
    
    var preloadedNotes: [[Int: [String: [ElNote]]]] = []
    
    // Nodes
    var world: SKNode!
    var notes: Dictionary<Int, Dictionary<String, Array<ElNote>>> = [:] {
        willSet {
            self.speed = 1
            speedLabel.text = "Speed: " + String(format: "%.1f", scene!.speed)
            self.paused = true
        }
    }
    
    var markers: [ElMarker] = []
    
    // Sounds
    var sounds: [String: SKAction] = [:]
    
    // Simulation timer
    var gameTime: Int = 0
    var endTime: Double = 1 {
        didSet {
            println("New endTime set: \(endTime)")
        }
    }
    
    // Debug labels
    var speedLabel: SKLabelNode!
    var timerLabel: SKLabelNode!
    
    /** Initial location for window dragging set on mouseDown*/
    var initialLocation: NSPoint!
    
    var gameTimer: NSTimer!
    
    var usedBackgroundName: String = "background"
    
    var background: SKSpriteNode!
    
    // MARK: - LIFE CYCLE
    
    override func didMoveToView(view: SKView) {
        
        // Cleaning
        scene?.removeAllActions()
        scene?.removeAllChildren()
        
        //self.scene!.size = view.frame.size
        
        // Store screen size
        UIConfig.setScreenSize(self.scene!.size)
        
        println(UIConfig.screenSize)
        
        // World setup
        world = SKNode()
        self.addChild(world)
        
        // Cleaning
        world.removeAllChildren()
        world.removeAllActions()
        
        self.paused = true
        
        reset()
        
        setupBackground()
        setupTracks()
        
        setupDebug()
        
        gameTimer = NSTimer.scheduledTimerWithTimeInterval(1/UIConfig.expectedFPS, target: self, selector: "firedGameTimer", userInfo: nil, repeats: true)
        
        var midi = SwiftMIDI()
        // call this without the param and it will print to stdout
        midi.initMIDI(reader: myPacketReadCallback)
    }
    
    var previousTimeStamp = MIDITimeStamp(0)
    
    func myPacketReadCallback(ts:MIDITimeStamp, data:UnsafePointer<UInt8>, len:UInt16) {
        let status = data[0]
        let rawStatus = data[0] & 0xF0 // without channel
        var delta = MIDITimeStamp(0)
        
        if self.previousTimeStamp != 0 {
            delta = ts - self.previousTimeStamp
        }
        /*
        if status < 0xF0 {
            var channel = status & 0x0F
            
            switch rawStatus {
                
            case 0x80:
                
                dispatch_async(dispatch_get_main_queue(), {
                    println("Note off. Channel \(channel) note \(data[1]) velocity \(data[2])\n")
                })
                
            case 0x90:
                
                dispatch_async(dispatch_get_main_queue(), {
                    println("Note on. Channel \(channel) note \(data[1]) velocity \(data[2])\n")
                })
                
            case 0xA0:
                println("Polyphonic Key Pressure (Aftertouch). Channel \(channel) note \(data[1]) pressure \(data[2])")
                dispatch_async(dispatch_get_main_queue(), {
                    println("Note on. Channel \(channel) note \(data[1]) velocity \(data[2])\n")
                })
            case 0xB0:
                
                dispatch_async(dispatch_get_main_queue(), {
                    println("Control Change. Channel \(channel) controller \(data[1]) value \(data[2])\n")
                })
                
            case 0xC0:
                dispatch_async(dispatch_get_main_queue(), {
                    println("Program Change. Channel \(channel) program \(data[1])\n")
                })
            case 0xD0:
                
                dispatch_async(dispatch_get_main_queue(), {
                    println("Channel Pressure (Aftertouch). Channel \(channel) pressure \(data[1])\n")
                    
                })
            case 0xE0:
                
                dispatch_async(dispatch_get_main_queue(), {
                    println("Pitch Bend Change. Channel \(channel) lsb \(data[1]) msb \(data[2])\n")
                    
                })
            case 0xFE:
                
                dispatch_async(dispatch_get_main_queue(), {
                    println("active sensing")
                })
                
            default:
                let hex = String(status, radix: 16, uppercase: true)
                println("Unhandled message \(status) \(hex)")
            }
        }*/
        
        if status >= 0xF0 {
            switch status {
            /*case 0xF0:
                println("Sysex")
            case 0xF1:
                println("MIDI Time Code")
            case 0xF2:
                println("Song Position Pointer")
            case 0xF3:
                println("Song Select")
            case 0xF4:
                println("Reserved")
            case 0xF5:
                println("Reserved")
            case 0xF6:
                println("Tune request")
            case 0xF7:
                println("End of SysEx")
            case 0xF8:
                println("Timing clock")
            case 0xF9:
                println("Reserved")*/
            case 0xFA:
                println("Start")
                scene?.paused = false
            case 0xFB:
                println("Continue")
                scene?.paused = false
            case 0xFC:
                println("Stop")
                scene?.paused = true
            case 0xFD:
                println("Start")
                scene?.paused = false
            default: break
                
            }
        }
    }
    
    func switchBackground() {
        usedBackgroundName = (usedBackgroundName == "background") ? "background_alt" : "background"
        background.texture = SKTexture(imageNamed: usedBackgroundName)
    }
    
    func firedGameTimer() {
        if speed > 0 {
            for i in 0 ..< Int(round(speed * 10)) {
                
                if let notesDic = notes[gameTime + i] {
                    if let notesToAppear = notesDic["appear"] {
                        for note in notesToAppear {
                            if note.parent == nil {
                                world.addChild(note)
                                note.resetToStart()
                                note.animate(endTime)
                            }
                        }
                    }
                    
                    if let notesToPlay = notesDic["play"] where speed > 0 {
                        for note in notesToPlay {
                            var trackIndex: Int!
                            
                            switch note.trackPosition {
                            case .FarLeft:
                                trackIndex = 0
                            case .CenterLeft:
                                trackIndex = 1
                            case .CenterRight:
                                trackIndex = 2
                            case .FarRight:
                                trackIndex = 3
                            default:
                                fatalError("Wrong track called in game update")
                            }
                            
                            note.fireEmitter()
                            
                            note.runAction(note.soundAction)
                            
                            note.fadeAlpha()
                        }
                    }
                }
            }
        }
        
        if speed < 0 {
            for i in 0 ..< Int(-round(speed * 10)) {
                if let notesDic = notes[gameTime - i] {
                    
                    if let notesToDisAppear = notesDic["appear"] {
                        for note in notesToDisAppear {
                            note.resetToStart()
                            note.removeAllActions()
                            note.removeFromParent()
                        }
                    }
                    
                    if let notesToRecolor = notesDic["play"] {
                        for note in notesToRecolor {
                            note.alpha = 1
                            note.colorize()
                            note.removeActionForKey("yoloDownAction")
                            note.size = UIConfig.noteEndSize
                            note.removeActionForKey("alphaAction")
                        }
                    }
                }
                
                if let notesDic = notes[gameTime - 1000 - i] {
                    if let notesToReAppear = notesDic["play"] {
                        for note in notesToReAppear {
                            note.startReappearance()
                        }
                    }
                }
            }
        }
        
        if !scene!.paused && ((gameTime > 0 && speed < 0) || (gameTime < (Int(endTime) - 100) && speed > 0)) {
            gameTime += Int(round(speed * 10))
        }
    }
    
    // MARK: - FRAME UPDATE
    
    override func update(currentTime: CFTimeInterval) {
        timerLabel.text = "\(gameTime) / \(Int(endTime))"
    }
    
    // MARK: - USER INPUT
    
    // MARK: Mouse
    
    override func mouseDown(theEvent: NSEvent) {
        var windowFrame = self.view!.window!.frame
        
        initialLocation = NSEvent.mouseLocation()
        
        initialLocation.x -= windowFrame.origin.x
        initialLocation.y -= windowFrame.origin.y
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        var screenFrame = NSScreen.mainScreen()!.frame
        var windowFrame = self.view!.window!.frame
        
        var currentLocation = NSEvent.mouseLocation()
        
        var newOrigin: NSPoint = NSPoint(x: 0, y: 0)
        
        newOrigin.x = currentLocation.x - initialLocation.x
        newOrigin.y = currentLocation.y - initialLocation.y
        
        self.view!.window!.setFrameOrigin(newOrigin)
    }
    
    // MARK: Keyboard
    
    override func keyDown(theEvent: NSEvent) {
        var keyCode = theEvent.keyCode
        switch keyCode {
        case 125: // Down
            scene?.speed -= 0.1
        case 126: // Up
            scene?.speed += 0.1
        case 49: // Space
            togglePlayPause()
        case 15: // R
            reset()
        case 50, 6, 7, 8, 9, 11, 45, 46, 43, 47, 44:
            for (index, value) in enumerate(loadKeyCodes) {
                if value == keyCode {
                    loadNotes(index)
                    break
                }
            }
        default:
            break
        }
        
        speedLabel.text = "Speed: " + String(format: "%.1f", scene!.speed)
    }
    
    // MARK: - SIMULATION HANDLING
    
    /**
    Reset the song:
    
    1. Game time is set to zero (0)
    2. All notes are removed from the partition
    3. Speed is set to zero (0)
    */
    
    func togglePlayPause() {
        self.paused = !self.paused
    }
    
    func reset() {
        scene?.paused = true
        gameTime = 0
        
        for node in world.children {
            if node.isKindOfClass(ElNote) {
                var songItem = node as! ElNote
                
                songItem.alpha = 1
                songItem.colorize()
                songItem.removeAllActions()
                songItem.removeFromParent()
            }
        }
    }
    
    // MARK: - SIMULATION SETUP
    
    func setupDebug() {
        timerLabel = SKLabelNode(text: "\(gameTime)")
        timerLabel.horizontalAlignmentMode = .Left
        timerLabel.position = CGPointMake(0, 0)
        timerLabel.text = "0"
        timerLabel.zPosition = 1000
        scene?.addChild(timerLabel)
        
        speedLabel = SKLabelNode(text: "Speed: \(scene!.speed)")
        speedLabel.horizontalAlignmentMode = .Left
        speedLabel.verticalAlignmentMode = .Bottom
        speedLabel.position = CGPointMake(0, scene!.frame.height - speedLabel.frame.size.height)
        speedLabel.text = "Speed: " + String(format: "%.1f", scene!.speed)
        speedLabel.zPosition = 1000
        scene?.addChild(speedLabel)
    }
    
    func setupBackground() {
        background = SKSpriteNode(imageNamed: "background")
        background.anchorPoint = CGPointZero
        background.position = CGPointZero
        background.zPosition = 1
        world.addChild(background)
    }
    
    /** 
    Setup the vertical lines
    */
    
    func setupTracks() {
        tracks.removeAll(keepCapacity: false)
        
        tracks.append(Track(position: .FarLeft))
        tracks.append(Track(position: .CenterLeft))
        tracks.append(Track(position: .CenterRight))
        tracks.append(Track(position: .FarRight))
    }
    
    /** 
    Setup the four markers on the baseline
    */
    
    func prepareNotes() {
        for (key, dic) in self.notes {
            for (subKey, noteList) in dic {
                for note in noteList {
                    note.prepareForAnimation(endTime)
                }
            }
        }
    }
    
    func loadNotes(index: Int) {
        if index < preloadedNotes.count {
            reset()
            
            println("Loading notes at index \(index)")
            
            notes = preloadedNotes[index]
        
            endTime = Utils.getMaxKey(notes) + 2 * UIConfig.noteDuration * Double(UIConfig.expectedFPS)
            prepareNotes()
        }
    }
}
