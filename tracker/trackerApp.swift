//
//  trackerApp.swift
//  tracker
//
//  Created by Jeremy Fong on 5/11/22.
//

import SwiftUI

@main
struct trackerApp: App {
//    @StateObject private var dataController = DataController()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
