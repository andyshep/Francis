//
//  ServiceInfoViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 4/7/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import Cocoa
import RxSwift

class ServiceInfoViewController: NSViewController {
    
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
        
        self.rx.observe(ServiceViewModel.self, "representedObject")
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] (representedObject) in
                guard let this = self else { return }
                
                guard let viewModel = representedObject else {
                    this.willChangeValue(for: \.entries)
                    this.entries = [:]
                    this.didChangeValue(for: \.entries)
                    return
                }
                
                let service = viewModel.service
                let interface = viewModel.interface
                
                service.delegate = this
                service.startResolve(on: interface)
            })
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
}

extension ServiceInfoViewController: DNSSDServiceDelegate {
    
    func dnssdService(_ service: DNSSDService, didNotResolve error: Error?) {
        print("\(#function): unhandled \(error.debugDescription)")
    }
    
    func dnssdServiceDidResolveAddress(_ service: DNSSDService) {
        guard let entries = service.entries else { return print("\(#function): missing TXT record entries") }
        
        self.willChangeValue(for: \.entries)
        self.entries = entries
        self.didChangeValue(for: \.entries)
    }
    
    func dnssdServiceDidStop(_ service: DNSSDService) {
        service.stop()
        service.delegate = nil
    }
}
