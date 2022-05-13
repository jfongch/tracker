//
//  DataController.swift
//  tracker
//
//  Created by Jeremy Fong on 5/11/22.
//

import CoreData
import Foundation
import SwiftUI

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "Item")
    
    init() {
        container.loadPersistentStores { descriptor, error in
            if let error = error {
                print("CoreData failed to load: \(error.localizedDescription)")
            }
            
        }
    }
}
