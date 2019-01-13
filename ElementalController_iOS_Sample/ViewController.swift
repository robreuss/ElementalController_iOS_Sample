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
        element.value = 1.0
        guard device.send(element: element) else {
            logDebug("Direction \(element.displayName) send failed")
            return
        }
    }
    
    @IBOutlet weak var speed: UILabel!
    @IBAction func speed(_ sender: Any) {
        guard let device = serverDevice else { return }
        guard let element = device.getElementWith(identifier: eid_speed) else { return }
        speed.text = "Speed is \((sender as! UISlider).value)"
        element.value = (sender as! UISlider).value
        guard device.send(element: element) else {
            logDebug("Speed send failed")
            return
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
                elementMotionX.value = data?.acceleration.x
                guard device.send(element: elementMotionX) else {
                    logDebug("\(elementMotionX.displayName) send failed")
                    return
                }
                elementMotionY.value = data?.acceleration.y
                guard device.send(element: elementMotionY) else {
                    logDebug("\(elementMotionY.displayName)  send failed")
                    return
                }
                elementMotionZ.value = data?.acceleration.z
                guard device.send(element: elementMotionZ) else {
                    logDebug("\(elementMotionZ.displayName)  send failed")
                    return
                }
            }
        }
        
    }
    
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
            let elementMotionX = serverDevice.attachElement(Element(identifier: self.eid_motionX, displayName: "Motion X", proto: .udp, dataType: .Double))
            let elementMotionY = serverDevice.attachElement(Element(identifier: self.eid_motionY, displayName: "Motion Y", proto: .udp, dataType: .Double))
            let elementMotionZ = serverDevice.attachElement(Element(identifier: self.eid_motionZ, displayName: "Motion Z", proto: .udp, dataType: .Double))
            
            // These are generally not necessary - they are handlers when the server sends a
            // reply to our elements in a request/response model
            elementForward.handler = { element, device in
                logDebug("Recieved response to forward: \(element.value ?? "Unknown Value")")
            }
            elementBackward.handler = { element, device in
                logDebug("Recieved response to backward: \(element.value ?? "Unknown Value")")
            }
            elementRight.handler = { element, device in
                logDebug("Recieved response to right: \(element.value ?? "Unknown Value")")
            }
            elementLeft.handler = { element, device in
                logDebug("Recieved response to left:\(element.value ?? "Unknown Value")")
            }
            elementSpeed.handler = { element, device in
                logDebug("Recieved response to speed:\(element.value ?? "Unknown Value")")
            }
            
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

