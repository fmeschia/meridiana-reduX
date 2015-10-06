//
//  Document.swift
//  Meridiana
//
//  Created by Francesco Meschia on 10/3/15.
//  Copyright © 2015 Francesco Meschia. All rights reserved.
//

import Cocoa
import CoreLocation

class Document: NSDocument, CLLocationManagerDelegate {
    var theModel : MeridianaModel?
    
    var locationFix : Bool = false
    
    @IBOutlet weak var meridiana: Meridiana!
    
    var theLocationManager : CLLocationManager?
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }
    
    func changeMeridianaModel() {
        undoManager?.registerUndoWithTarget(self, selector: Selector("setFromDict:"), object: theModel?.toDictionary())
        setMeridianaModel()
    }
    
    func setFromDict(dictionary: NSDictionary) {
        undoManager?.registerUndoWithTarget(self, selector: Selector("setFromDict:"), object: theModel?.toDictionary())
        theModel? = MeridianaModel.fromDictionary(dictionary)
        meridiana.theModel = theModel
        meridiana.calcola()
        updateFields()
        meridiana.needsDisplay = true
    }
    
    func setMeridianaModel() {
        
        theModel!.lambda = Utils.deg2rad(longitudeField.doubleValue)*(longitudeEastButton.state == NSOnState ? 1.0 : -1.0)
        theModel!.lambdar = Utils.deg2rad(referenceLongitudeField.doubleValue)*(referenceLongitudeEastButton.state == NSOnState ? 1.0 : -1.0)
        theModel!.fi = Utils.deg2rad(latitudeField.doubleValue)*(latitudeNorthButton.state == NSOnState ? 1.0 : -1.0)
        theModel!.iota = Utils.deg2rad(inclinationField.doubleValue)
        theModel!.delta = Utils.deg2rad(declinationField.doubleValue)*(declinationEastButton.state != NSOnState ? 1.0 : -1.0)
        theModel!.calcPrelim()
        meridiana.theModel = theModel
        meridiana.calcola()
        meridiana.needsDisplay = true
    }
    
    func updateFields() {
        latitudeField.doubleValue = Utils.rad2deg(abs(theModel!.fi))
        if theModel!.fi >= 0.0 {
            latitudeNorthButton.state = NSOnState
        } else {
            latitudeSouthButton.state = NSOnState
        }
        longitudeField.doubleValue = Utils.rad2deg(abs(theModel!.lambda))
        if theModel!.lambda >= 0.0 {
            longitudeEastButton.state = NSOnState
        } else {
            longitudeWestButton.state = NSOnState
        }
        referenceLongitudeField.doubleValue = Utils.rad2deg(abs(theModel!.lambdar))
        if theModel!.lambdar >= 0.0 {
            referenceLongitudeEastButton.state = NSOnState
        } else {
            referenceLongitudeWestButton.state = NSOnState
        }
        inclinationField.doubleValue = Utils.rad2deg(theModel!.iota)
        declinationField.doubleValue = Utils.rad2deg(abs(theModel!.delta))
        if theModel!.delta < 0.0 {
            declinationWestButton.state = NSOnState
        } else {
            declinationEastButton.state = NSOnState
        }
    }
    
    func locationManager(_manager: CLLocationManager,
        didUpdateLocations locations: [AnyObject]) {
        if (!locationFix) {
            let location = locations.last
            let coord = location!.coordinate
            latitudeField.floatValue = Float(abs(coord.latitude))
            if coord.latitude >= 0.0 {
                latitudeNorthButton.state = NSOnState
            } else {
                latitudeSouthButton.state = NSOnState
            }
            longitudeField.floatValue = Float(abs(coord.longitude))
            if coord.longitude >= 0.0 {
                longitudeEastButton.state = NSOnState
            } else {
                longitudeWestButton.state = NSOnState
            }
            let tz = CFTimeZoneCopySystem()
            let hoursFromGMT = CFTimeZoneGetSecondsFromGMT(tz, CFAbsoluteTimeGetCurrent()) / 3600.0
            referenceLongitudeField.doubleValue = abs(15.0 * hoursFromGMT)
            if hoursFromGMT >= 0.0 {
                referenceLongitudeEastButton.state = NSOnState
            } else {
                referenceLongitudeWestButton.state = NSOnState
            }
            declinationWestButton.state = NSOnState
            theLocationManager!.stopUpdatingLocation()
            locationFix = true
            setMeridianaModel()
        }
    }
    
    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
        theModel = MeridianaModel()
        meridiana.theModel = theModel

        let autorizationStatus = CLLocationManager.authorizationStatus()
        if (autorizationStatus != CLAuthorizationStatus.Denied) {
            theLocationManager = CLLocationManager()
            theLocationManager!.desiredAccuracy = kCLLocationAccuracyKilometer
            theLocationManager!.delegate = self
            theLocationManager!.startUpdatingLocation()
        }
        inclinationField.doubleValue = 0.0
        declinationField.doubleValue = 0.0
        //meridiana.calcola()
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
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func readFromData(data: NSData, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }
    
    @IBAction func latitudeAction(sender: AnyObject) {
        let value = latitudeField.doubleValue * (latitudeNorthButton.state == NSOnState ? 1.0 : -1.0)
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.fi) > 0.001 {
            changeMeridianaModel()
        }
    }
    @IBAction func longitudeAction(sender: AnyObject) {
        let value = longitudeField.doubleValue * (longitudeEastButton.state == NSOnState ? 1.0 : -1.0)
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.lambda) > 0.001 {
            changeMeridianaModel()
        }
    }
    @IBAction func referenceLongitudeAction(sender: AnyObject) {
        let value = referenceLongitudeField.doubleValue * (referenceLongitudeEastButton.state == NSOnState ? 1.0 : -1.0)
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.lambdar) > 0.001 {
            changeMeridianaModel()
        }
    }
    @IBAction func declinationAction(sender: AnyObject) {
        let value = declinationField.doubleValue * (declinationEastButton.state == NSOnState ? 1.0 : -1.0)
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.delta) > 0.001 {
            changeMeridianaModel()
        }
    }
    @IBAction func inclinationAction(sender: AnyObject) {
        let value = inclinationField.doubleValue
        if abs(Utils.deg2rad(value) - meridiana!.theModel!.iota) > 0.001 {
            changeMeridianaModel()
        }
    }
    @IBOutlet weak var declinationEastButton: NSButton!
    @IBOutlet weak var declinationWestButton: NSButton!
    @IBOutlet weak var longitudeEastButton: NSButton!
    @IBOutlet weak var longitudeWestButton: NSButton!
    @IBOutlet weak var latitudeSouthButton: NSButton!
    @IBOutlet weak var latitudeNorthButton: NSButton!
    @IBOutlet weak var referenceLongitudeWestButton: NSButton!
    @IBOutlet weak var referenceLongitudeEastButton: NSButton!
    @IBOutlet weak var longitudeField: NSTextField!
    @IBOutlet weak var latitudeField: NSTextFieldCell!
    @IBOutlet weak var inclinationField: NSTextField!
    @IBOutlet weak var declinationField: NSTextField!
    @IBOutlet weak var referenceLongitudeField: NSTextField!
}

