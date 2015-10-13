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
    var ridotto : Bool = true
    
    override var intrinsicContentSize: NSSize { return CGSize(width: 600, height: 550) }
    
    func calcola() {
        elementi = [Segno]()
        boundingBox = CGRectZero
        let tracciaStilo : TracciaStilo = TracciaStilo(model: self.theModel!, ridotto: ridotto)
        elementi.append(tracciaStilo)
        
        for var h = 0; h < 24; h++ {
            do {
                var l: LineaOraria
                try l = LineaOraria(theModel:theModel!, ha:Utils.deg2rad((Double(h)-12)*15.0), ridotto:ridotto)
                l.lemniscata = theModel!.lineaOrariaLemniscata[elementi.count]
                elementi.append(l)
            } catch LineaOrariaError.NoPoints {
 
            } catch {
                
            }
        }
        for var m = -3; m <= 3; m++ {
            do {
                var l: LineaStagionale
                try l = LineaStagionale(theModel: theModel!, mesi: Double(m), ridotto: ridotto)
                elementi.append(l)
            } catch {
                
            }
        }
        calcolato = true
        for elemento in self.elementi {
            let elementBounds : CGRect = elemento.getBounds()
            boundingBox = CGRectUnion((boundingBox == nil ? elementBounds : boundingBox!), elementBounds)
        }
        boundingBox = CGRectInset(boundingBox!, -20, -20)
        if (ridotto) {
            boundingBox = CGRect(origin: boundingBox!.origin, size:CGSize(width:boundingBox!.width, height:550))
        }
        if (ridotto) {
            self.setFrameSize(CGSize(width: 600, height: boundingBox!.height))
        } else {
            self.setFrameSize(CGSize(width: boundingBox!.width, height: boundingBox!.height))
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
    
    func toggleLemniscata(params: NSDictionary) {
        undoManager?.registerUndoWithTarget(self, selector: Selector("toggleLemniscata:"), object: params)
        (params["elemento"] as! LineaOraria).lemniscata = !(params["elemento"] as! LineaOraria).lemniscata
        theModel!.lineaOrariaLemniscata[(params["index"] as! Int)] = !theModel!.lineaOrariaLemniscata[(params["index"] as! Int)]
        self.needsDisplay = true
    }
    
    override func mouseUp(theEvent: NSEvent) {
        var location: CGPoint = theEvent.locationInWindow
        location = self.convertPoint(location, fromView: nil)
        location.x -= 300/ratio
        location.y -= -self.boundingBox!.origin.y/ratio
        for (index, elemento) in elementi.enumerate() {
            if elemento is LineaOraria {
                (elemento as! LineaOraria).premuto = false
                if (elemento as! LineaOraria).contiene(location, scale: CGFloat(1.0/ratio)) {
                    if (elemento as! LineaOraria).tutto {
                        toggleLemniscata(["elemento":(elemento as! LineaOraria), "index":index])
                        //(elemento as! LineaOraria).lemniscata = !(elemento as! LineaOraria).lemniscata
                        //theModel?.lineaOrariaLemniscata[index] = !theModel!.lineaOrariaLemniscata[index]
                    }
                }
            }
        }
    }

    override func drawPageBorderWithSize(borderSize: NSSize) {
        let savedFrame = frame
        let info: NSPrintInfo = NSPrintOperation.currentOperation()!.printInfo
        let imageableBounds = info.imageablePageBounds
        setFrameOrigin(info.imageablePageBounds.origin)
        setFrameSize(info.imageablePageBounds.size)
        let imageableHeight = info.imageablePageBounds.size.height
        let imageableWidth = info.imageablePageBounds.size.width
        lockFocus()
        saveGState { ctx in
            CGContextTranslateCTM(ctx, info.imageablePageBounds.origin.x, info.imageablePageBounds.origin.y)
            CGContextSetLineWidth(ctx,CGFloat(1.0))
            CGContextMoveToPoint(ctx, 0, imageableHeight-10)
            CGContextAddLineToPoint(ctx, 0, imageableHeight+10)
            CGContextMoveToPoint(ctx,-10, imageableHeight)
            CGContextAddLineToPoint(ctx, 10, imageableHeight)
            CGContextStrokePath(ctx)
            CGContextBeginPath(ctx)
            CGContextSetLineWidth(ctx,CGFloat(1.0))
            CGContextMoveToPoint(ctx, imageableWidth, imageableHeight-10)
            CGContextAddLineToPoint(ctx, imageableWidth, imageableHeight+10)
            CGContextMoveToPoint(ctx, imageableWidth+10, imageableHeight)
            CGContextAddLineToPoint(ctx, imageableWidth-10, imageableHeight)
            CGContextStrokePath(ctx)
            CGContextStrokePath(ctx)
            CGContextBeginPath(ctx)
            CGContextSetLineWidth(ctx,CGFloat(1.0))
            CGContextMoveToPoint(ctx, imageableWidth, 10)
            CGContextAddLineToPoint(ctx, imageableWidth, -10)
            CGContextMoveToPoint(ctx, imageableWidth+10, 0)
            CGContextAddLineToPoint(ctx, imageableWidth-10, 0)
            CGContextStrokePath(ctx)
            CGContextBeginPath(ctx)
            CGContextSetLineWidth(ctx,CGFloat(1.0))
            CGContextMoveToPoint(ctx, 0, 10)
            CGContextAddLineToPoint(ctx, 0, -10)
            CGContextMoveToPoint(ctx, -10, 0)
            CGContextAddLineToPoint(ctx, 10, 0)
            CGContextStrokePath(ctx)
        }
  
        unlockFocus()
        setFrameOrigin(savedFrame.origin)
        setFrameSize(savedFrame.size)
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        if (calcolato) {
            saveGState { ctx in
                if !NSGraphicsContext.currentContextDrawingToScreen() {
                    CGContextTranslateCTM(ctx, -self.boundingBox!.origin.x, -self.boundingBox!.origin.y)
                } else {
                    CGContextTranslateCTM(ctx, 300 , -self.boundingBox!.origin.y)
                }

                for elemento in self.elementi {
                    if elemento is LineaOraria || elemento is LineaStagionale {
                        CGContextBeginPath(ctx);
                        CGContextSetLineWidth(ctx,CGFloat(0.5))
                        //CGContextSetAllowsAntialiasing(layerContext, true)
                        //CGContextSetShouldAntialias(layerContext, true)
                        elemento.draw(ctx, scale: CGFloat(1.0/self.ratio))
                        CGContextStrokePath(ctx)
                    }
                }
                CGContextBeginPath(ctx);
                for elemento in self.elementi {
                    if elemento is TracciaStilo {
                        elemento.draw(ctx, scale: CGFloat(1.0/self.ratio))
                    }
                }
                CGContextStrokePath(ctx)
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
    override func knowsPageRange(range: NSRangePointer) -> Bool {
        let printHeight : CGFloat = calculatePrintHeight()
        let printWidth : CGFloat = calculatePrintWidth()
        let horizontalPages: Int = Int(ceil(self.boundingBox!.width / printWidth))
        let verticalPages: Int = Int(ceil(self.boundingBox!.height / printHeight))
        let rangeOut = NSRange(location: 1, length: horizontalPages*verticalPages)
        range.memory = rangeOut
        return true
    }
    
    override func rectForPage(page: Int) -> NSRect {
        let printHeight : CGFloat = calculatePrintHeight()
        let printWidth : CGFloat = calculatePrintWidth()
        let horizontalPages: Int = Int(ceil(self.boundingBox!.width / printWidth))
        let horizontalPage: Int = (page-1) % horizontalPages
        let verticalPage: Int = (page-1) / horizontalPages
        //let out = NSMakeRect(self.boundingBox!.origin.x+printWidth*CGFloat(horizontalPage), self.boundingBox!.origin.y+self.boundingBox!.height-printHeight*CGFloat(verticalPage+1), printWidth, printHeight)
        let out = NSMakeRect(printWidth*CGFloat(horizontalPage), boundingBox!.height-printHeight*CGFloat(verticalPage+1), printWidth, printHeight)
        return out
    }
    
    func calculatePrintHeight () -> CGFloat{
        let info: NSPrintInfo = NSPrintOperation.currentOperation()!.printInfo
        let paperSize : NSSize = info.paperSize
        let pageHeight : CGFloat = paperSize.height - info.topMargin - info.bottomMargin
        let dict = info.dictionary()
        let scaleFromInfo = (dict["NSScalingFactor"] as! CGFloat)
        let scale = CGFloat(1.0)

        //let scale : CGFloat = info.dictionary()["NSPrintScalingFactor"] as! CGFloat
        return CGFloat(pageHeight / scale)
    }
    
    func calculatePrintWidth () -> CGFloat{
        let info: NSPrintInfo = NSPrintOperation.currentOperation()!.printInfo
        let paperSize : NSSize = info.paperSize
        let pageWidth : CGFloat = paperSize.width - info.leftMargin - info.rightMargin
        let scale = CGFloat(1.0)
        //let scale : CGFloat = info.dictionary()["NSPrintScalingFactor"] as! CGFloat
        return CGFloat(pageWidth / scale)
    }

    
}
