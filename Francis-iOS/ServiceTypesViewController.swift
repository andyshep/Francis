//
//  ServiceTypesViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 11/10/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ServiceTypesViewController: UIViewController {
    
    private enum ReuseIdentifier {
        static let serviceTypeCell = "ServicesTypesCellIdentifier"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    private let viewModel = ServiceTypesViewModel()
    private let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Service Types", comment: "Service Types")
        
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: ReuseIdentifier.serviceTypeCell)
        
        viewModel.serviceTypes
            .bind(to: tableView.rx.items) { (tableView, row, service) in
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ReuseIdentifier.serviceTypeCell,
                    for: IndexPath(row: row, section: 0)
                )
                cell.textLabel?.text = service.name
                return cell
            }
            .disposed(by: bag)
        
        tableView.rx.modelSelected(NetService.self)
            .map { service -> ServicesViewModel in
                return ServicesViewModel(service: service)
            }
            .subscribe(onNext: { [weak self] (viewModel) in
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let identifier = String(describing: ServicesViewController.self)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: identifier) as? ServicesViewController else { return }
                
                viewController.viewModel = viewModel
                
                self?.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
