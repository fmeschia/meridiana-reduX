//
//  LineaOraria.swift
//  Meridiana
//
//  Created by Francesco Meschia on 9/29/15.
//  Copyright © 2015 Francesco Meschia. All rights reserved.
//

import Cocoa

enum LineaOrariaError: ErrorType {
    case NoPoints
}

typealias Polilinea = [CGPoint]

class LineaOraria: Segno {
    var inizio: CGPoint?
    var fine: CGPoint?
    var curva: Polilinea = Polilinea()
    var alfa: Double
    var theModel: MeridianaModel
    var scala: Double
    var ridotto: Bool
    var lemniscata: Bool = true
    
    init(theModel: MeridianaModel, ha: Double, ridotto: Bool) throws {
        self.theModel = theModel
        self.ridotto = ridotto
        self.alfa = ha
        self.scala = 1.0
        try calcola()
    }
    
    func calcola() throws {
        var calcolato: Bool = false
        var tutto: Bool = true
        var tau: Double
        var p: CGPoint
        for var k = 0; k <= 144 ; k++ {
            do {
                tau = 1.0 + 2.58924/1200.0
                tau += Double(k) / 14400.0
                try p = theModel.calcola(alfa, tau: tau, medio: true, strict: true, ridotto: ridotto)
                if (!calcolato) {
                    curva.append(p)
                    calcolato = true
                } else {
                    curva.append(p)
                }
            } catch {
                tutto = false
                break
            }			
        }
        //if (calcolato) {
            calcolato = false
            for var m = -3; m <= 3 ; m++ {
            do {
                    tau = 1.0 + (2.58924/1200.0)
                    tau += (Double(m)/1200.0)
                    try p = theModel.calcola(alfa, tau:tau, medio:false, strict:true, ridotto:ridotto)
                    if (!calcolato) {
                        inizio = p //inizio.scale(scala);
                        fine = p
                        calcolato = true;
                    } else {
                        fine = p //inizio.scale(scala);
                    }
                } catch {
                    tutto = false
                }
            }
        //}
        if (!tutto) {
            lemniscata = false
        }
        if (!calcolato) {
            throw LineaOrariaError.NoPoints
        }
            //inizio!.y = -(inizio!.y)
        //fine!.y = -(fine!.y)
    }
    
    func draw(ctx: CGContext, scale: CGFloat) {
        CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1)
        if (lemniscata) {
            var primo : Bool = true
            for punto: CGPoint in curva {
                if primo {
                    CGContextMoveToPoint(ctx, punto.x*scale, punto.y*scale)
                    primo = false
                } else {
                    CGContextAddLineToPoint(ctx, punto.x*scale, punto.y*scale)
                }
            }
        } else {
            CGContextMoveToPoint(ctx, inizio!.x*scale, inizio!.y*scale)
            CGContextAddLineToPoint(ctx, fine!.x*scale, fine!.y*scale)
        }
    }
    
    func getBounds() -> CGRect {
        if (lemniscata) {
            var boundsRect : CGRect!
            var primo : Bool = true
            for punto: CGPoint in curva {
                if primo {
                    boundsRect = CGRect(origin: punto, size: CGSizeZero)
                    primo = false
                } else {
                    boundsRect = CGRectUnion(boundsRect, CGRect(origin: punto, size:CGSizeZero))
                }
            }
            return boundsRect
        } else {
            return CGRect(x: min(inizio!.x, fine!.x), y: min(inizio!.y, fine!.y), width: abs(fine!.x-inizio!.x), height:abs(fine!.y - inizio!.y))
        }
    }
}
