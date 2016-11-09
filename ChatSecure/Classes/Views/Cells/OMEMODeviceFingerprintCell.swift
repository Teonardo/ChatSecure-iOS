//
//  OMEMODeviceFingerprintCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/14/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit
import XLForm
import OTRAssets
import XMPPFramework
import FormatterKit
import OTRKit

private extension String {
    //http://stackoverflow.com/a/34454633/805882
    func splitEvery(n: Int) -> [String] {
        var result: [String] = []
        let chars = Array(characters)
        for index in 0.stride(to: chars.count, by: n) {
            result.append(String(chars[index..<min(index+n, chars.count)]))
        }
        return result
    }
}

public extension NSData {
    /// hex, split every 8 bytes by a space
    public func humanReadableFingerprint() -> String {
        return self.xmpp_hexStringValue().splitEvery(8).joinWithSeparator(" ")
    }
}

public extension XLFormBaseCell {
    
    public class func defaultRowDescriptorType() -> String {
        let type = NSStringFromClass(self)
        return type
    }
    
    public class func registerCellClass(forType: String) {
        let bundle = OTRAssets.resourcesBundle()
        let path = bundle.bundlePath
        let bundleName = (path as NSString).lastPathComponent
        let className = bundleName + "/" + NSStringFromClass(self)
        XLFormViewController.cellClassesForRowDescriptorTypes().setObject(className, forKey: forType)
    }
}

@objc(OMEMODeviceFingerprintCell)
public class OMEMODeviceFingerprintCell: XLFormBaseCell {
    
    @IBOutlet weak var fingerprintLabel: UILabel!
    @IBOutlet weak var trustSwitch: UISwitch!
    @IBOutlet weak var lastSeenLabel: UILabel!
    
    private static let intervalFormatter = TTTTimeIntervalFormatter()
    
    public override class func formDescriptorCellHeightForRowDescriptor(rowDescriptor: XLFormRowDescriptor!) -> CGFloat {
        return 90
    }
    
    public override func update() {
        super.update()
        if let device = rowDescriptor.value as? OTROMEMODevice {
            updateCellFromDevice(device)
        }
        if let fingerprint = rowDescriptor.value as? OTRFingerprint {
            updateCellFromFingerprint(fingerprint)
        }
    }
    

    
    @IBAction func switchValueChanged(sender: UISwitch) {
        if let device = rowDescriptor.value as? OTROMEMODevice {
            switchValueWithDevice(device)
        }
        if let fingerprint = rowDescriptor.value as? OTRFingerprint {
            switchValueWithFingerprint(fingerprint)
        }
    }
    
    private func updateCellFromDevice(device: OTROMEMODevice) {
        let trusted = device.isTrusted()
        trustSwitch.on = trusted
        
        // we've already filtered out devices w/o public keys
        // so publicIdentityKeyData should never be nil
        let fingerprint = device.humanReadableFingerprint
        
        fingerprintLabel.text = fingerprint
        let interval = -NSDate().timeIntervalSinceDate(device.lastSeenDate)
        let since = self.dynamicType.intervalFormatter.stringForTimeInterval(interval)
        let lastSeen = "OMEMO: " + since
        lastSeenLabel.text = lastSeen
        let enabled = !rowDescriptor.isDisabled()
        trustSwitch.enabled = enabled
        fingerprintLabel.enabled = enabled
        lastSeenLabel.enabled = enabled
    }
    
    private func switchValueWithDevice(device: OTROMEMODevice) {
        if (trustSwitch.on) {
            device.trustLevel = .TrustedUser
        } else {
            device.trustLevel = .Untrusted
        }
        rowDescriptor.value = device
    }
    
    private func updateCellFromFingerprint(fingerprint: OTRFingerprint) {
        fingerprintLabel.text = fingerprint.fingerprint.lowercaseString
        lastSeenLabel.text = "OTR"
        trustSwitch.enabled = true
        if (fingerprint.trustLevel == .TrustedUser ||
            fingerprint.trustLevel == .TrustedTofu) {
            trustSwitch.on = true
        } else {
            trustSwitch.on = false
        }
    }
    
    private func switchValueWithFingerprint(fingerprint: OTRFingerprint) {
        if (trustSwitch.on) {
            fingerprint.trustLevel = .TrustedUser
        } else {
            fingerprint.trustLevel = .Untrusted
        }
        rowDescriptor.value = fingerprint
    }

    
}
