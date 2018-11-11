//
//  ViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 3/17/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class ServicesViewController: NSViewController {
    
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private weak var statusLabel: NSButton!
    
    private let bag = DisposeBag()
    
    lazy var servicesController: NSArrayController = {
        let controller = NSArrayController()
        controller.bind(.contentArray, to: self, withKeyPath: "services")
        controller.preservesSelection = true
        
        return controller
    }()
    
    @objc private var services: [NetService] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.bind(.content, to: servicesController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: servicesController, withKeyPath: "selectionIndexes")
        
        self.rx.observe(Any.self, "representedObject")
            .do(onNext: { [weak self] (representedObject) in
                guard representedObject == nil else { return }
                
                // if representedObject is nil, clear our the services array
                self?.willChangeValue(for: \.services)
                self?.services = []
                self?.didChangeValue(for: \.services)
            })
            .map { $0 as? ServicesViewModel }
            .catchErrorJustReturn(nil)
            .filterNils()
            .do(onNext: { [weak self] viewModel in
                guard let this = self else { return }
                
                // if viewModel is _not_ nil, bind to it and send a refresh
                this.bind(to: viewModel)
                viewModel.refreshEvent.onNext(())
            })
            .subscribe()
            .disposed(by: bag)
    }
}

private extension ServicesViewController {
    private func bind(to viewModel: ServicesViewModel) {
        viewModel.services
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] (services) in
                self?.willChangeValue(for: \.services)
                self?.services = services
                self?.didChangeValue(for: \.services)
            })
            .disposed(by: bag)
    }
    
    private func handleError(_ error: Error) {
        print("\(#function): unhandled error: \(error)")
    }
}
