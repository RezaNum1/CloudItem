//
//  ListElements.swift
//  CloudItem
//
//  Created by Reza Harris on 21/10/21.
//

import Foundation
import CloudKit

class ListElements: ObservableObject {
    @Published var items: [ListElement] = []
}

struct ListElement: Identifiable {
    var id = UUID()
    var recordID: CKRecord.ID?
    var text: String = ""
}
