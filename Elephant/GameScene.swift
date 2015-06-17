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
    
    // Nodes
    var world: SKNode!
    var notes: [Int: [ElNote]] = [:]
    var markers: [ElMarker] = []
    var emitters: [SKEmitterNode] = []
    
    // Sounds
    var sounds: [String: SKAction] = [:]
    
    // Simulation timer
    var gameTime: Int = 0
    var endTime: Double = 100
    
    // Debug labels
    var speedLabel: SKLabelNode!
    var timerLabel: SKLabelNode!
    
    /** Initial location for window dragging set on mouseDown*/
    var initialLocation: NSPoint!
    
    // MARK: - LIFE CYCLE
    
    override func didMoveToView(view: SKView) {
        
        // Cleaning
        scene?.removeAllActions()
        scene?.removeAllChildren()
        
        self.scene!.size = view.frame.size
        
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
        setupBaseline()
        setupMarkers()
        preloadSounds()
        
        #if DEBUG
        setupDebug()
        #endif
    }
    
    // MARK: - FRAME UPDATE
    
    override func update(currentTime: CFTimeInterval) {
        
        /* If the speed is positive, when the time is right either
        a particle appears on the top of the screen or an animation
        is started  at the right baseline marke */
        
        if speed > 0 {
            
            /* The current gameTime is taken into account as well as the game ticks
            that will be ignored by the speed of the animation */
            
            for i in 0 ..< Int(speed) {
                
                // Get the list of notes suposed to appear
                if let noteList = notes[gameTime + i] {
                    
                    // Add each note to the scene
                    for note in noteList {
                        if note.parent == nil {
                            world.addChild(note)
                            note.animate(endTime)
                        }
                    }
                }
                
                /// Time when a note is supposed to reach the baseline
                let noteEndTime = Int(UIConfig.noteDuration * UIConfig.expectedFPS)
                
                // Get the list of notes supposed to reach the baseline
                if let noteList = notes[gameTime - noteEndTime + i] {
                    
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
                        
                        emitters[trackIndex].numParticlesToEmit = Int(note.noteDuration * 10)
                        emitters[trackIndex].resetSimulation()
                        
                        if note.noteDuration > 10 {
                            sound = SKAction.repeatAction(sound, count: Int(note.noteDuration/20))
                        }
                        
                        if UIConfig.playSound {
                            world.runAction(sound)
                        }
                    }
                }
            }
            
            /* If speed is negative, when a note reaches the top of the screen
            it is removed to avoid creating doubles */
            
        } else if speed < 0 {
            for i in Int(speed) ..< 0 {
                if let noteList = notes[gameTime + i] {
                    
                    // Remove each note from the scene
                    for note in noteList {
                        note.removeAllActions()
                        note.removeFromParent()
                    }
                }
            }
        }
        
        if (gameTime > 0 && speed < 0) || (gameTime < (Int(endTime) - 100) && speed > 0) {
            gameTime += Int(speed)
        } else {
            speed = 0
        }
        
        #if DEBUG
            timerLabel.text = "\(gameTime) / \(Int(endTime))"
        #endif
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
            if gameTime > 0 {
                scene?.speed -= 1
            }
        case 126: // Up
            if gameTime < Int(endTime) {
                scene?.speed += 1
            }
        case 49: // Space
            if gameTime < Int(endTime) {
                scene?.speed = (scene?.speed == 0) ? 1 : 0
            }
        case 15: // R
            reset()
        case 3: // F
            if gameTime > 0 {
                scene?.speed = -5
            }
        case 38: // J
            if gameTime < Int(endTime) {
                scene?.speed = 5
            }
        default:
            break
        }
        
        #if DEBUG
        speedLabel.text = "Speed: \(Int(scene!.speed))"
        #endif
    }
    
    // MARK: - SIMULATION HANDLING
    
    /**
    Reset the song:
    
    1. Game time is set to zero (0)
    2. All notes are removed from the partition
    3. Speed is set to zero (0)
    */
    
    func reset() {
        
        scene?.speed = 0
        gameTime = 0
        
        for node in world.children {
            if node.isKindOfClass(ElNote) {
                var songItem = node as! ElNote
                
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
        setupBaseline()
        setupMarkers()
        preloadSounds()
        
        #if DEBUG
        setupDebug()
        #endif
    }
    
    func setupDebug() {
        timerLabel = SKLabelNode(text: "\(gameTime)")
        timerLabel.horizontalAlignmentMode = .Left
        timerLabel.position = CGPointMake(0, 0)
        timerLabel.text = "0"
        scene?.addChild(timerLabel)
        
        speedLabel = SKLabelNode(text: "Speed: \(Int(scene!.speed))")
        speedLabel.horizontalAlignmentMode = .Left
        speedLabel.verticalAlignmentMode = .Bottom
        speedLabel.position = CGPointMake(0, scene!.frame.height - speedLabel.frame.size.height)
        speedLabel.text = "0"
        scene?.addChild(speedLabel)
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
        
        for track in tracks {
            world.addChild(track)
        }
    }
    
    /**
    Setup the horizontal lines
    */
    
    func setupBaseline() {
        
        if let left = tracks[0].markerPosition, let right = tracks[3].markerPosition {
            var path: CGMutablePathRef = CGPathCreateMutable()
            CGPathMoveToPoint(path, nil, left.x, left.y)
            CGPathAddLineToPoint(path, nil, right.x, right.y)
            
            var baseline = SKShapeNode(path: path)
            baseline.strokeColor = NSColor.whiteColor()
            baseline.lineWidth = UIConfig.baseLineStrokeWidth
            
            world.addChild(baseline)
        }
    }
    
    /** 
    Setup the four markers on the baseline
    */
    
    func setupMarkers() {
        markers.removeAll(keepCapacity: false)
        emitters.removeAll(keepCapacity: false)
        
        let markerParticles = NSBundle.mainBundle().pathForResource("MarkerParticle", ofType: "sks")
        
        let markerColors = [NSColor.redColor(), NSColor.greenColor(), NSColor.blueColor(), NSColor.orangeColor()]
        
        if markerColors.count == tracks.count {
            for i in 0..<tracks.count {
                markers.append(ElMarker(position: tracks[i].markerPosition, color: markerColors[i]))
                
                var emitter = NSKeyedUnarchiver.unarchiveObjectWithFile(markerParticles!) as! SKEmitterNode
                emitter.position = tracks[i].markerPosition
                emitters.append(emitter)
            }
        }
        
        for marker in markers {
            world.addChild(marker)
        }
        
        for emitter in emitters {
            world.addChild(emitter)
        }
    }
    
    /**
    Create the sound actions
    */
    
    func preloadSounds() {
        sounds.removeAll(keepCapacity: false)
        
        let soundNames = ["low_beat", "high_beat", "low_vocal", "high_vocal"]
        
        for soundName in soundNames {
            let action = SKAction.playSoundFileNamed(soundName + ".wav", waitForCompletion: true)
            sounds.updateValue(action, forKey: soundName)
        }
    }
}
