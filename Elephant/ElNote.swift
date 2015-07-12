//
//  ElNote.swift
//  Elephant
//
//  Created by Thomas Brichart on 09/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

enum Tone {
    case High
    case Low
}

enum SoundType {
    case Beat
    case Vocal
}

class ElNote: SKSpriteNode, Printable {
    
    /** Corde sur laquelle est placée la note */
    var trackPosition: TrackPosition = .FarLeft
    
    /** Corresponding track */
    var track: Track!
    
    /** Temps auquel la note apparait à l'écran */
    var appearTime: NSTimeInterval = 0.0
    
    /** Temps que dure la note */
    var noteDuration: NSTimeInterval = 0
    
    /** Type de note */
    var soundType: SoundType!
    
    /** Tonalité de la note */
    var tone: Tone!
    
    var soundAction: SKAction!
    
    var alphaAction: SKAction!
    
    var mainMoveAction: SKAction!
    var mainSizeAction: SKAction!
    var mainAlphaAction: SKAction!
    var mainGroupedAction: SKAction!
    
    var yoloUpAction: SKAction!
    var yoloDownAction: SKAction!
    
    override var description: String {
        get {
            return "Note: appearTime = \(appearTime)"
        }
    }
    
    init(texture: SKTexture!, color: NSColor!, size: CGSize, appearTime: NSTimeInterval, noteDuration: NSTimeInterval, track: TrackPosition, tone: Tone, soundType: SoundType) {
        super.init(texture: texture, color: color, size: size)
        
        self.colorBlendFactor = UIConfig.songItemColorBlendingFactor
        self.alpha = 0
        
        self.trackPosition = track
        self.appearTime = appearTime
        self.noteDuration = noteDuration
        
        self.tone = tone
        self.soundType = soundType
        
        self.zPosition = 100
        
        switch track {
        case .FarLeft:
            self.track = tracks[0]
        case .CenterLeft:
            self.track = tracks[1]
        case .CenterRight:
            self.track = tracks[2]
        case .FarRight:
            self.track = tracks[3]
        default:
            fatalError("Wrong track position called in ElNote init")
        }
        
        var soundName = ""
        
        switch track {
        case .FarLeft:
            soundName = "low_beat"
        case .CenterLeft:
            soundName = "high_beat"
        case .CenterRight:
            soundName = "low_beat"
        case .FarRight:
            soundName = "high_beat"
        default:
            fatalError("Wrong track called in sound init ElNote")
        }
        
        soundAction = SKAction.playSoundFileNamed(soundName + ".wav", waitForCompletion: false)
    
        alphaAction = SKAction.fadeAlphaTo(0, duration: 1)
    }
    
    convenience init(track: TrackPosition, appearTime: NSTimeInterval, noteDuration: NSTimeInterval) {
        
        var color = NSColor.whiteColor()
        var tone: Tone = .Low
        var soundType: SoundType = .Vocal
        var texture: String = ""
        
        switch track {
        case .FarLeft:
            color = NSColor.redColor()
            tone = .Low
            soundType = .Vocal
            texture = "note1"
        case .CenterLeft:
            color = NSColor.greenColor()
            tone = .High
            soundType = .Vocal
            texture = "note3"
        case .CenterRight:
            color = NSColor.blueColor()
            tone = .Low
            soundType = .Beat
            texture = "note2"
        case .FarRight:
            color = NSColor.orangeColor()
            tone = .High
            soundType = .Beat
            texture = "note4"
        default:
            fatalError("Wrong track called in convenience init ElNote")
        }
        
        self.init(texture: SKTexture(imageNamed: texture), color: color, size: UIConfig.noteStartSize, appearTime: appearTime, noteDuration: noteDuration, track: track, tone: tone, soundType: soundType)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func removeFromParent() {
        super.removeFromParent()
        
        self.size = UIConfig.noteStartSize
    }
    
    func resetToStart() {
        position = track.top
        alpha = 0
        size = UIConfig.noteStartSize
    }
    
    func prepareForAnimation(endTime: Double) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        
        if let sceneSize = appDelegate.skView.scene?.frame.size {
            
            // Starting position
            position = track.top
            
            /// Position of the note when it will reach the bottom of the screen
            var finalPosition: CGPoint = track.bottom
            
            /// Time (in seconds) the note will actually live (from the moment it appears til the end of the song
            let realDuration = (endTime - appearTime) / UIConfig.expectedFPS
            
            let realNoteDuration = CGFloat(UIConfig.noteDuration) * (sqrt(pow(track.top.x - track.bottom.x, 2) + pow(track.top.y - track.bottom.y, 2)) / sqrt(pow(track.top.x - track.markerPosition.x, 2) + pow(track.top.y - track.markerPosition.y, 2)))
            
            /// Time the note will live divided by the time a note spends on screen
            let multiplier = CGFloat(realDuration) / realNoteDuration
            
            // Definition of the real distance (as a vector) the note will travel
            let dx = 10 * multiplier * (finalPosition.x - self.position.x)
            let dy = 10 * multiplier * (finalPosition.y - self.position.y)
            let moveVector = CGVector(dx: dx, dy: dy)
            
            // Definition of the real size change the note will undergo
            let dw = multiplier * (UIConfig.noteEndSize.width - self.size.width)
            let dh = multiplier * (UIConfig.noteEndSize.height - self.size.height)
            
            /// Real time the note will live
            let duration = Double(realNoteDuration * multiplier)
            
            // Move
            mainMoveAction = SKAction.moveBy(moveVector, duration: duration)
            
            // Resize
            mainSizeAction = SKAction.resizeByWidth(dw, height: dh, duration: duration)
            
            // Alpha when entering the screen
            mainAlphaAction = SKAction.fadeAlphaTo(1, duration: 0.5)
            
            // All actions are simultaneous, only the alpha will stop before the others and won't be reversible
            mainGroupedAction = SKAction.group([mainMoveAction, mainSizeAction, mainAlphaAction])
            
            yoloUpAction = SKAction.resizeToWidth(UIConfig.noteYoloSize.width, height: UIConfig.noteYoloSize.height, duration: 0.1)
            yoloDownAction = SKAction.resizeToWidth(UIConfig.noteEndSize.width, height: UIConfig.noteEndSize.height, duration: 0.1)
        }
    }
    
    func animate(endTime: Double) {
        self.runAction(mainGroupedAction)
    }
    
    func fadeAlpha() {
        self.runAction(alphaAction)
    }
    
    func fireEmitter() {
        self.runAction(yoloUpAction) {
            self.runAction(self.yoloDownAction)
        }
    }
}