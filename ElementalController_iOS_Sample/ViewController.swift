//
//  ViewController.swift
//  ElementalController_iOS_Sample
//
//  Created by Rob Reuss on 1/12/19.
//  Copyright © 2019 Rob Reuss. All rights reserved.
//

import UIKit
import ElementalController

class ViewController: UIViewController {

    let eid_forward: Int8 = 1
    let eid_backward: Int8 = 2
    let eid_right: Int8 = 3
    let eid_left: Int8 = 4
    let eid_speed: Int8 = 5
    
    var serviceName = "robot"
    var elementalController = ElementalController()
    var serverDevice: ServerDevice?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ElementalController.protocolFamily = .inet6

        elementalController.setupForBrowsingAs(deviceNamed: "My iPhone")
        
        elementalController.browser.events.foundServer.handler { serverDevice in
            
            self.browse.setTitle("Browse for \(self.serviceName)", for: .normal)
            self.service.setTitle("Connect to \(serverDevice.remoteServerAddress)", for: .normal)
            self.service.isEnabled = true
            self.serverDevice = serverDevice
            
            let element_forward = serverDevice.attachElement(Element(identifier: self.eid_forward, displayName: "Forward", proto: .tcp, dataType: .Double))
            let element_backward = serverDevice.attachElement(Element(identifier: self.eid_backward, displayName: "Backward", proto: .tcp, dataType: .Double))
            let element_right = serverDevice.attachElement(Element(identifier: self.eid_right, displayName: "Right", proto: .tcp, dataType: .Double))
            let element_left = serverDevice.attachElement(Element(identifier: self.eid_left, displayName: "Left", proto: .tcp, dataType: .Double))
            let element_speed = serverDevice.attachElement(Element(identifier: self.eid_speed, displayName: "Speed", proto: .udp, dataType: .Float))
            
            // These are for return messages from the server (our Linux-based robot)
            element_forward.handler = { element, device in
                logDebug("Recieved response to forward: \(element.value ?? "Unknown Value")")
            }
            element_backward.handler = { element, device in
                logDebug("Recieved response to backward: \(element.value ?? "Unknown Value")")
            }
            element_right.handler = { element, device in
                logDebug("Recieved response to right: \(element.value ?? "Unknown Value")")
            }
            element_left.handler = { element, device in
                logDebug("Recieved response to left:\(element.value ?? "Unknown Value")")
            }
            element_speed.handler = { element, device in
                logDebug("Recieved response to speed:\(element.value ?? "Unknown Value")")
            }
            
            serverDevice.events.deviceDisconnected.handler = { _ in
                logDebug("Handler got device disconnected")
                self.service.setTitle("No service", for: .normal)
                self.browse.setTitle("Browse for \(self.serviceName)", for: .normal)
                self.service.isEnabled = false
                self.browse.isEnabled = true
            }
            
            serverDevice.events.connected.handler = { (device) in
                logDebug("Device successfully connected to server")
                self.service.setTitle("Disconnect from \(serverDevice.remoteServerAddress)", for: .normal)
                self.browse.setTitle("Connected to \(self.serviceName)", for: .normal)
                self.browse.isEnabled = false
                
            }
            
        }
    }

}

