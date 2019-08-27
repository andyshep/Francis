//
//  ServiceViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 4/7/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

class ServiceViewController: NSViewController {
    
    @IBOutlet private weak var tableView: NSTableView!
    
    @objc private var entries: [String: String] = [:]
    
    private var cancelables: [AnyCancellable] = []
    
    lazy private var entriesController: NSDictionaryController = {
        let controller = NSDictionaryController()
        controller.bind(NSBindingName.contentDictionary, to: self, withKeyPath: "entries")
        controller.preservesSelection = true
        
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.bind(.content, to: entriesController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: entriesController, withKeyPath: "selectionIndexes")
        
        representedObjectPublisher
            .sink { [weak self] (representedObject) in
                if representedObject == nil {
                    self?.willChangeValue(for: \.entries)
                    self?.entries = [:]
                    self?.didChangeValue(for: \.entries)
                } else if let viewModel = representedObject as? ServiceViewModel {
                    self?.bind(to: viewModel)
                    viewModel.refreshEvent.send(())
                }
            }
            .store(in: &cancelables)
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
            .removeDuplicates()
            .sink { [weak self] (entries) in
                self?.willChangeValue(for: \.entries)
                self?.entries = entries
                self?.didChangeValue(for: \.entries)
            }
            .store(in: &cancelables)
    }
}
