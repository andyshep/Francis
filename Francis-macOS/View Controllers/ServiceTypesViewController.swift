//
//  ServiceTypesViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 10/28/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Cocoa
import Combine

class ServiceTypesViewController: NSViewController {
    
    @objc private var serviceTypes: [NetService] = []
    
    @IBOutlet private weak var tableView: NSTableView!
    
    private var viewModel: ServiceTypesProvider!
    
    private var cancelables: [AnyCancellable] = []
    
    lazy var serviceTypesController: NSArrayController = {
        let controller = NSArrayController()
        controller.bind(.contentArray, to: self, withKeyPath: "serviceTypes")
        controller.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        controller.preservesSelection = true
        
        return controller
    }()
    
    deinit {
        cancelables.forEach { $0.cancel() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.bind(.content, to: serviceTypesController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: serviceTypesController, withKeyPath: "selectionIndexes")
        
        representedObjectPublisher
            .compactMap { $0 as? ServiceTypesProvider }
            .flatMapLatest { viewModel -> AnyPublisher<[NetService], Never> in
                return viewModel.serviceTypes
            }
            .sink { [weak self] serviceTypes in
                self?.willChangeValue(for: \.serviceTypes)
                self?.serviceTypes = serviceTypes
                self?.didChangeValue(for: \.serviceTypes)
            }
            .store(in: &cancelables)
    }
}
