//
//  Meridiana.swift
//  Meridiana
//
//  Created by Francesco Meschia on 9/28/15.
//  Copyright © 2015 Francesco Meschia. All rights reserved.
//

import Cocoa

class Meridiana: NSView {
    var theModel : MeridianaModel?
    var boundingBox : CGRect?
    var calcolato : Bool = false
    var elementi : [Segno]!
    var ratio : CGFloat = 1.0
    
    func calcola() {
        elementi = [Segno]()
        boundingBox = CGRectZero
        let tracciaStilo : TracciaStilo = TracciaStilo(model: self.theModel!, ridotto: true)
        elementi.append(tracciaStilo)
        
        for var h = 0; h < 24; h++ {
            do {
                var l: LineaOraria
                try l = LineaOraria(theModel:theModel!, ha:Utils.deg2rad((Double(h)-12)*15.0), ridotto:true)
                elementi.append(l)
                var statoLinea : Int
                if l.tutto {
                    if (l.lemniscata) {
                        statoLinea = LineaOrariaState.Lemniscata
                    } else {
                        statoLinea = LineaOrariaState.LineaOrariaCompleta
                    }
                } else {
                    statoLinea = LineaOrariaState.LineaParziale
                }
                theModel?.statoLineeOrarie.append(statoLinea)
            } catch LineaOrariaError.NoPoints {
 
            } catch {
                
            }
        }
        for var m = -3; m <= 3; m++ {
            do {
                var l: LineaStagionale
                try l = LineaStagionale(theModel: theModel!, mesi: Double(m), ridotto: true)
                elementi.append(l)
            } catch {
                
            }
        }
        calcolato = true
        for elemento in self.elementi {
            let elementBounds : CGRect = elemento.getBounds()
            boundingBox = CGRectUnion((boundingBox == nil ? elementBounds : boundingBox!), elementBounds)
        }
        boundingBox = CGRectInset(boundingBox!, -30, -30)
        boundingBox = CGRect(origin: boundingBox!.origin, size:CGSize(width:boundingBox!.width, height:550))
        //boundingBox = CGRect(origin: CGPoint(x:-330,y:-330),size:CGSize(width:660, height:660))
        self.setFrameSize(CGSize(width: 600, height: boundingBox!.height))
    }
    
    private var currentContext : CGContext? {
        get {
            if #available(OSX 10.10, *) {
                return NSGraphicsContext.currentContext()?.CGContext
            } else if let contextPointer = NSGraphicsContext.currentContext()?.graphicsPort {
                let context: CGContextRef = Unmanaged.fromOpaque(COpaquePointer(contextPointer)).takeUnretainedValue()
                return context
            }
            
            return nil
        }
    }
    
    private func saveGState(drawStuff: (ctx:CGContextRef) -> ()) -> () {
        if let context = self.currentContext {
            CGContextSaveGState (context)
            drawStuff(ctx: context)
            CGContextRestoreGState (context)
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        var location: CGPoint = theEvent.locationInWindow
        location = self.convertPoint(location, fromView: nil)
        location.x -= 300/ratio
        location.y -= -self.boundingBox!.origin.y/ratio
        for elemento in elementi {
            if elemento is LineaOraria {
                if (elemento as! LineaOraria).contiene(location, scale: CGFloat(1.0/ratio)) {
                    (elemento as! LineaOraria).premuto = true
                    self.needsDisplay = true
                }
            }
        }
    }
    
    override func mouseUp(theEvent: NSEvent) {
        var location: CGPoint = theEvent.locationInWindow
        location = self.convertPoint(location, fromView: nil)
        location.x -= 300/ratio
        location.y -= -self.boundingBox!.origin.y/ratio
        for elemento in elementi {
            if elemento is LineaOraria {
                (elemento as! LineaOraria).premuto = false
                if (elemento as! LineaOraria).contiene(location, scale: CGFloat(1.0/ratio)) {
                    if (elemento as! LineaOraria).tutto {
                        (elemento as! LineaOraria).lemniscata = !(elemento as! LineaOraria).lemniscata
                    }
                }
                self.needsDisplay = true
            }
        }
    }

    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        var layer: CGLayer?
        var layerContext: CGContext?
        let containerFrame = self.frame
        if (calcolato) {
            ratio = max(boundingBox!.size.width/containerFrame.size.width,boundingBox!.size.height/containerFrame.size.height)
            ratio = 1.0
            saveGState { ctx in
                layer = CGLayerCreateWithContext(ctx, self.bounds.size, nil)!
                layerContext = CGLayerGetContext(layer)!
                //CGContextTranslateCTM(layerContext, -self.boundingBox!.origin.x/self.ratio, -self.boundingBox!.origin.y/self.ratio)
                CGContextTranslateCTM(layerContext, 300, -self.boundingBox!.origin.y)
                //self.setFrameSize(CGSize(width: 600, height:600))
                //CGContextScaleCTM(layerContext, CGFloat(1.0/self.ratio), CGFloat(1.0/self.ratio))
                //self.ratio = 1.0
                CGContextBeginPath(layerContext)
                

                for elemento in self.elementi {
                    if elemento is LineaOraria || elemento is LineaStagionale {
                        CGContextBeginPath(layerContext);
                        CGContextSetLineWidth(layerContext,CGFloat(1.0))
                        CGContextSetAllowsAntialiasing(layerContext, true)
                        CGContextSetShouldAntialias(layerContext, true)
                        elemento.draw(layerContext!, scale: CGFloat(1.0/self.ratio))
                        CGContextStrokePath(layerContext)
                    }
                }
                
                CGContextBeginPath(layerContext);
                for elemento in self.elementi {
                    if elemento is TracciaStilo {
                        elemento.draw(layerContext!, scale: CGFloat(1.0/self.ratio))
                    }
                }
                CGContextStrokePath(layerContext)
            }
            
            saveGState { ctx in
                CGContextDrawLayerAtPoint(ctx, CGPointZero, layer)
                //CGContextStrokeRect(ctx,self.bounds)

            }
        }
    }
    
    /*
    func toDictionary() -> NSDictionary {
        let dict : NSDictionary = [
            "model": theModel!.toDictionary()
        ]
        return dict
    }
    
    class func fromDictionary(dict: NSDictionary) -> Meridiana {
        let object : Meridiana = Meridiana()
        object.theModel = MeridianaModel.fromDictionary(dict)
        object.calcola()
        return object
    }
*/
    
}
