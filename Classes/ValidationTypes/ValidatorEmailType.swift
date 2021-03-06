//
//  ValidatorEmailType.swift
//  PapersPlease
//
//  Created by Brett Walker on 7/4/14.
//  Copyright (c) 2014 Poet & Mountain, LLC. All rights reserved.
//

import Foundation

class ValidatorEmailType:ValidatorType {

    override func isTextValid(text: String) -> Bool {

        var error:NSError? = nil

        self.valid = false

        // while Unicode characters are permissible in user and domain sections of an e-mail address, they must be encoded and use IDNA.
        // (see: http://en.wikipedia.org/wiki/Unicode_and_e-mail#Unicode_support_in_message_headings )
        // this validation does not parse or check thusly-encoded strings for well-formedness (yet?)
        if let regex = NSRegularExpression(pattern: "^[+\\w\\.\\-'!#$%&*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+(\\.[a-zA-Z]{2,})+$", options: .CaseInsensitive, error: &error) {

            let num_matches:Int = regex.numberOfMatchesInString(text, options: .ReportProgress, range: NSMakeRange(0, count(text.utf16)))

            self.valid = (num_matches == 1)

        }

        // update states
        self.validationStates.removeAll()
        (self.valid) ? (self.validationStates.append(self.status.valid))
                     : (self.validationStates.append(self.status.invalid))

        return self.valid
    }

    class override func type() -> String {
        return "ValidationTypeEmail"
    }

}
