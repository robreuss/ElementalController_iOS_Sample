//
//  ViewController.swift
//  ElementalController_iOS_Sample
//
//  Created by Rob Reuss on 1/12/19.
//  Copyright © 2019 Rob Reuss. All rights reserved.
//

import UIKit
import ElementalController
import CoreMotion

class ViewController: UIViewController {
    
    // MARK: -
    // MARK: Vars
    
    // Define element identifiers which are transmitted with each
    // element message to identify the eleent to the recieving end
    let eid_forward: Int8 = 1
    let eid_backward: Int8 = 2
    let eid_right: Int8 = 3
    let eid_left: Int8 = 4
    let eid_speed: Int8 = 5
    let eid_motionX: Int8 = 6
    let eid_motionY: Int8 = 7
    let eid_motionZ: Int8 = 8
    
    // This is used as part of the NetService name when the service
    // is published, and used as the basis of browsing
    var serviceName = "robot"
    
    // A reference to the framework instance.  If you wish to publish
    // more than one service, or act as the client of more than one service,
    // you'll want more than one of these.
    var elementalController = ElementalController()
    
    // A client-specific reference, this refers to the server device
    // instance returned by the foundServer event.  It's "send" method
    // is used to send elements to the server.
    var serverDevice: ServerDevice?
    
    // For demo purposes
    let manager = CMMotionManager()
    
    // MARK: -
    // MARK: Just UI stuff
    @IBOutlet weak var browse: UIButton!
    @IBAction func browse(_ sender: Any) {
        elementalController.browser.browseFor(serviceName: serviceName)
        browse.setTitle("Browsing for \(serviceName)", for: .normal)
        service.setTitle("No service available", for: .normal)
    }
    
    @IBOutlet weak var service: UIButton!
    @IBAction func service(_ sender: Any) {
        if (serverDevice?.isConnected)! {
            serverDevice?.disconnect()
        } else {
            serverDevice?.connect()
        }
    }
    
    func sendDirection(eid: Int) {
        guard let device = serverDevice else { return }
        guard let element = device.getElementWith(identifier: Int8(eid)) else { return }
        element.doubleValue = 1.0
        do {
            try device.send(element: element)
        } catch {
            logDebug("Direction \(element.displayName) send failed: \(error)")
        }
    }
    
    @IBOutlet weak var speed: UILabel!
    @IBAction func speed(_ sender: Any) {
        guard let device = serverDevice else { return }
        guard let element = device.getElementWith(identifier: eid_speed) else { return }
        speed.text = "Speed is \((sender as! UISlider).value)"
        element.floatValue = (sender as! UISlider).value
        do {
            try device.send(element: element)
        } catch {
            logDebug("Speed send failed: \(error)")
        }
    }

    @IBAction func forward(_ sender: Any) {
        sendDirection(eid: (sender as! UIView).tag)
    }
    @IBAction func left(_ sender: Any) {
        sendDirection(eid: (sender as! UIView).tag)
    }
    @IBAction func right(_ sender: Any) {
        sendDirection(eid: (sender as! UIView).tag)
    }
    @IBAction func backwards(_ sender: Any) {
        sendDirection(eid: (sender as! UIView).tag)
    }
    
