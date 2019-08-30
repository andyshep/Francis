//
//  ViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 3/17/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

class ServicesViewController: NSViewController {
    
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var statusLabel: NSButton!
    
    private var cancelables: [AnyCancellable] = []
    
    lazy var servicesController: NSArrayController = {
        let controller = NSArrayController()
        controller.bind(.contentArray, to: self, withKeyPath: "services")
        controller.preservesSelection = true
        controller.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        return controller
    }()
    
    @objc private var services: [NetService] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.bind(.content, to: servicesController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: servicesController, withKeyPath: "selectionIndexes")
        
        representedObjectPublisher
            .sink { [weak self] representedObject in
                if representedObject == nil {
                    self?.willChangeValue(for: \.services)
                    self?.services = []
                    self?.didChangeValue(for: \.services)
                } else if let viewModel = representedObject as? ServicesProvider {
                    self?.bind(to: viewModel)
                    viewModel.refreshEvent.send(())
                }
            }
            .store(in: &cancelables)
    }
}

private extension ServicesViewController {
    private func bind(to viewModel: ServicesProvider) {
        viewModel.services
            .removeDuplicates()
            .sink { [weak self] (services) in
                self?.willChangeValue(for: \.services)
                self?.services = services
                self?.didChangeValue(for: \.services)
            }
            .store(in: &cancelables)
    }
    
    private func handleError(_ error: Error) {
        print("\(#function): unhandled error: \(error)")
    }
}
