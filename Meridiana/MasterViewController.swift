//
//  MasterViewController.swift
//  Meridiana
//
//  Created by Francesco Meschia on 9/30/15.
//  Copyright © 2015 Francesco Meschia. All rights reserved.
//

import Cocoa

class MasterViewController: NSViewController {

    var theModel : MeridianaModel?
    
    @IBOutlet weak var meridiana: Meridiana!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        theModel = MeridianaModel()
        meridiana.theModel = theModel
        meridiana.calcola()
    }
    
}
