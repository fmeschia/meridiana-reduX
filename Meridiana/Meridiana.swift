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
    var calcolato : Bool = false;
    var elementi = [Segno]()
    
    func calcola() {
        let tracciaStilo : TracciaStilo = TracciaStilo(model: self.theModel!, ridotto: false)
        elementi.append(tracciaStilo)
        
        for var h = 0; h < 24; h++ {
            do {
                var l: LineaOraria
                try l = LineaOraria(theModel:theModel!, ha:Utils.deg2rad((Double(h)-12)*15.0), ridotto:false)
                elementi.append(l)
            } catch LineaOrariaError.NoPoints {
 
            } catch {
                
            }
        }
        for var m = -3; m <= 3; m++ {
            do {
                var l: LineaStagionale
                try l = LineaStagionale(theModel: theModel!, mesi: Double(m), ridotto: false)
                elementi.append(l)
            } catch {
                
            }
        }
        calcolato = true
        for elemento in self.elementi {
            let elementBounds : CGRect = elemento.getBounds()
            boundingBox = CGRectUnion((boundingBox == nil ? elementBounds : boundingBox!), elementBounds)
        }
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
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        var layer: CGLayer?
        var layerContext: CGContext?
        var thisFrame = CGRectZero
        let containerFrame = self.frame
        if (calcolato) {
            let content_ratio = Double(boundingBox!.size.width) / Double(boundingBox!.size.height)
            let container_ratio = Double(containerFrame.size.width) / Double(containerFrame.size.height)
            thisFrame.size.width = CGFloat(Double(boundingBox!.width)) / CGFloat(min(1.0,content_ratio/container_ratio))
            thisFrame.size.height = boundingBox!.height * CGFloat(max(1.0,content_ratio/container_ratio))
            let ratio = max(boundingBox!.size.width/containerFrame.size.width,boundingBox!.size.height/containerFrame.size.height)
            //let ratio: CGFloat = min(thisFrame.size.height/containerFrame.height, thisFrame.size.width/containerFrame.width)
            //let ratio: CGFloat = CGFloat(content_ratio/container_ratio)
            
            //self.setBoundsSize(thisFrame.size)
            saveGState { ctx in
                layer = CGLayerCreateWithContext(ctx, self.bounds.size, nil)!
                layerContext = CGLayerGetContext(layer)!
                CGContextTranslateCTM(layerContext, -self.boundingBox!.origin.x/ratio, -self.boundingBox!.origin.y/ratio)
                CGContextBeginPath(layerContext)
                CGContextSetLineWidth(layerContext,CGFloat(1.0))
                for elemento in self.elementi {
                    if elemento is LineaOraria || elemento is LineaStagionale {
                        elemento.draw(layerContext!, scale: CGFloat(1.0/ratio))
                    }
                }
                CGContextStrokePath(layerContext)
                CGContextBeginPath(layerContext);
                for elemento in self.elementi {
                    if elemento is TracciaStilo {
                        elemento.draw(layerContext!, scale: CGFloat(1.0/ratio))
                    }
                }
                CGContextStrokePath(layerContext)
                //CGContextTranslateCTM(ctx, -bbox.origin.x, 0)
                
                //var origin : CGPoint = CGPoint(x: -bbox.origin.x, y: 0)
                
            }
            
            saveGState { ctx in
                CGContextDrawLayerAtPoint(ctx, CGPointZero, layer);

            }
        }
    }
    
}
