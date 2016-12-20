//
//  TracciaStilo.swift
//  Meridiana
//
//  Created by Francesco Meschia on 9/28/15.
//  Copyright © 2015 Francesco Meschia. All rights reserved.
//

import Cocoa

class TracciaStilo: NSObject, Segno {

    var centro : CGPoint = CGPoint()
    var origine : CGPoint = CGPoint()
    var ridotto : Bool
    var theModel : MeridianaModel
    var theBounds : CGRect = CGRect()
    
    init(model: MeridianaModel, ridotto: Bool) {
        self.theModel = model
        self.ridotto = ridotto
        super.init()
        calcola()
    }
    
    func calcola() {
        centro = theModel.centro(ridotto)
        theBounds.origin.x = CGFloat(min(0, centro.x))
        theBounds.origin.y = CGFloat(min(0, centro.y))
        theBounds.size.width = CGFloat(max(0, centro.x) - theBounds.origin.x + 1)
        theBounds.size.height = CGFloat(max(0, centro.y) - theBounds.origin.y + 1)
    //    centro.x += CGFloat(-theBounds.origin.x)
    //    centro.y += CGFloat(-theBounds.origin.y)
    //    origine.x += CGFloat(-theBounds.origin.x)
    //    origine.y += CGFloat(-theBounds.origin.y)
    }

    func draw(_ ctx: CGContext, scale: CGFloat) {
        ctx.setStrokeColor(red: 1, green: 0, blue: 0, alpha: 1)
        ctx.move(to: CGPoint(x: self.origine.x, y: self.origine.y))
        ctx.addLine(to: CGPoint(x: self.centro.x, y: self.centro.y))
    }
    
    func getBounds() -> CGRect {
        return CGRect(x: min(centro.x, origine.x), y: min(centro.y, origine.y), width: abs(centro.x-origine.x), height:abs(centro.y - origine.y))
    }

    
}

		
