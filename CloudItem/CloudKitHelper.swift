//
//  CloudKitHelper.swift
//  CloudItem
//
//  Created by Reza Harris on 21/10/21.
//

import Foundation
import CloudKit

struct CloudKitHelper {
    
    struct RecordType {
        static let Items = "Items"
    }
    
    enum CloudKitHelperError: Error {
        case recordFailure
        case recordIDFailure
        case castFailure
        case cursorFailure
    }
    
    static func save(item: ListElement, completion: @escaping (Result<ListElement, Error>) -> ()) {
        let itemRecord = CKRecord(recordType: RecordType.Items)
        itemRecord["text"] = item.text as CKRecordValue
        
        CKContainer.default().publicCloudDatabase.save(itemRecord) { (record, err) in
            DispatchQueue.main.async {
                if let err = err {
                    completion(.failure(err))
                    return
                }
                guard let record = record else {
                    completion(.failure(CloudKitHelperError.recordFailure))
                    return
                }
                let id = record.recordID
                guard let text = record["text"] as? String else {
                    completion(.failure(CloudKitHelperError.castFailure))
                    return
                }
                
                let element = ListElement(recordID: id, text: text)
                completion(.success(element))
            }
        }
    }
    
    static func fetch(completion: @escaping (Result<ListElement, Error>) -> ()) {
        let pred = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: RecordType.Items, predicate: pred)
        query.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["text"]
        operation.resultsLimit = 50
        
        operation.recordFetchedBlock = { record in
            DispatchQueue.main.async {
                let id = record.recordID
                guard let text = record["text"] as? String else {
                    completion(.failure(CloudKitHelperError.castFailure))
                    return
                }
                let element = ListElement(recordID: id, text: text)
                completion(.success(element))
            }
        }
        
        operation.queryCompletionBlock = { (_, err) in
            DispatchQueue.main.async {
                if let err = err {
                    completion(.failure(err))
                    return
                }
            }
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    static func delete(recordID: CKRecord.ID, completion: @escaping (Result<CKRecord.ID, Error>) -> ()) {
        CKContainer.default().publicCloudDatabase.delete(withRecordID: recordID) { recordID, err in
            DispatchQueue.main.async {
                if let err = err {
                    completion(.failure(err))
                    return
                }
                
                guard let recordId = recordID else {
                    completion(.failure(CloudKitHelperError.castFailure))
                    return
                }
                completion(.success(recordId))
            }
        }
    }
    
    static func modify(item: ListElement, completion: @escaping (Result<ListElement, Error>) -> ()) {
        guard let recordID = item.recordID else { return }
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, err in
            DispatchQueue.main.async {
                if let err = err {
                    completion(.failure(err))
                    return
                }
                guard let record = record else { return }
                record["text"] = item.text as CKRecordValue
                
                CKContainer.default().publicCloudDatabase.save(record) { (record, err) in
                    DispatchQueue.main.async {
                        if let err = err {
                            completion(.failure(err))
                            return
                        }
                        guard let record = record else { return }
                        let id = record.recordID
                        guard let text = record["text"] as? String else { return }
                        let element = ListElement(recordID: id, text: text)
                        completion(.success(element))
                    }
                }
            }
        }
    }
}
