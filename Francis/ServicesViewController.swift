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
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var statusLabel: NSButton!
    
    private let bag = DisposeBag()
    private var viewModel: ServicesViewModel!
    
    lazy var servicesController: NSArrayController = {
        let controller = NSArrayController()
        controller.bind(.contentArray, to: self, withKeyPath: "services")
        controller.preservesSelection = true
        
        return controller
    }()
    
    @objc private var services: [DNSSDService] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.bind(.content, to: servicesController, withKeyPath: "arrangedObjects")
        tableView.bind(.selectionIndexes, to: servicesController, withKeyPath: "selectionIndexes")
        
        self.rx.observe(Any.self, "representedObject")
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] (representedObject) in
                guard let this = self else { return }
                
                guard let viewModel = representedObject as? ServicesViewModel else {
                    this.willChangeValue(for: \.services)
                    this.services = []
                    this.didChangeValue(for: \.services)
                    return
                }
                
                this.bindTo(viewModel: viewModel)
                viewModel.refreshEvent.onNext(())
            })
            .disposed(by: bag)
    }
}

private extension ServicesViewController {
    private func bindTo(viewModel: ServicesViewModel) {
        viewModel.services
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] (services) in
                self?.willChangeValue(for: \.services)
                self?.services = services
                self?.didChangeValue(for: \.services)
                
                self?.updateServiceLabel(with: services.count)
            })
            .disposed(by: bag)
    }
    
    private func handleError(_ error: Error) {
        print("\(#function): unhandled error: \(error)")
    }
    
    private func updateServiceLabel(with count: Int) {
        let descriptor = (count == 1) ? "service found" : "services found"
        statusLabel.title = "\(count) \(descriptor)"
    }
}
