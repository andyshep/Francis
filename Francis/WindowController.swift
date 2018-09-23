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
    @IBOutlet private weak var interfacesButton: NSPopUpButton!
    @IBOutlet private weak var reloadButton: NSButton!
    
    lazy private var servicesViewController: ServicesViewController = {
        guard let splitViewController = contentViewController as? NSSplitViewController else { fatalError() }
        
        if #available(macOS 10.14, *) {
            guard let viewController = splitViewController.children.first as? ServicesViewController else { fatalError() }
            return viewController
        } else {
            guard let viewController = splitViewController.splitViewItems[0].viewController as? ServicesViewController else { fatalError() }
            return viewController
        }
    }()
    
    lazy private var serviceInfoViewController: ServiceInfoViewController = {
        guard let splitViewController = contentViewController as? NSSplitViewController else { fatalError() }
        
        if #available(macOS 10.14, *) {
            guard let viewController = splitViewController.children.last as? ServiceInfoViewController else { fatalError() }
            return viewController
        } else {
            guard let viewController = splitViewController.splitViewItems[1].viewController as? ServiceInfoViewController else { fatalError() }
            return viewController
        }
    }()
    
    @objc private var serviceTypes: [DNSSDService] = []
    
    @objc private var interfaceTypes: [String] {
        return ["Any", "Local Only", "Unicast", "P2P", "BLE"]
    }
    
    lazy private var serviceTypesArrayController: NSArrayController = {
        let arrayController = NSArrayController()
        arrayController.bind(.contentArray, to: self, withKeyPath: "serviceTypes")

        return arrayController
    }()
    
    lazy private var servicesArrayController: NSArrayController = {
        let arrayController = self.servicesViewController.servicesController
        return arrayController
    }()
    
    lazy private var interfacesArrayController: NSArrayController = {
        let arrayController = NSArrayController()
        arrayController.bind(.contentArray, to: self, withKeyPath: "interfaceTypes")
        
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
        
        interfacesButton.bind(.content, to: interfacesArrayController, withKeyPath: "arrangedObjects")
        interfacesButton.bind(.contentValues, to: interfacesArrayController, withKeyPath: "arrangedObjects")
        interfacesButton.bind(.selectedIndex, to: interfacesArrayController, withKeyPath: "selectionIndex")
        
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
                
                guard let service = this.serviceTypesArrayController.selectedObjects.first as? DNSSDService else { return nil }
                guard let interfaceObject = this.interfacesArrayController.selectedObjects.first else { return nil }
                
                let interfaceValue = interfaceObject as? String ?? "Any"
                guard let interface = DNSSDInterfaceType(string: interfaceValue) else { return nil }
                
                let viewModel = ServicesViewModel(service: service, interface: interface)
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
                
                guard let service = this.servicesArrayController.selectedObjects.first as? DNSSDService else { return nil }
                guard let interfaceObject = this.interfacesArrayController.selectedObjects.first else { return nil }
                
                let interfaceValue = interfaceObject as? String ?? "Any"
                guard let interface = DNSSDInterfaceType(string: interfaceValue) else { return nil }
                
                let viewModel = ServiceViewModel(service: service, interface: interface)
                return viewModel
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] (viewModel) in
                guard let this = self else { return }
                
                this.serviceInfoViewController.representedObject = viewModel
            })
            .disposed(by: bag)
        
        interfacesArrayController
            .rx
            .observeWeakly(Int.self, "selectionIndex", options: [.new])
            .map { [weak self] (index) -> ServiceTypesViewModel? in
                guard let this = self else { return nil }
                guard let selectedObject = this.interfacesArrayController.selectedObjects.first else { return nil }
                
                let interfaceValue = selectedObject as? String ?? "Any"
                guard let interface = DNSSDInterfaceType(string: interfaceValue) else { return nil }
                
                let viewModel = ServiceTypesViewModel(interface: interface)
                return viewModel
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self ] (viewModel) in
                guard let this = self else { return }
                
                this.serviceTypesViewModel = viewModel
                
                this.servicesViewController.representedObject = nil
                this.serviceInfoViewController.representedObject = nil
            })
            .disposed(by: bag)
    }
    
    private func bind(to viewModel: ServiceTypesViewModel) {
        serviceTypesViewModel
            .serviceTypes
            .asDriver(onErrorJustReturn: [])
            .map { (services) -> [DNSSDService] in
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
            .map { [weak self] event -> DNSSDInterfaceType? in
                let selectedObjct = self?.interfacesArrayController.selectedObjects.first
                let interfaceValue = (selectedObjct as? String) ?? "Any"
                guard let interface = DNSSDInterfaceType(string: interfaceValue) else { return nil }
                return interface
            }
            .filter { $0 != nil }
            .asDriver(onErrorJustReturn: DNSSDInterfaceType.any)
            .debounce(0.5)
            .drive(onNext: { [weak self] (interface) in
                guard let interface = interface else { return }
                self?.serviceTypesViewModel.refreshEvent.onNext((interface))
            })
            .disposed(by: bag)
    }
    
    private func createViewModel() {
        let interfaceValue = (interfacesArrayController.selectedObjects.first as? String) ?? "Any"
        guard let interface = DNSSDInterfaceType(string: interfaceValue) else { fatalError() }
        let viewModel = ServiceTypesViewModel(interface: interface)
        
        self.serviceTypesViewModel = viewModel
        
        bind(to: serviceTypesViewModel)
        
        servicesViewController.representedObject = serviceTypesViewModel
    }
}

extension DNSSDInterfaceType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .any: return "Any"
        case .localOnly: return "Local Only"
        case .unicast: return "Unicast"
        case .P2P: return "Peer-to-peer (P2P)"
        case .BLE: return "Bluetooth Low Energy (BLE)"
        }
    }
}
