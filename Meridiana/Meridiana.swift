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
        boundingBox = CGRect.zero
        let tracciaStilo : TracciaStilo = TracciaStilo(model: self.theModel!, ridotto: ridotto)
        elementi.append(tracciaStilo)
        
        for h in 0 ..< 24 {
            do {
                var l: LineaOraria
                try l = LineaOraria(theModel:theModel!, ha:Utils.deg2rad((Double(h)-12)*15.0), ridotto:ridotto)
                l.lemniscata = theModel!.lineaOrariaLemniscata[elementi.count]
                elementi.append(l)
            } catch LineaOrariaError.noPoints {
 
            } catch {
                
            }
        }
        for m in -3...3 {
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
            boundingBox = (boundingBox == nil ? elementBounds : boundingBox!).union(elementBounds)
        }
        boundingBox = boundingBox!.insetBy(dx: -20, dy: -20)
        if (ridotto) {
            boundingBox = CGRect(origin: boundingBox!.origin, size:CGSize(width:boundingBox!.width, height:550))
        }
        /*
        let alert = NSAlert()
        alert.messageText = "Warning"
        alert.addButtonWithTitle("Yes")
        alert.addButtonWithTitle("No")
        alert.informativeText = "Bounding box width=\(boundingBox!.width)"
        alert.runModal()
        */
 
        /*
        if (ridotto) {
            self.setFrameSize(CGSize(width: 600, height: boundingBox!.height))
        } else {
            self.setFrameSize(CGSize(width: boundingBox!.width, height: boundingBox!.height))
        }
        */
    }
    
    /*
    fileprivate var currentContext : CGContext? {
        get {
            if #available(OSX 10.10, *) {
                return NSGraphicsContext.current()?.cgContext
            } else if let contextPointer = NSGraphicsContext.current()?.graphicsPort {
                let context: CGContext = Unmanaged.fromOpaque(OpaquePointer(contextPointer)).takeUnretainedValue()
                return context
            }
            
            return nil
        }
    }
     */
    
    fileprivate func saveGState(_ drawStuff: (_ ctx:CGContext) -> ()) -> () {
        if let context = NSGraphicsContext.current()?.cgContext {
            context.saveGState ()
            drawStuff(context)
            context.restoreGState ()
        }
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        var location: CGPoint = theEvent.locationInWindow
        location = self.convert(location, from: nil)
        location.x -= 300/ratio
        location.y -= -self.boundingBox!.origin.y/ratio
        for elemento in elementi {
            if elemento is LineaOraria {
                if (elemento as! LineaOraria).contiene(location, scale: CGFloat(1.0/ratio)) {
                    (elemento as! LineaOraria).premuto = true
                    self.needsDisplay = true
                    break
                }
            }
        }
    }
    
    func toggleLemniscata(_ params: NSDictionary) {
        undoManager?.registerUndo(withTarget: self, selector: #selector(Meridiana.toggleLemniscata(_:)), object: params)
        (params["elemento"] as! LineaOraria).lemniscata = !(params["elemento"] as! LineaOraria).lemniscata
        theModel!.lineaOrariaLemniscata[(params["index"] as! Int)] = !theModel!.lineaOrariaLemniscata[(params["index"] as! Int)]
        self.needsDisplay = true
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        var location: CGPoint = theEvent.locationInWindow
        location = self.convert(location, from: nil)
        location.x -= 300/ratio
        location.y -= -self.boundingBox!.origin.y/ratio
        for (index, elemento) in elementi.enumerated() {
            if elemento is LineaOraria {
                (elemento as! LineaOraria).premuto = false
                if (elemento as! LineaOraria).contiene(location, scale: CGFloat(1.0/ratio)) {
                    if (elemento as! LineaOraria).tutto {
                        toggleLemniscata(["elemento":(elemento as! LineaOraria), "index":index])
                        //(elemento as! LineaOraria).lemniscata = !(elemento as! LineaOraria).lemniscata
                        //theModel?.lineaOrariaLemniscata[index] = !theModel!.lineaOrariaLemniscata[index]
                        break
                    }
                }
            }
        }
    }

    override func drawPageBorder(with borderSize: NSSize) {
        let savedFrame = frame
        let info: NSPrintInfo = NSPrintOperation.current()!.printInfo
        let imageableBounds = info.imageablePageBounds
        setFrameOrigin(info.imageablePageBounds.origin)
        setFrameSize(info.imageablePageBounds.size)
        let imageableHeight = info.imageablePageBounds.size.height
        let imageableWidth = info.imageablePageBounds.size.width
        lockFocus()
        saveGState { ctx in
            ctx.translateBy(x: info.imageablePageBounds.origin.x, y: info.imageablePageBounds.origin.y)
            ctx.setLineWidth(CGFloat(1.0))
            ctx.move(to: CGPoint(x: 0, y: imageableHeight-10))
            ctx.addLine(to: CGPoint(x: 0, y: imageableHeight+10))
            ctx.move(to: CGPoint(x: -10, y: imageableHeight))
            ctx.addLine(to: CGPoint(x: 10, y: imageableHeight))
            ctx.strokePath()
            ctx.beginPath()
            ctx.setLineWidth(CGFloat(1.0))
            ctx.move(to: CGPoint(x: imageableWidth, y: imageableHeight-10))
            ctx.addLine(to: CGPoint(x: imageableWidth, y: imageableHeight+10))
            ctx.move(to: CGPoint(x: imageableWidth+10, y: imageableHeight))
            ctx.addLine(to: CGPoint(x: imageableWidth-10, y: imageableHeight))
            ctx.strokePath()
            ctx.strokePath()
            ctx.beginPath()
            ctx.setLineWidth(CGFloat(1.0))
            ctx.move(to: CGPoint(x: imageableWidth, y: 10))
            ctx.addLine(to: CGPoint(x: imageableWidth, y: -10))
            ctx.move(to: CGPoint(x: imageableWidth+10, y: 0))
            ctx.addLine(to: CGPoint(x: imageableWidth-10, y: 0))
            ctx.strokePath()
            ctx.beginPath()
            ctx.setLineWidth(CGFloat(1.0))
            ctx.move(to: CGPoint(x: 0, y: 10))
            ctx.addLine(to: CGPoint(x: 0, y: -10))
            ctx.move(to: CGPoint(x: -10, y: 0))
            ctx.addLine(to: CGPoint(x: 10, y: 0))
            ctx.strokePath()
            ctx.textMatrix = CGAffineTransform.identity
            let pageNumber = NSPrintOperation.current()?.currentPage
            let attrs: NSDictionary = [NSFontAttributeName:CTFontCreateWithName("Helvetica" as CFString?, 9, nil)]
            let attrString : CFAttributedString =
            CFAttributedStringCreate(kCFAllocatorDefault,"H:\(self.getPageH(pageNumber!)) V:\(self.getPageV(pageNumber!))" as CFString!, attrs)
            let line = CTLineCreateWithAttributedString(attrString)
            let textBounds = CTLineGetImageBounds(line, ctx)
            ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1)
            ctx.textPosition = CGPoint(x:5, y:imageableHeight-textBounds.height-5)
            //CGContextSetTextPosition(ctx, 5, imageableHeight-textBounds.height-5)
            CTLineDraw(line, ctx)
        }
  
        unlockFocus()
        setFrameOrigin(savedFrame.origin)
        setFrameSize(savedFrame.size)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if (calcolato) {
            saveGState { ctx in
                if !NSGraphicsContext.currentContextDrawingToScreen() {
                    ctx.translateBy(x: -self.boundingBox!.origin.x, y: -self.boundingBox!.origin.y)
                } else {
                    ctx.translateBy(x: 300 , y: -self.boundingBox!.origin.y)
                }

                
                for elemento in self.elementi {
                    if elemento is LineaOraria || elemento is LineaStagionale {
                        ctx.beginPath()
                        ctx.setLineWidth(CGFloat(0.5))
                        //CGContextSetAllowsAntialiasing(layerContext, true)
                        //CGContextSetShouldAntialias(layerContext, true)
                        elemento.draw(ctx, scale: CGFloat(1.0/self.ratio))
                        ctx.strokePath()
                    }
                }
                ctx.beginPath()
                for elemento in self.elementi {
                    if elemento is TracciaStilo {
                        elemento.draw(ctx, scale: CGFloat(1.0/self.ratio))
                        break
                    }
                }
                ctx.strokePath()

            }
        }
    }
    
    override func knowsPageRange(_ range: NSRangePointer) -> Bool {
        let horizontalPages = getHorizontalPages()
        let verticalPages = getVerticalPages()
        let rangeOut = NSRange(location: 1, length: horizontalPages*verticalPages)
        range.pointee = rangeOut
        return true
    }
    
    override func rectForPage(_ page: Int) -> NSRect {
        let printHeight : CGFloat = calculatePrintHeight()
        let printWidth : CGFloat = calculatePrintWidth()
        let horizontalPages = getHorizontalPages()
        let horizontalPage = (page-1) % horizontalPages
        let verticalPage: Int = (page-1) / horizontalPages
        //let out = NSMakeRect(self.boundingBox!.origin.x+printWidth*CGFloat(horizontalPage), self.boundingBox!.origin.y+self.boundingBox!.height-printHeight*CGFloat(verticalPage+1), printWidth, printHeight)
        let out = NSMakeRect(printWidth*CGFloat(horizontalPage), boundingBox!.height-printHeight*CGFloat(verticalPage+1), printWidth, printHeight)
        return out
    }
    
    func getHorizontalPages() -> Int {
        let printWidth : CGFloat = calculatePrintWidth()
        let horizontalPages: Int = Int(ceil(self.boundingBox!.width / printWidth))
        return horizontalPages
    }
    
    func getVerticalPages() -> Int {
        let printHeight : CGFloat = calculatePrintHeight()
        let verticalPages: Int = Int(ceil(self.boundingBox!.height / printHeight))
        return verticalPages
    }
    
    func getPagePosition(_ pageIn: Int, pageH: Int, pageV: Int) {
        var pageH = pageH, pageV = pageV
        let horizontalPages = getHorizontalPages()
        pageH = 1 + (pageIn - 1) % horizontalPages
        pageV = 1 + (pageIn - 1) / horizontalPages
    }
    
    func getPageH(_ pageNumber: Int) -> Int {
        let out = 1 + (pageNumber - 1) % getHorizontalPages()
        return out
    }
    
    func getPageV(_ pageNumber: Int) -> Int {
        let out = 1 + (pageNumber - 1) / getVerticalPages()
        return out
    }

    func calculatePrintHeight () -> CGFloat{
        let info: NSPrintInfo = NSPrintOperation.current()!.printInfo
        let paperSize : NSSize = info.paperSize
        let pageHeight : CGFloat = paperSize.height - info.topMargin - info.bottomMargin
        let dict = info.dictionary()
        let scaleFromInfo = (dict["NSScalingFactor"] as! CGFloat)
        let scale = CGFloat(1.0)

        //let scale : CGFloat = info.dictionary()["NSPrintScalingFactor"] as! CGFloat
        return CGFloat(pageHeight / scale)
    }

    func calculatePrintWidth () -> CGFloat{
        let info: NSPrintInfo = NSPrintOperation.current()!.printInfo
        let paperSize : NSSize = info.paperSize
        let pageWidth : CGFloat = paperSize.width - info.leftMargin - info.rightMargin
        let scale = CGFloat(1.0)
        //let scale : CGFloat = info.dictionary()["NSPrintScalingFactor"] as! CGFloat
        return CGFloat(pageWidth / scale)
    }

    
}
