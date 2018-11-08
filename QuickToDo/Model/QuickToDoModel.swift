//
//  QuickToDoModel.swift
//  QuickToDo
//
//  Created by Bratislav Ljubisic on 02.10.18.
//  Copyright © 2018 Bratislav Ljubisic. All rights reserved.
//

import Foundation
import RxSwift

class QuickToDoModel: QuickToDoOutputs, QuickToDoInputs, QuickToDoProtocol {
    private let itemsPrivate: PublishSubject<Item> = PublishSubject()
    private let cloudStatusPrivate: PublishSubject<CloudStatus> = PublishSubject()
    
    var items: Observable<Item>? {
        return itemsPrivate
    }
    
    var cloudStatus: Observable<CloudStatus> {
        return cloudStatusPrivate
    }
    
    var coreData: QuickToDoCoreDataProtocol
    
    init(_ withCoreData: QuickToDoCoreDataProtocol) {
        coreData = withCoreData
    }
    
    func add(_ item: Item) -> (Bool, Error?) {
        let newItem = self.coreData.inputs.insert(item)
        self.itemsPrivate.onNext(newItem)
        return (true, nil)
    }
    
    func update(_ item: Item) -> (Bool, Error?) {
        let oldItem = self.coreData.inputs.getItemWith(item.name)
        let newItem = self.coreData.inputs.update(oldItem, withItem: item)
        self.itemsPrivate.onNext(newItem)
        return(true, nil)
    }
    
    var inputs: QuickToDoInputs { return self }
    
    var outputs: QuickToDoOutputs { return self }
    
    
}
