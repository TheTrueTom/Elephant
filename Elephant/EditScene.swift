//
//  EditScene.swift
//  Elephant
//
//  Created by Thomas Brichart on 13/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation
import SpriteKit

class EditScene: SKScene {
    
    // MARK: - PROPERTIES
    
    var world: SKNode = SKNode()
    
    let pixelsPerFrame: CGFloat = 2
    let maxLength: CGFloat = 10000
    
    var notes: [Int: [ElNote]] = [:]
    
    var isPlaying = false
    
    var tracks: [SKSpriteNode] = []
    
    var timeLabel: SKLabelNode!
    
    var currentNode: ElNote? {
        didSet {
            oldValue?.colorBlendFactor = 0.8
            currentNode?.colorBlendFactor = 0.0
        }
    }
    
    var sounds: [String: SKAction] = [:]
    
    var mouseClickPosition: CGPoint!
    
    var initialLocation: NSPoint!
    
    var playStatusNode: SKSpriteNode!
    
    var currentKeyboardNotes: [UInt16: ElNote] = [:]
    
    // MARK: - LIFE CYCLE
    
    override func didMoveToView(view: SKView) {
        
        // Cleaning
        scene?.removeAllChildren()
        scene?.removeAllActions()
        
        scene?.size = view.frame.size
        
        world = SKNode()
        
        scene?.addChild(world)
        
        world.removeAllActions()
        world.removeAllChildren()
        
        // Setup
        createTracks()
        
        world.position.x = scene!.size.width/2
        
        timeLabel = SKLabelNode()
        timeLabel.position.x = scene!.size.width/2 + 5
        timeLabel.position.y = scene!.size.height/5 * 4 + 25
        timeLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        
        scene!.addChild(timeLabel)
        
        preloadSounds()
        
        playStatusNode = SKSpriteNode(imageNamed: "pause")
        playStatusNode.anchorPoint = CGPointMake(0, 1)
        playStatusNode.size = CGSizeMake(40, 40)
        playStatusNode.position = CGPointMake(0, scene!.size.height)
        scene?.addChild(playStatusNode)
        
        loadNotes()
    }
    
    // MARK: - USER INTERACTIONS
    
    // MARK: Keyboard
    
    override func keyDown(theEvent: NSEvent) {
        var keyCode = theEvent.keyCode
        
        switch keyCode {
        case 49: // Space
            
            if isPlaying {
                changePlayStatusNode(false)
                world.removeActionForKey("forward")
            } else {
                changePlayStatusNode(true)
                let forward = SKAction.moveByX(-60*pixelsPerFrame, y: 0, duration: 1)
                let repeatForward = SKAction.repeatActionForever(forward)
                
                world.runAction(repeatForward, withKey: "forward")
            }
            
            isPlaying = !isPlaying
        case 15: // R
            reset()
        case 123:
            world.position.x += 50
        case 124:
            world.position.x -= 50
        case 1, 3, 4, 40: // S, F, H, K
            if currentKeyboardNotes[keyCode] == nil {
                newNote(keyCode)
            }
        case 51: // Del
            if currentNode != nil {
                currentNode?.removeFromParent()
                
                var newArray: [ElNote] = []
                for note in notes[Int(currentNode!.appearTime)]! {
                    if note != currentNode {
                        newArray.append(note)
                    }
                }
                
                notes.updateValue(newArray, forKey: Int(currentNode!.appearTime))
                
                currentNode = nil
            }
        default:
            break
        }
    }
    
    override func keyUp(theEvent: NSEvent) {
        var keyCode = theEvent.keyCode
        
        switch keyCode {
        case 1, 3, 4, 40: // S, F, H, K
            if currentKeyboardNotes[keyCode] != nil {
                endNote(keyCode)
            }
        default:
            break
        }
        
    }
    
    // MARK: Mouse
    
