//
//  ServiceInfoViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 4/7/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Cocoa
import RxSwift

class ServiceInfoViewController: NSViewController {
    
    @IBOutlet private weak var tableView: NSTableView!
    
    @objc private var entries: [String: String] = [:]
    
    private let bag = DisposeBag()
    
    lazy private var entriesController: NSDictionaryController = {
        let controller = NSDictionaryController()
        controller.bind(NSBindingName.contentDictionary, to: self, withKeyPath: "entries")
        
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.bind(.content, to: entriesController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: entriesController, withKeyPath: "selectionIndexes")
        
        self.rx.observe(Any.self, "representedObject")
            .do(onNext: { [weak self] (representedObject) in
                guard let this = self else { return }
                guard representedObject == nil else { return }

                this.willChangeValue(for: \.entries)
                this.entries = [:]
                this.didChangeValue(for: \.entries)
            })
            .map { $0 as? ServiceViewModel }
            .catchErrorJustReturn(nil)
            .filterNils()
            .flatMapLatest { (viewModel) -> Observable<[String: String]> in
                return viewModel.entries
            }
            .do(onNext: { [weak self] entries in
                guard let this = self else { return }
                
                this.willChangeValue(for: \.entries)
                this.entries = entries
                this.didChangeValue(for: \.entries)
            })
            .subscribe()
            .disposed(by: bag)
    }
    
    @IBAction func copyObj(_ sender: Any) {
        guard let selected = entriesController.selectedObjects.first
            as? NSDictionaryControllerKeyValuePair else { return }
        guard let value = selected.value as? String else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(value, forType: .string)
    }
}
