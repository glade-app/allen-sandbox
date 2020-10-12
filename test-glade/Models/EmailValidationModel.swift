//
//  EmailValidation.swift
//  test-glade
//
//  Created by Allen Gu on 10/10/20.
//

import Foundation

struct EmailValidationModel {
    var validEmail: Bool = false
    var schoolEmailEndings = ["UC Berkeley": "@berkeley.edu"]
    var caseFailed: String = ""
    
    // Validates an email and alters the validEmail boolean variable based on a regex filter. The regex filter checks if the email ends in the school's domain address and contains valid letters in the local part
    mutating func validateEmail(school: String, email: String) {
        if email.count == 0 {
            caseFailed = "Email is required"
        }
        else {
            let range = NSRange(location: 0, length: email.utf16.count)
            let regex = try! NSRegularExpression(pattern: "([A-Za-z0-9.(),:;<>@!#$%&'*+-/=?^_`{|}~])+" + schoolEmailEndings[school]!)
            validEmail = regex.firstMatch(in: email, options: [], range: range) != nil
            if !validEmail {
                caseFailed = "Invalid email"
            }
        }
    }
    func isValidEmail() -> Bool {
        return validEmail
    }
    func emailValidationFeedback() -> String {
        if !validEmail {
            return caseFailed
        }
        return "Valid Email"
    }
}
