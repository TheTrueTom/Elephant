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
    }
    
    // MARK: - FRAME UPDATE
    
    override func update(currentTime: CFTimeInterval) {
        
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
                            
                            note.colorBlendFactor = 0
                            
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
                            note.colorBlendFactor = UIConfig.songItemColorBlendingFactor
                        }
                    }
                }
            }
        }
        
        if !scene!.paused && ((gameTime > 0 && speed < 0) || (gameTime < (Int(endTime) - 100) && speed > 0)) {
            gameTime += Int(round(speed * 10))
        }
        
        timerLabel.text = "\(gameTime) / \(Int(endTime))"
    }
    
    // MARK: - USER INPUT
    
    // MARK: Mouse
    
    override func mouseDown(theEvent: NSEvent) {
        var windowFrame = self.view!.window!.frame
        
        initialLocation = NSEvent.mouseLocation()
        println(theEvent.locationInNode(world))
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
                songItem.colorBlendFactor = UIConfig.songItemColorBlendingFactor
                songItem.removeAllActions()
                songItem.removeFromParent()
            }
        }
    }
    
    // MARK: - SIMULATION SETUP
    
    /**
    Setup the labels of game speed and game time used for debugging
    */
    
    func resetView() {
        // Cleaning
        scene?.removeAllActions()
        scene?.removeAllChildren()
        
        // Store screen size
        UIConfig.setScreenSize(self.scene!.size)
        
        // World setup
        world = SKNode()
        self.addChild(world)
        
        // Cleaning
        world.removeAllChildren()
        world.removeAllActions()
        
        speed = 0
        
        reset()
        
        setupTracks()
        
        setupDebug()
    }
    
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
        let background = SKSpriteNode(imageNamed: "background")
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
        if index < preloadedNotes.count - 1 {
            reset()
        
            notes = preloadedNotes[index]
        
            endTime = Utils.getMaxKey(notes)
            endTime += 2 * UIConfig.noteDuration * Double(UIConfig.expectedFPS)
            prepareNotes()
        }
    }
}
