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
    
    private let viewModel = ServiceTypesViewModel()
    
    lazy private var serviceTypesViewController: ServiceTypesViewController = {
        guard let splitViewController = contentViewController as? NSSplitViewController else { fatalError() }
        guard let viewController = splitViewController.children[0] as? ServiceTypesViewController else { fatalError() }
        return viewController
    }()
    
    lazy private var servicesViewController: ServicesViewController = {
        guard let splitViewController = contentViewController as? NSSplitViewController else { fatalError() }
        
        guard let viewController = splitViewController.children[1] as? ServicesViewController else { fatalError() }
        return viewController
    }()
    
    lazy private var serviceViewController: ServiceViewController = {
        guard let splitViewController = contentViewController as? NSSplitViewController else { fatalError() }
        
        guard let viewController = splitViewController.children[2] as? ServiceViewController else { fatalError() }
        return viewController
    }()
    
    lazy private var serviceTypesController: NSArrayController = {
        let arrayController = self.serviceTypesViewController.serviceTypesController
        return arrayController
    }()
    
    lazy private var servicesController: NSArrayController = {
        let arrayController = self.servicesViewController.servicesController
        return arrayController
    }()
    
    private var bag = DisposeBag()

    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.titleVisibility = .hidden
        window?.setContentBorderThickness(24.0, for: .minY)
        window?.setAutorecalculatesContentBorderThickness(false, for: .minY)
        
        serviceTypesViewController.representedObject = viewModel
        
        bindToArrayControllers()
        bindToButtons()
    }
}

extension WindowController {
    
    private func bindToArrayControllers() {
        
        // observe service type selections
        // e.g. a service type containing one or more services
        serviceTypesController
            .rx
            .observeWeakly(Int.self, "selectionIndex", options: [.new])
            .map { [weak self] (index) -> ServicesViewModel? in
                guard let this = self else { return nil }
                guard let service = this.serviceTypesController.selectedObjects.first as? NetService else { return nil }

                let viewModel = ServicesViewModel(service: service)
                return viewModel
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] (viewModel) in
                guard let this = self else { return }

                this.servicesViewController.representedObject = viewModel
                this.serviceViewController.representedObject = nil
            })
            .disposed(by: bag)
        
        // observe individual service selections
        // e.g. a service running on a device
        servicesController
            .rx
            .observeWeakly(Int.self, "selectionIndex", options: [.new])
            .map { [weak self] (index) -> ServiceViewModel? in
                guard let this = self else { return nil }
                
                guard let service = this.servicesController.selectedObjects.first as? NetService else {
                    return nil
                }
                
                let viewModel = ServiceViewModel(service: service)
                return viewModel
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] (viewModel) in
                guard let this = self else { return }
                
                this.serviceViewController.representedObject = viewModel
            })
            .disposed(by: bag)
    }
    
    private func bindToButtons() {
        reloadButton
            .rx
            .controlEvent
            .debounce(0.5, scheduler: MainScheduler.instance)
            .bind(to: viewModel.refreshEvent)
            .disposed(by: bag)
    }
}
