//
//  UIPreferences.swift
//  Elephant
//
//  Created by Thomas Brichart on 08/06/2015.
//  Copyright (c) 2015 Thomas Brichart. All rights reserved.
//

import Foundation

struct UIPreferences {
    // MARK: - Cordes
    
    /// Espacement entre les cordes au bas de l'écran
    var bottomTrackSpacing: CGFloat = 250
    
    /// Espacement entre deux sous-cordes au bas de l'écran
    var bottomSubSpacing: CGFloat = 75
    
    /// Espacement entre les cordes en haut de l'écran
    var topTrackSpacing: CGFloat = 100
    
    /// Espacement entre deux sous-cordes en haut de l'écran
    var topSubSpacing: CGFloat = 30
    
    /// Largeur du trait des cordes
    var trackStrokeWidth: CGFloat = 2
    
    /// Hauteur de la ligne de base par rapport au bas de l'écran
    var baseLineHeight: CGFloat = 100
    
    /// Espacement entre les lignes secondaires
    var sublineSpacing: CGFloat = 100
    
    /// Largeur du trait de la ligne de base
    var baseLineStrokeWidth: CGFloat = 2
    
    /// Largeur du trait des lignes secondaires
    var sublineStrokeWidth: CGFloat = 1
    
    // MARK: - Notes
    
    /// Largeur des notes
    var noteWidth: CGFloat = 60
    
    /// Longueur des notes
    var noteHeight: CGFloat = 30
    
    /// Temps que mets une note pour aller du haut à la ligne de base (en s)
    var noteDuration: NSTimeInterval = 10
    
    
    /// Mix entre la couleur et la texture des notes
    var songItemColorBlendingFactor: CGFloat = 0.8
    
    /// Largeur de trait de la queue des notes longues
    var queueWidth: CGFloat = 8
    
    /// Wether sounds should be played or not
    var playSound: Bool = true
    
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
    
    /// Temps que mets une note pour aller du haut de l'écran au bas de l'écran
    var realNoteDuration: NSTimeInterval {
        let durationMultiplier = screenSize.height / (screenSize.height - baseLineHeight)
        
        return noteDuration * Double(durationMultiplier)
    }
    
    /// Taille des notes en haut de l'écran
    var noteStartSize: CGSize {
        
        let height = noteEndSize.height / ((bottomTrackSpacing / topTrackSpacing) / 2)
        let width = noteEndSize.width / ((bottomTrackSpacing / topTrackSpacing) / 2)
        return CGSizeMake(width, height)
    }
    
    /// Taille des notes en bas de l'écran
    var noteEndSize: CGSize {
        return CGSizeMake(noteWidth, noteHeight)
    }
    
    /// Sound Far Left
    var soundA: NSURL? = nil
    
    /// Sound Center Left
    var soundB: NSURL? = nil
    
    /// Sound Center Right
    var soundC: NSURL? = nil
    
    /// Sound Far Right
    var soundD: NSURL? = nil
    
}