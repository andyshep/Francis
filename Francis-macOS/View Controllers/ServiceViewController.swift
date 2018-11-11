//
//  ServiceViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 4/7/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Cocoa
import RxSwift

class ServiceViewController: NSViewController {
    
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
                guard representedObject == nil else { return }

                self?.willChangeValue(for: \.entries)
                self?.entries = [:]
                self?.didChangeValue(for: \.entries)
            })
            .map { something in
                return something as? ServiceViewModel
            }
            .catchErrorJustReturn(nil)
            .filterNils()
            .do(onNext: { [weak self] viewModel in
                self?.bind(to: viewModel)
                viewModel.refreshEvent.onNext(())
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
    
    private func bind(to viewModel: ServiceViewModel) {
        viewModel.entries
            .asDriver(onErrorJustReturn: [:])
            .drive(onNext: { [weak self] (entries) in
                self?.willChangeValue(for: \.entries)
                self?.entries = entries
                self?.didChangeValue(for: \.entries)
            })
            .disposed(by: bag)
    }
}