    @IBOutlet weak var motion: UIButton!
    @IBAction func motion(_ sender: Any) {
        guard let device = serverDevice else { return }
        if manager.isAccelerometerActive {
            manager.stopAccelerometerUpdates()
            motion.setTitle("Send motion data", for: .normal)
        } else if device.isConnected {
            motion.setTitle("Stop motion data", for: .normal)
            manager.accelerometerUpdateInterval = 1.0 / 60.0 // 60 hz
            guard let device = self.serverDevice else { return }
            guard let elementMotionX = device.getElementWith(identifier: self.eid_motionX) else { return }
            guard let elementMotionY = device.getElementWith(identifier: self.eid_motionY) else { return }
            guard let elementMotionZ = device.getElementWith(identifier: self.eid_motionZ) else { return }
            manager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                elementMotionX.doubleValue = (data?.acceleration.x)!
                do {
                    try device.send(element: elementMotionX)
                } catch {
                    logDebug("\(elementMotionX.displayName) send failed: \(error)")
                }
                elementMotionY.doubleValue = (data?.acceleration.y)!
                do {
                    try device.send(element: elementMotionY)
                } catch {
                    logDebug("\(elementMotionY.displayName) send failed: \(error)")
                }
                elementMotionZ.doubleValue = (data?.acceleration.z)!
                do {
                    try device.send(element: elementMotionZ)
                } catch {
                    logDebug("\(elementMotionZ.displayName) send failed: \(error)")
                }
            }
        }
        
    }
    
    // MARK: -
    // MARK: Core functionality
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Determines if networking occurs over IPv4 or IPv6
        ElementalController.protocolFamily = .inet6
        
        // Initializes the browser for use in setting up event handlers
        // Pass an empty string as the device name and the host name of your
        // device or machine will be used.
        elementalController.setupForBrowsingAs(deviceNamed: "My iPhone")
        
        // What to do when a server is found by the browser, in terms of defining the
        // elements and their respective handlers, before calling "connect" (see the "service"
        // IBAction above for calling the "connect" method.
        elementalController.browser.events.foundServer.handler { serverDevice in
            
            // Demo stuff
            self.browse.setTitle("Browse for \(self.serviceName)", for: .normal)
            self.service.setTitle("Connect to \(serverDevice.remoteServerAddress)", for: .normal)
            self.service.isEnabled = true
            
            // Keep a reference to this in order to send elements to the server
            self.serverDevice = serverDevice
            
            // Attach the elements to the server device.  Note that if you connect to more than
            // one server, you can have different elements and handlers per server
            let elementForward = serverDevice.attachElement(Element(identifier: self.eid_forward, displayName: "Forward", proto: .tcp, dataType: .Double))
            let elementBackward = serverDevice.attachElement(Element(identifier: self.eid_backward, displayName: "Backward", proto: .tcp, dataType: .Double))
            let elementRight = serverDevice.attachElement(Element(identifier: self.eid_right, displayName: "Right", proto: .tcp, dataType: .Double))
            let elementLeft = serverDevice.attachElement(Element(identifier: self.eid_left, displayName: "Left", proto: .tcp, dataType: .Double))
            let elementSpeed = serverDevice.attachElement(Element(identifier: self.eid_speed, displayName: "Speed", proto: .udp, dataType: .Float))
            let _ = serverDevice.attachElement(Element(identifier: self.eid_motionX, displayName: "Motion X", proto: .udp, dataType: .Double))
            let _ = serverDevice.attachElement(Element(identifier: self.eid_motionY, displayName: "Motion Y", proto: .udp, dataType: .Double))
            let _ = serverDevice.attachElement(Element(identifier: self.eid_motionZ, displayName: "Motion Z", proto: .udp, dataType: .Double))
            
            // The following handlers are generally not necessary - they are handlers when the server sends a
            // reply to our elements in a request/response model
            
            // Define our handler one time and apply it to muliple elements
            let directionHandler: Element.ElementHandler = { element, device in
                logDebug("Recieved response to \(element.displayName): \(element.doubleValue)")
            }
            elementForward.handler = directionHandler
            elementBackward.handler = directionHandler
            elementRight.handler = directionHandler
            elementLeft.handler = directionHandler
            elementSpeed.handler = directionHandler
            
            // What to do when the device disconnects
            serverDevice.events.deviceDisconnected.handler = { _ in
                logDebug("Handler got device disconnected")
                self.service.setTitle("No service", for: .normal)
                self.browse.setTitle("Browse for \(self.serviceName)", for: .normal)
                self.service.isEnabled = false
                self.browse.isEnabled = true
            }
            
            // What to do when once we are connected to the server.  You can test the server device
            // "isConnected" property at any time to know if the client is connected to the server and
            // ready to send elements.
            serverDevice.events.connected.handler = { (device) in
                logDebug("Device successfully connected to server")
                self.service.setTitle("Disconnect from \(serverDevice.remoteServerAddress)", for: .normal)
                self.browse.setTitle("Connected to \(self.serviceName)", for: .normal)
                self.browse.isEnabled = false
                
            }
            
        }
    }
    
}


