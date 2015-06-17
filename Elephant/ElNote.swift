//
//  ElNote.swift
//  Elephant
//
//  Created by Thomas Brichart on 09/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation
import SpriteKit

enum Tone {
    case High
    case Low
}

enum SoundType {
    case Beat
    case Vocal
}

class ElNote: SKSpriteNode {
    
    /** Corde sur laquelle est placée la note */
    var trackPosition: TrackPosition = .FarLeft
    
    /** Corresponding track */
    var track: Track!
    
    /** Temps auquel la note apparait à l'écran */
    var appearTime: NSTimeInterval = 0.0
    
    /** Temps que dure la note */
    var noteDuration: NSTimeInterval = 0
    
    /** Trainée pour les notes longues */
    var queue: SKSpriteNode?
    
    /** Type de note */
    var soundType: SoundType!
    
    /** Tonalité de la note */
    var tone: Tone!
    
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
        
        // Création de la queue de la note si celle-ci dure plus que 10 frames
        if noteDuration > 20 {
            queue = SKSpriteNode(color: color, size: CGSizeMake(UIConfig.queueWidth, calculateQueueLength()))
            queue!.color = color
            queue!.colorBlendFactor = 0.8
            queue!.anchorPoint = CGPointMake(0.5, 0)
            
            if track == .FarLeft || track == .CenterLeft {
                queue!.zRotation = -self.track.angle
            } else if track == .CenterRight || track == .FarRight {
                queue!.zRotation = self.track.angle
            }
            
            self.addChild(queue!)
        }
    }
    
    convenience init(track: TrackPosition, appearTime: NSTimeInterval, noteDuration: NSTimeInterval) {
        
        var color = NSColor.whiteColor()
        var tone: Tone = .Low
        var soundType: SoundType = .Vocal
        
        switch track {
        case .FarLeft:
            color = NSColor.redColor()
            tone = .Low
            soundType = .Vocal
        case .CenterLeft:
            color = NSColor.greenColor()
            tone = .High
            soundType = .Vocal
        case .CenterRight:
            color = NSColor.blueColor()
            tone = .Low
            soundType = .Beat
        case .FarRight:
            color = NSColor.orangeColor()
            tone = .High
            soundType = .Beat
        default:
            fatalError("Wrong track called in convenience init ElNote")
        }
        
        self.init(texture: SKTexture(imageNamed: "circle"), color: color, size: UIConfig.noteStartSize, appearTime: appearTime, noteDuration: noteDuration, track: track, tone: tone, soundType: soundType)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func removeFromParent() {
        super.removeFromParent()
        
        self.size = UIConfig.noteStartSize
    }
    
    func calculateQueueLength() -> CGFloat {
        return CGFloat(noteDuration / UIConfig.expectedFPS) * (track.length / CGFloat(UIConfig.realNoteDuration))
    }
    
    func animate(endTime: Double) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        
        if let sceneSize = appDelegate.skView.scene?.frame.size {
            
            // Starting position
            position = track.top
            
            /// Position of the note when it will reach the bottom of the screen
            var finalPosition: CGPoint = track.bottom
            
            /// Time (in seconds) the note will actually live (from the moment it appears til the end of the song
            let realDuration = (endTime - appearTime) / UIConfig.expectedFPS
            
            /// Time the note will live divided by the time a note spends on screen
            let multiplier = CGFloat(realDuration / UIConfig.realNoteDuration)
            
            // Definition of the real distance (as a vector) the note will travel
            let dx = multiplier * (finalPosition.x - self.position.x)
            let dy = multiplier * (finalPosition.y - self.position.y)
            let moveVector = CGVector(dx: dx, dy: dy)
            
            // Definition of the real size change the note will undergo
            let dw = multiplier * (UIConfig.noteEndSize.width - self.size.width)
            let dh = multiplier * (UIConfig.noteEndSize.height - self.size.height)
            
            /// Real time the note will live
            let duration = UIConfig.realNoteDuration * Double(multiplier)
            
            // Move
            let moveAction = SKAction.moveBy(moveVector, duration: duration)
            
            // Resize
            let sizeAction = SKAction.resizeByWidth(dw, height: dh, duration: duration)
            
            // Alpha when entering the screen
            let alphaAction = SKAction.fadeAlphaTo(1, duration: 0.5)
            
            // All actions are simultaneous, only the alpha will stop before the others and won't be reversible
            let groupedAction = SKAction.group([moveAction, sizeAction, alphaAction])
            
            self.runAction(groupedAction)
        }
    }
    
    func animateEdit() {
        position = track.markerPosition
        alpha = 1
        
        let finalPosition = track.top
        
        let moveAction = SKAction.moveTo(finalPosition, duration: 10)
        self.runAction(moveAction)
    }
}