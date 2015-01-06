//
//  ValidationUnit.swift
//  PapersPlease
//
//  Created by Brett Walker on 7/3/14.
//  Copyright (c) 2014 Poet & Mountain, LLC. All rights reserved.
//

import Foundation
import UIKit

let ValidationUnitUpdateNotification:String = "ValidationUnitUpdateNotification"

class ValidationUnit {
    
    var registeredValidationTypes:[ValidatorType] = []
    var errors = [String:[String]]()
    var identifier = ""
    var valid:Bool = false
    var enabled:Bool = true
    let validationQueue:dispatch_queue_t
    
    var lastTextValue:String = ""
    
    init(validatorTypes:[ValidatorType]=[], identifier:String, initialText:String="") {
        
        self.validationQueue = dispatch_queue_create("com.poetmountain.ValidationUnitQueue", DISPATCH_QUEUE_SERIAL)
        self.registeredValidationTypes = validatorTypes
        self.identifier = identifier
        self.lastTextValue = initialText

        for type:ValidatorType in self.registeredValidationTypes {
            if (type.sendsUpdates) {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("validationUnitStatusUpdatedNotification:"), name: ValidatorUpdateNotification, object: type)
                type.isTextValid(self.lastTextValue)
            }
        }

    }


    func dealloc() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    
    // MARK: Validation methods
    
    func registerValidatorType (validatorType:ValidatorType) {
        self.registeredValidationTypes.append(validatorType)
    }
    
    func clearValidatorTypes () {
        self.registeredValidationTypes.removeAll()
    }
    
    
    func validationComplete () {
        // first remove any old errors
        self.errors.removeAll()
        
        var total_errors = [String:[String:[String]]]() as NSDictionary
        
        if (!self.valid) {
            for validator_type:ValidatorType in self.registeredValidationTypes {
                if (!validator_type.valid) {
                    self.errors[validator_type.dynamicType.type()] = validator_type.validationStates
                }
            }
            total_errors = ["errors" : self.errors]
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(ValidationUnitUpdateNotification, object: self, userInfo: total_errors)
    }
    
    
    func validateText(text:String) {
        
        if (self.enabled) {
            dispatch_async(self.validationQueue, {
                [weak self] in
                
                if let strong_self = self {
                    
                    var num_valid = 0
                    
                    for type:ValidatorType in strong_self.registeredValidationTypes {
                        let is_valid:Bool = type.isTextValid(text)
                        num_valid += Int(is_valid)
                    }
                    
                    let type_count:Int = strong_self.registeredValidationTypes.count
                    (num_valid == type_count) ? (strong_self.valid = true) : (strong_self.valid = false)
                    
                    strong_self.lastTextValue = text
                    
                    // send notification (on main queue, there be UI work)
                    dispatch_async(dispatch_get_main_queue(), {
                        strong_self.validationComplete()
                    })
                }
                
            })
        }
        
    }
    
    
    
    // MARK: Utility methods
    
    func validatorTypeForIdentifier(identifier:String) -> ValidatorType? {
        var validator_type: ValidatorType?
        
        for type:ValidatorType in self.registeredValidationTypes {
            if (type.identifier == identifier) {
                validator_type = type
                break
            }
        }

        return validator_type
    }
    
    
    
    // MARK: Notifications
    
    @objc func textDidChangeNotification(notification:NSNotification) {
        
        if (notification.name == UITextFieldTextDidChangeNotification) {
            let text_field:UITextField = notification.object as UITextField
            self.validateText(text_field.text)
        } else if (notification.name == UITextViewTextDidChangeNotification) {
            let text_view:UITextView = notification.object as UITextView
            self.validateText(text_view.text)
        }
    }
    
    
    @objc func validationUnitStatusUpdatedNotification(notification:NSNotification) {
        
        if (self.enabled) {
        
            if let user_info = notification.userInfo {
                if let status_num:NSNumber = user_info["status"] as? NSNumber {
                    let is_valid: Bool = status_num.boolValue ?? false
                    
                    if (is_valid) {
                        self.validateText(self.lastTextValue)
                    } else {
                        self.valid = false
                        self.validationComplete()
                    }
                }
            }
            
        }

    }
    
}