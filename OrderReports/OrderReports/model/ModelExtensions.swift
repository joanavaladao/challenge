//
//  ModelExtensions.swift
//  OrderReport
//
//  Created by Joana Valadao on 19/08/17.
//  Copyright © 2017 Joana Bittencourt. All rights reserved.
//

import Foundation

extension Customer {
    
    func completeName() -> String {
        
        if let firstName = firstName,
            let lastName = lastName {
            return firstName + " " + lastName
        }
        return " "
    }
    
}
