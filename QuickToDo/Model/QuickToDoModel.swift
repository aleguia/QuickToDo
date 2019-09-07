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
    private let itemHints: PublishSubject<String> = PublishSubject()
    private let disposeBag = DisposeBag()
    
    var items: Observable<Item> {
        return itemsPrivate
    }
    
    var cloudStatus: Observable<CloudStatus> {
        return cloudStatusPrivate
    }
    
    private var coreData: QuickToDoStorageProtocol
    
    init(_ withCoreData: QuickToDoStorageProtocol) {
        coreData = withCoreData
    }
    
    func getItems() -> (Bool, Error?) {
        self.coreData.outputs.items
            .subscribe({ (item) in
            if let itemElement = item.element {
                self.itemsPrivate.onNext(itemElement)
            }
        }).disposed(by: disposeBag)
        return self.coreData.inputs.getItems()
    }
    
    func add(_ item: Item) -> (Bool, Error?) {
        let newItem = self.coreData.inputs.insert(item)
        self.itemsPrivate.onNext(newItem)
        return (true, nil)
    }
    
    func update(_ item: Item, withItem newItem: Item) -> (Bool, Error?) {
        let oldItem = self.coreData.inputs.getItemWith(item.name)
        let superNewItem = self.coreData.inputs.update(oldItem, withItem: newItem)
        self.itemsPrivate.onNext(superNewItem)
        return(true, nil)
    }
    
    func getHints(for itemName: String) -> Observable<String> {
        
        return Observable.create({ (observer) -> Disposable in
            self.coreData.inputs.getHints(for: itemName) { (firstItem, secondItem) in
                observer.onNext(firstItem.name)
                observer.onNext(secondItem.name)
                observer.onCompleted()
            }
            return Disposables.create()
        })
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
        .observeOn(MainScheduler.instance)

            //itemHints.onCompleted()
    }
    
    var inputs: QuickToDoInputs { return self }
    
    var outputs: QuickToDoOutputs { return self }
    
    
}
