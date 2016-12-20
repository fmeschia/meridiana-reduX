//
//  LineaStagionale.swift
//  Meridiana
//
//  Created by Francesco Meschia on 9/29/15.
//  Copyright © 2015 Francesco Meschia. All rights reserved.
//

import Cocoa

enum LineaStagionaleError: Error {
    case noPoints
}

class LineaStagionale: NSObject, Segno  {
    var theModel: MeridianaModel
    var delta: Double
    var scala: Double
    var ridotto: Bool
    var segmenti = [Polilinea]()

    
    init(theModel: MeridianaModel, mesi: Double, ridotto: Bool) throws {
        self.theModel = theModel
        self.ridotto = ridotto
        self.delta = 1.0 + (2.58924/1200.0)
        self.delta += (Double(mesi)/1200.0)
        self.scala = 1.0
        super.init()
        try calcola()
    }
    
    func calcola() throws  {
        var calcolato: Bool = false
        var p : CGPoint
        var segm = Polilinea()
        for i in 0...96 {
            do {
                try p = theModel.calcola(Utils.deg2rad(Double(i-24)*3.75), tau:delta, medio: false, strict: true, ridotto: ridotto)
                if i%4 == 0 || !segm.isEmpty {
                    segm.append(p)
                    calcolato = true
                }
            } catch {
                if !segm.isEmpty {
                    while segm.count % 4 != 1 {
                        segm.removeLast()
                    }
                    segmenti.append(segm)
                    segm = Polilinea()
                }
            }
        }
        if !calcolato {
            throw LineaStagionaleError.noPoints
        }
        if !segm.isEmpty {
            while segm.count % 4 != 1 {
                segm.removeLast()
            }
            segmenti.append(segm)
        }
    }
    
    func draw(_ ctx: CGContext, scale: CGFloat) {
        for segmento in segmenti {
            var primo = true
            for punto in segmento {
                if (primo) {
                    ctx.move(to: CGPoint(x: punto.x, y: punto.y))
                    primo = false
                } else {
                    ctx.addLine(to: CGPoint(x: punto.x, y: punto.y))
                }
            }
        }
    }
    
    func getBounds() -> CGRect {
        var primo = true
        var bounds : CGRect = CGRect.zero
        for segmento in segmenti {
            for punto in segmento {
                if (primo) {
                    bounds = CGRect(origin: punto, size: CGSize(width: 0.0, height: 0.0))
                    primo = false
                } else {
                    bounds = bounds.union(CGRect(origin:punto, size:CGSize(width:0.0, height: 0.0)));
                }
            }
        }
        return bounds
    }

}
