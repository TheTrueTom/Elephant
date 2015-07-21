//
//  UIPreferences.swift
//  Elephant
//
//  Created by Thomas Brichart on 08/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation

struct UIPreferences {
    
    // MARK: - Notes
    
    /// Largeur des notes
    var noteWidth: CGFloat = 60
    
    /// Longueur des notes
    var noteHeight: CGFloat = 60
    
    /// Temps que mets une note pour aller du haut à la ligne de base
    var noteDuration: NSTimeInterval = 30
    
    /// Mix entre la couleur et la texture des notes
    var songItemColorBlendingFactor: CGFloat = 0
    
    /// Wether sounds should be played or not
    var playSound: Bool = true
    
    var yoloFactor: CGFloat = 2
    
    // MARK: - RESERVED
    
    /* 
    
    DO NOT MODIFY ANYTHING AFTER THIS POINT 
    
    */
    
    var expectedFPS: Double = 60
    
    var songLength: Double = 100
    
    /// Taille de la fenêtre
    var screenSize: CGSize = CGSizeZero
    
    mutating func setScreenSize(size: CGSize) {
        self.screenSize = size
    }
    
    /// Taille des notes en haut de l'écran
    var noteStartSize: CGSize {
        let height = noteEndSize.height * 0.95
        let width = noteEndSize.width * 0.95
        return CGSizeMake(width, height)
    }
    
    /// Taille des notes en bas de l'écran
    var noteEndSize: CGSize {
        return CGSizeMake(noteWidth, noteHeight)
    }
    
    var noteYoloSize: CGSize {
        return CGSizeMake(noteWidth * yoloFactor, noteHeight * yoloFactor)
    }
}