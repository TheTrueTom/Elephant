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
import CoreGraphics

var topZPosition: CGFloat = 100000

class ElNote: SKSpriteNode, Printable {
    
    /** Corde sur laquelle est placée la note */
    var trackPosition: TrackPosition = .FarLeft
    
    /** Corresponding track */
    var track: Track!
    
    /** Temps auquel la note apparait à l'écran */
    var appearTime: NSTimeInterval = 0.0
    
    /** Temps que dure la note */
    var noteDuration: NSTimeInterval = 0
    
    var soundAction: SKAction!
    
    var alphaAction: SKAction!
    
    var mainMoveAction: SKAction!
    var mainSizeAction: SKAction!
    var mainAlphaAction: SKAction!
    var mainGroupedAction: SKAction!
    
    var yoloUpAction: SKAction!
    var yoloDownAction: SKAction!
    
    var colorTexture: SKTexture!
    var nbTexture: SKTexture!
    
    override var description: String {
        get {
            return "Note: appearTime = \(appearTime)"
        }
    }
    
    init(texture: SKTexture!, color: NSColor!, size: CGSize, appearTime: NSTimeInterval, noteDuration: NSTimeInterval, track: TrackPosition, flipped: Bool) {
        super.init(texture: texture, color: color, size: size)
        
        self.colorBlendFactor = UIConfig.songItemColorBlendingFactor
        self.alpha = 0
        
        self.trackPosition = track
        self.appearTime = appearTime
        self.noteDuration = noteDuration
        
        self.zPosition = topZPosition
        topZPosition--
        
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
            soundName = (flipped) ? "clap_main" : "boum_corps"
        case .CenterLeft:
            soundName = (flipped) ? "tchiki_bouche" : "boum_bouche"
        case .CenterRight:
            soundName = (flipped) ? "boum_corps" : "clap_main"
        case .FarRight:
            soundName = (flipped) ? "boum_bouche" : "tchiki_bouche"
        default:
            fatalError("Wrong track called in sound init ElNote")
        }
        
        soundAction = SKAction.playSoundFileNamed(soundName + ".wav", waitForCompletion: false)
    
        alphaAction = SKAction.fadeAlphaTo(0, duration: 1)
    }
    
    convenience init(track: TrackPosition, appearTime: NSTimeInterval, noteDuration: NSTimeInterval, flipped: Bool = false) {
        
        var color = NSColor.whiteColor()
        var texture: String = ""
        
        switch track {
        case .FarLeft:
            color = NSColor.redColor()
            texture = "note1"
        case .CenterLeft:
            color = NSColor.greenColor()
            texture = "note3"
        case .CenterRight:
            color = NSColor.blueColor()
            texture = "note2"
        case .FarRight:
            color = NSColor.orangeColor()
            texture = "note4"
        default:
            fatalError("Wrong track called in convenience init ElNote")
        }
        
        self.init(texture: SKTexture(imageNamed: texture), color: color, size: UIConfig.noteStartSize, appearTime: appearTime, noteDuration: noteDuration, track: track, flipped: flipped)
        
        colorTexture = SKTexture(imageNamed: texture)
        nbTexture = SKTexture(imageNamed: texture + "nb")
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
        self.runAction(alphaAction, withKey: "alphaAction")
    }
    
    func startReappearance() {
        self.alpha = 0.5
    }
    
    func fireEmitter() {
        
        self.runAction(yoloUpAction) {
            self.decolorize()
            self.runAction(self.yoloDownAction, withKey: "yoloDownAction")
        }
    }
    
    func colorize() {
        self.texture = colorTexture
    }
    
    func decolorize() {
        self.texture = nbTexture
    }
}