//
//  WindowController.swift
//  Francis
//
//  Created by Andrew Shepard on 3/24/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class WindowController: NSWindowController {
    
    @IBOutlet private weak var toolbar: NSToolbar!
    @IBOutlet private weak var servicesListButton: NSPopUpButton!
    @IBOutlet private weak var reloadButton: NSButton!
    
    lazy private var servicesViewController: ServicesViewController = {
        guard let splitViewController = contentViewController as? NSSplitViewController else { fatalError() }
        
        guard let viewController = splitViewController.children.first as? ServicesViewController else { fatalError() }
        return viewController
    }()
    
    lazy private var serviceInfoViewController: ServiceInfoViewController = {
        guard let splitViewController = contentViewController as? NSSplitViewController else { fatalError() }
        
        guard let viewController = splitViewController.children.last as? ServiceInfoViewController else { fatalError() }
        return viewController
    }()
    
    @objc private var serviceTypes: [NetService] = []
    
    lazy private var serviceTypesArrayController: NSArrayController = {
        let arrayController = NSArrayController()
        arrayController.bind(.contentArray, to: self, withKeyPath: "serviceTypes")

        return arrayController
    }()
    
    lazy private var servicesArrayController: NSArrayController = {
        let arrayController = self.servicesViewController.servicesController
        return arrayController
    }()
    
    private var serviceTypesViewModel: ServiceTypesViewModel! {
        didSet {
            guard let viewModel = serviceTypesViewModel else { return }
            
            if oldValue != nil {
                bag = DisposeBag()
                
                bind(to: viewModel)
                bindToArrayControllers()
            }
        }
    }
    
    private var bag = DisposeBag()

    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.titleVisibility = .hidden
        
        createViewModel()
        
        servicesListButton.bind(.content, to: serviceTypesArrayController, withKeyPath: "arrangedObjects")
        servicesListButton.bind(.contentValues, to: serviceTypesArrayController, withKeyPath: "arrangedObjects.name")
        servicesListButton.bind(.selectedIndex, to: serviceTypesArrayController, withKeyPath: "selectionIndex")
        
        bindToArrayControllers()
    }
}

extension WindowController {
    
    private func bindToArrayControllers() {
        serviceTypesArrayController
            .rx
            .observeWeakly(Int.self, "selectionIndex", options: [.new])
            .map { [weak self] (index) -> ServicesViewModel? in
                guard let this = self else { return nil }
                guard let service = this.serviceTypesArrayController.selectedObjects.first as? NetService else { return nil }

                let viewModel = ServicesViewModel(service: service)
                return viewModel
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] (viewModel) in
                guard let this = self else { return }

                this.servicesViewController.representedObject = viewModel
                this.serviceInfoViewController.representedObject = nil
            })
            .disposed(by: bag)
        
        servicesArrayController
            .rx
            .observeWeakly(Int.self, "selectionIndex", options: [.new])
            .map { [weak self] (index) -> ServiceViewModel? in
                guard let this = self else { return nil }
                
                guard let service = this.servicesArrayController.selectedObjects.first as? NetService else { return nil }
                
                let viewModel = ServiceViewModel(service: service)
                return viewModel
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] (viewModel) in
                guard let this = self else { return }
                
                this.serviceInfoViewController.representedObject = viewModel
            })
            .disposed(by: bag)
    }
    
    private func bind(to viewModel: ServiceTypesViewModel) {
        serviceTypesViewModel
            .serviceTypes
            .asDriver(onErrorJustReturn: [])
            .map { (services) -> [NetService] in
                return services.sorted { $0.name < $1.name }
            }
            .drive(onNext: { [weak self] (serviceTypes) in
                self?.willChangeValue(for: \.serviceTypes)
                self?.serviceTypes = serviceTypes
                self?.didChangeValue(for: \.serviceTypes)
            })
            .disposed(by: bag)
        
        reloadButton
            .rx
            .controlEvent
            .debounce(0.5, scheduler: MainScheduler.instance)
            .bind(to: serviceTypesViewModel.refreshEvent)
            .disposed(by: bag)
    }
    
    private func createViewModel() {
        self.serviceTypesViewModel = ServiceTypesViewModel()
        bind(to: serviceTypesViewModel)
        
        servicesViewController.representedObject = serviceTypesViewModel
    }
}
