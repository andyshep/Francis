//
//  ServiceTypesViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 10/28/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class ServiceTypesViewController: NSViewController {
    
    @objc private var serviceTypes: [NetService] = []
    
    @IBOutlet private weak var tableView: NSTableView!
    
    private var viewModel: ServiceTypesViewModel!
    private let bag = DisposeBag()
    
    lazy var serviceTypesController: NSArrayController = {
        let controller = NSArrayController()
        controller.bind(.contentArray, to: self, withKeyPath: "serviceTypes")
        controller.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        controller.preservesSelection = true
        
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.bind(.content, to: serviceTypesController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: serviceTypesController, withKeyPath: "selectionIndexes")
        
        self.rx.observe(Any.self, "representedObject")
            .do(onNext: { [weak self] (representedObject) in
                guard representedObject == nil else { return }
                
                self?.willChangeValue(for: \.serviceTypes)
                self?.serviceTypes = []
                self?.didChangeValue(for: \.serviceTypes)
            })
            .map { $0 as? ServiceTypesViewModel }
            .catchErrorJustReturn(nil)
            .filterNils()
            .flatMapLatest { viewModel -> Observable<[NetService]> in
                return viewModel.serviceTypes
            }
            .distinctUntilChanged()
            .do(onNext: { [weak self] serviceTypes in
                self?.willChangeValue(for: \.serviceTypes)
                self?.serviceTypes = serviceTypes
                self?.didChangeValue(for: \.serviceTypes)
            })
            .subscribe()
            .disposed(by: bag)
    }
}