    override func mouseDown(theEvent: NSEvent) {
        
        // Window dragging movement
        var windowFrame = self.view!.window!.frame
        
        initialLocation = NSEvent.mouseLocation()
        
        initialLocation.x -= windowFrame.origin.x
        initialLocation.y -= windowFrame.origin.y
        
        // Queue generation
        var clickPosition = theEvent.locationInNode(world)
        
        mouseClickPosition = clickPosition
        
        currentNode = nil
        
        var nodes = world.nodesAtPoint(theEvent.locationInNode(world))
        
        var nodeSelected = false
        
        for node in nodes {
            if node.isKindOfClass(ElNote) {
                nodeSelected = true
                
                currentNode = node as? ElNote
            }
        }
        
        if !nodeSelected {
            
            for i in 0...3 {
                var track = tracks[i]
                
                switch Int(clickPosition.y) {
                case Int(track.position.y)-10...Int(track.position.y)+10:
                    
                    var trackPos: TrackPosition!
                    
                    switch i {
                    case 3:
                        trackPos = .FarLeft
                    case 2:
                        trackPos = .CenterLeft
                    case 1:
                        trackPos = .CenterRight
                    case 0:
                        trackPos = .FarRight
                    default:
                        fatalError("Wrong string in mouseDown edit")
                    }
                    
                    let yPosition = track.position.y
                    let xPosition = clickPosition.x
                    let appearTime = Int(xPosition/pixelsPerFrame)
                    
                    if appearTime > 0 {
                        var newNote = ElNote(track: trackPos, appearTime: Double(appearTime), noteDuration: 1)
                        
                        newNote.anchorPoint = CGPointMake(0.5, 0.5)
                        newNote.position.x = xPosition
                        newNote.position.y = yPosition
                        newNote.size = CGSizeMake(40, 40)
                        
                        newNote.alpha = 1
                        
                        world.addChild(newNote)
                        
                        if notes[appearTime] != nil {
                            notes[appearTime]?.append(newNote)
                        } else {
                            notes.updateValue([newNote], forKey: appearTime)
                        }
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        
        if currentNode != nil {
            // Queue generation
            var mouseCurrentLocation = theEvent.locationInNode(world)
        
            var dx = mouseCurrentLocation.x - mouseClickPosition.x
            
            
            if dx > 0 {
                currentNode!.noteDuration = Double(dx / pixelsPerFrame)
                
                if currentNode!.noteDuration < 10 {
                    currentNode!.queue?.removeFromParent()
                    currentNode!.queue = nil
                } else {
                    currentNode!.queue?.removeFromParent()
                    currentNode!.queue = SKSpriteNode(color: currentNode?.color, size: CGSizeMake(UIConfig.queueWidth, currentNode!.calculateQueueLength()))
                    currentNode!.queue!.color = currentNode!.color
                    currentNode!.queue!.colorBlendFactor = 0.8
                    currentNode!.queue!.anchorPoint = CGPointMake(0.5, 0)
                    currentNode!.queue!.zRotation = CGFloat(-M_PI_2)
                    currentNode!.addChild(currentNode!.queue!)
                }
            }
        } else {
            // Window dragging movement
            var screenFrame = NSScreen.mainScreen()!.frame
            var windowFrame = self.view!.window!.frame
            
            var currentLocation = NSEvent.mouseLocation()
            
            var newOrigin: NSPoint = NSPoint(x: 0, y: 0)
            
            newOrigin.x = currentLocation.x - initialLocation.x
            newOrigin.y = currentLocation.y - initialLocation.y
            
            self.view!.window!.setFrameOrigin(newOrigin)
        }
    }
    
    // MARK: - NOTE CREATION
    
    func newNote(keyCode: UInt16) {
        println("newNote")
        
        let time = -Int((world.position.x - scene!.size.width / 2) / pixelsPerFrame)
        
        var trackPos: TrackPosition!
        var track = tracks[0]
        
        switch keyCode {
        case 1: // S
            trackPos = .FarLeft
            track = tracks[3]
        case 3: // F
            trackPos = .CenterLeft
            track = tracks[2]
        case 4: // H
            trackPos = .CenterRight
            track = tracks[1]
        case 40: // K
            trackPos = .FarRight
            track = tracks[0]
        default:
            fatalError("Wrong track in EditScene.keyboardNote")
        }
        
        let yPosition = track.position.y
        let xPosition = CGFloat(time) * pixelsPerFrame
        let appearTime = Int(xPosition/pixelsPerFrame)
        
        if appearTime > 0 {
            var newNote = ElNote(track: trackPos, appearTime: Double(appearTime), noteDuration: 10)
            
            newNote.anchorPoint = CGPointMake(0.5, 0.5)
            newNote.position.x = xPosition
            newNote.position.y = yPosition
            newNote.size = CGSizeMake(40, 40)
            
            newNote.alpha = 1
            
            world.addChild(newNote)
            
            currentKeyboardNotes.updateValue(newNote, forKey: keyCode)
            
            if notes[appearTime] != nil {
                notes[appearTime]?.append(newNote)
            } else {
                notes.updateValue([newNote], forKey: appearTime)
            }
        }
    }
    
    func endNote(keyCode: UInt16) {
        println("endNote")
        currentKeyboardNotes.removeValueForKey(keyCode)
    }
    
    // MARK: - SIMULATION CONTROL
    
    func reset() {
        world.position.x = scene!.size.width/2
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        let time = -Int((world.position.x - scene!.size.width / 2) / pixelsPerFrame)
        timeLabel.text = "\(time)"
        
        if isPlaying {
            for (key, note) in currentKeyboardNotes {
                note.noteDuration += 1
                
                if note.noteDuration > 20 {
                    note.queue?.removeFromParent()
                    note.queue = SKSpriteNode(color: note.color, size: CGSizeMake(UIConfig.queueWidth, (CGFloat(note.noteDuration) * pixelsPerFrame) - note.size.width))
                    note.queue!.position.x = note.size.width / 2
                    note.queue!.color = note.color
                    note.queue!.colorBlendFactor = 0.8
                    note.queue!.anchorPoint = CGPointMake(0.5, 0)
                    note.queue!.zRotation = CGFloat(-M_PI_2)
                    note.addChild(note.queue!)
                }
            }
        }
        
        if let noteList = notes[time] {
            
            // Animate the right marker
            for note in noteList {
                
                var trackIndex: Int!
                var sound: SKAction!
                
                switch note.trackPosition {
                case .FarLeft:
                    trackIndex = 0
                    sound = sounds["low_beat"]
                case .CenterLeft:
                    trackIndex = 1
                    sound = sounds["high_beat"]
                case .CenterRight:
                    trackIndex = 2
                    sound = sounds["low_vocal"]
                case .FarRight:
                    trackIndex = 3
                    sound = sounds["high_vocal"]
                default:
                    fatalError("Wrong track called in game update")
                }
                
                if note.noteDuration > 10 {
                    sound = SKAction.repeatAction(sound, count: Int(note.noteDuration/20))
                }
                
                if UIConfig.playSound {
                    world.runAction(sound)
                }
            }
        }
    }
    
    // MARK: - SETUP
    
    func changePlayStatusNode(play: Bool) {
        
        let action: SKAction!
        
        if play {
            action = SKAction.setTexture(SKTexture(imageNamed: "play"))
        } else {
            action = SKAction.setTexture(SKTexture(imageNamed: "pause"))
        }
        
        playStatusNode.runAction(action)
    }
    
    func loadNotes() {
        
        for time in notes.keys {
            var noteList = notes[time]!
            
            for note in noteList {
                
                note.position.x = 0
                note.position.y = 0
                
                switch note.trackPosition {
                case .FarLeft:
                    note.position.y = self.scene!.size.height / 5 * 4
                case .CenterLeft:
                    note.position.y = self.scene!.size.height / 5 * 3
                case .CenterRight:
                    note.position.y = self.scene!.size.height / 5 * 2
                case .FarRight:
                    note.position.y = self.scene!.size.height / 5 * 1
                default:
                    fatalError("Wrong track in loadNotes of EditScene")
                }
                
                note.anchorPoint = CGPointMake(0.5, 0.5)
                note.position.x = CGFloat(note.appearTime) * pixelsPerFrame
                note.alpha = 1
                note.size = CGSizeMake(40, 40)
                
                if note.noteDuration > 20 {
                    note.queue?.removeFromParent()
                    note.queue = SKSpriteNode(color: note.color, size: CGSizeMake(UIConfig.queueWidth, (CGFloat(note.noteDuration) * pixelsPerFrame) - note.size.width))
                    note.queue!.position.x = note.size.width / 2
                    note.queue!.color = note.color
                    note.queue!.colorBlendFactor = 0.8
                    note.queue!.anchorPoint = CGPointMake(0.5, 0)
                    note.queue!.zRotation = CGFloat(-M_PI_2)
                    note.addChild(note.queue!)
                }
                
                world.addChild(note)
            }
        }
    }
    
    func createTracks() {
        let sceneSize = self.scene!.size
        
        let length = maxLength * pixelsPerFrame
        
        for i in 1...4 {
            var track = SKSpriteNode(color: NSColor.whiteColor(), size: CGSizeMake(length, 1))

            track.anchorPoint = CGPointZero
            track.position.x = 0
            track.position.y = sceneSize.height/5 * CGFloat(i)
            
            tracks.append(track)
            
            world.addChild(track)
        }
        
        scene?.addChild(SKShapeNode(rect: CGRectMake(sceneSize.width/2, 0, 1, sceneSize.height)))
        
        var tickPosition: CGFloat = 0
        
        while tickPosition < length {
            var tick = SKSpriteNode(color: NSColor.whiteColor(), size: CGSizeMake(1, sceneSize.height / 5 * 3))
            
            tick.anchorPoint = CGPointZero
            tick.position.x = tickPosition
            tick.position.y = sceneSize.height / 5
            
            world.addChild(tick)
            
            tickPosition += 60 * pixelsPerFrame * 5
        }
    }
    
    func preloadSounds() {
        let soundNames = ["low_beat", "high_beat", "low_vocal", "high_vocal"]
        
        for soundName in soundNames {
            let action = SKAction.playSoundFileNamed(soundName + ".wav", waitForCompletion: true)
            sounds.updateValue(action, forKey: soundName)
        }
    }
    
}