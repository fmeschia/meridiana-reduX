//
//  Document.swift
//  Meridiana
//
//  Created by Francesco Meschia on 10/3/15.
//  Copyright © 2015 Francesco Meschia. All rights reserved.
//

import Cocoa
import CoreLocation
import CoreData

class Document: NSDocument, CLLocationManagerDelegate {
    var theModel : MeridianaModel = MeridianaModel()
    
    var printableMeridiana : Meridiana?
    
    var locationFix : Bool = false
    
    @IBOutlet var meridiana: Meridiana!
    
    var theLocationManager : CLLocationManager?
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }
    
    convenience init(type typeName: String) throws {
        self.init()
        fileType = typeName
        // add your own initialisation for new document here
        /*
        let autorizationStatus = CLLocationManager.authorizationStatus()
        if (autorizationStatus != CLAuthorizationStatus.Denied) {
            theLocationManager = CLLocationManager()
            theLocationManager!.desiredAccuracy = kCLLocationAccuracyKilometer
            theLocationManager!.delegate = self
            theLocationManager!.startUpdatingLocation()
        }
*/
    }
    
    override func printOperationWithSettings(_ printSettings: [String : AnyObject]) throws -> NSPrintOperation {
        setUpPrintObject()
        let printInfo = self.printInfo
        let imageableBounds = printInfo.imageablePageBounds
        printInfo.horizontalPagination = NSPrintingPaginationMode.AutoPagination
        printInfo.verticalPagination = NSPrintingPaginationMode.AutoPagination
        printInfo.leftMargin = max(1,printInfo.imageablePageBounds.origin.x)
        printInfo.bottomMargin = max(1,printInfo.imageablePageBounds.origin.y)
        printInfo.rightMargin = max(1,printInfo.paperSize.width - printInfo.imageablePageBounds.width - printInfo.imageablePageBounds.origin.x)
        printInfo.topMargin = max(1, printInfo.paperSize.height - printInfo.imageablePageBounds.height - printInfo.imageablePageBounds.origin.y)
        let op : NSPrintOperation = NSPrintOperation(view: printableMeridiana!, printInfo: printInfo)
        return op
    }
    
    /*
    override func printDocument(sender: AnyObject?) {
        super.printDocument(sender)
        setUpPrintObject()
        let op : NSPrintOperation? = NSPrintOperation(view: printableMeridiana!)
        op!.printInfo.horizontalPagination = NSPrintingPaginationMode.AutoPagination
        op!.printInfo.verticalPagination = NSPrintingPaginationMode.AutoPagination
        op!.printInfo.leftMargin = op!.printInfo.imageablePageBounds.origin.x
        op!.printInfo.rightMargin = op!.printInfo.paperSize.width - op!.printInfo.imageablePageBounds.width - op!.printInfo.imageablePageBounds.origin.x
        op!.printInfo.topMargin = op!.printInfo.paperSize.height - op!.printInfo.imageablePageBounds.height - op!.printInfo.imageablePageBounds.origin.y
        op!.printInfo.bottomMargin = op!.printInfo.imageablePageBounds.origin.y
        if op != nil {
            op!.runOperation()
        }
        
    }
*/
    
    func setUpPrintObject() {
        printableMeridiana = Meridiana()
        printableMeridiana?.ridotto = false
        printableMeridiana?.theModel = theModel
        printableMeridiana?.calcola()
        printableMeridiana?.setFrameSize(NSSize(width:(printableMeridiana?.boundingBox?.width)!, height:(printableMeridiana?.boundingBox?.height)!))
    }
    
    func changeMeridianaModel() {
        undoManager?.registerUndoWithTarget(self, selector: Selector("setFromDict:"), object: theModel.toDictionary())
        //theModel = MeridianaModel()
        setMeridianaModel()
        meridiana.needsDisplay = true
    }
    
    func setFromDict(dictionary: NSDictionary) {
        undoManager?.registerUndoWithTarget(self, selector: Selector("setFromDict:"), object: theModel.toDictionary())
        theModel.fromDictionary(dictionary)
        meridiana.theModel = theModel
        meridiana.calcola()
        updateFields()
        meridiana.needsDisplay = true
    }
    
    func setMeridianaModel() {
        
        theModel.lambda = Utils.deg2rad(longitudeField.doubleValue)*(longitudeEastButton.state == NSOnState ? 1.0 : -1.0)
        theModel.lambdar = Utils.deg2rad(referenceLongitudeField.doubleValue)*(referenceLongitudeEastButton.state == NSOnState ? 1.0 : -1.0)
        theModel.fi = Utils.deg2rad(latitudeField.doubleValue)*(latitudeNorthButton.state == NSOnState ? 1.0 : -1.0)
        theModel.iota = Utils.deg2rad(inclinationField.doubleValue)
        theModel.delta = Utils.deg2rad(declinationField.doubleValue)*(declinationEastButton.state == NSOnState ? 1.0 : -1.0)
        theModel.altezza = styleHeightField.doubleValue
        theModel.calcPrelim()
        meridiana.theModel = theModel
        meridiana.calcola()
        meridiana.needsDisplay = true
    }
    
    func updateFields() {
        latitudeField.doubleValue = Utils.rad2deg(abs(theModel.fi))
        if theModel.fi >= 0.0 {
            latitudeNorthButton.state = NSOnState
        } else {
            latitudeSouthButton.state = NSOnState
        }
        longitudeField.doubleValue = Utils.rad2deg(abs(theModel.lambda))
        if theModel.lambda >= 0.0 {
            longitudeEastButton.state = NSOnState
        } else {
            longitudeWestButton.state = NSOnState
        }
        referenceLongitudeField.doubleValue = Utils.rad2deg(abs(theModel.lambdar))
        if theModel.lambdar >= 0.0 {
            referenceLongitudeEastButton.state = NSOnState
        } else {
            referenceLongitudeWestButton.state = NSOnState
        }
        inclinationField.doubleValue = Utils.rad2deg(theModel.iota)
        declinationField.doubleValue = Utils.rad2deg(abs(theModel.delta))
        if theModel.delta <= 0.0 {
            declinationWestButton.state = NSOnState
        } else {
            declinationEastButton.state = NSOnState
        }
        styleHeightField.doubleValue = theModel.altezza
    }
    
    func locationManager(_manager: CLLocationManager,
        didUpdateLocations locations: [AnyObject]) {
        if (!locationFix) {
            let location = locations.last
            let coord = location!.coordinate
            theModel.fi = Utils.deg2rad(coord.latitude)
            theModel.lambda = Utils.deg2rad(coord.longitude)
            let tz = CFTimeZoneCopySystem()
            let now = CFAbsoluteTimeGetCurrent()
            let hoursFromGMT = (CFTimeZoneGetSecondsFromGMT(tz, now) + (CFTimeZoneIsDaylightSavingTime(tz,now) ? -CFTimeZoneGetDaylightSavingTimeOffset(tz, now) : 0)) / 3600.0
            theModel.lambdar = Utils.deg2rad(15.0 * hoursFromGMT)
            theModel.calcPrelim()
            theLocationManager!.stopUpdatingLocation()
            locationFix = true
            if (meridiana.theModel != nil) {
                meridiana.calcola()
                updateFields()
                meridiana.needsDisplay = true
            }
        }
    }
    
    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        meridiana.theModel = theModel
        meridiana.calcola()
        updateFields()
        //changeMeridianaModel()
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }

    override func dataOfType(typeName: String) throws -> NSData {
        let orig = theModel.toDictionary()
        let data : NSData = NSKeyedArchiver.archivedDataWithRootObject(orig)
        return data
    }

    override func readFromData(data: NSData, ofType typeName: String) throws {
        let dict = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! NSDictionary
        theModel = MeridianaModel()
        theModel.fromDictionary(dict)
    }
    
    @IBAction func latitudeAction(sender: AnyObject) {
        let value = latitudeField.doubleValue * (latitudeNorthButton.state == NSOnState ? 1.0 : -1.0)
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.fi) > 0.000018 {
            changeMeridianaModel()
        }
    }
    @IBAction func longitudeAction(sender: AnyObject) {
        let value = longitudeField.doubleValue * (longitudeEastButton.state == NSOnState ? 1.0 : -1.0)
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.lambda) > 0.000018 {
            changeMeridianaModel()
        }
    }
    @IBAction func referenceLongitudeAction(sender: AnyObject) {
        let value = referenceLongitudeField.doubleValue * (referenceLongitudeEastButton.state == NSOnState ? 1.0 : -1.0)
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.lambdar) > 0.000018 {
            changeMeridianaModel()
        }
    }
    @IBAction func declinationAction(sender: AnyObject) {
        let value = declinationField.doubleValue * (declinationEastButton.state == NSOnState ? 1.0 : -1.0)
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.delta) > 0.000018 {
            changeMeridianaModel()
        }
    }
    @IBAction func inclinationAction(sender: AnyObject) {
        let value = inclinationField.doubleValue
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.iota) > 0.000018 {
            changeMeridianaModel()
        }
    }
    @IBAction func styleHeightAction(sender: NSTextField) {
        setMeridianaModel()
    }
    @IBOutlet  var styleHeightField: NSTextField!
    @IBOutlet  var declinationEastButton: NSButton!
    @IBOutlet  var declinationWestButton: NSButton!
    @IBOutlet  var longitudeEastButton: NSButton!
    @IBOutlet  var longitudeWestButton: NSButton!
    @IBOutlet  var latitudeSouthButton: NSButton!
    @IBOutlet  var latitudeNorthButton: NSButton!
    @IBOutlet  var referenceLongitudeWestButton: NSButton!
    @IBOutlet  var referenceLongitudeEastButton: NSButton!
    @IBOutlet  var longitudeField: NSTextField!
    @IBOutlet  var latitudeField: NSTextFieldCell!
    @IBOutlet  var inclinationField: NSTextField!
    @IBOutlet  var declinationField: NSTextField!
    @IBOutlet  var referenceLongitudeField: NSTextField!
}

