//
//  ServicesViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 11/10/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ServicesViewController: UIViewController {
    
    enum ReuseIdentifier {
        static let servicesCell = "ServicesCellIdentifier"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    public var viewModel: ServicesViewModel!
    
    private let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.title
            .bind(to: rx.title)
            .disposed(by: bag)
        
        viewModel.services
            .bind(to: tableView.rx.items) { tableView, row, service in
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ReuseIdentifier.servicesCell,
                    for: IndexPath(row: row, section: 0)
                )
                cell.textLabel?.text = service.name
                return cell
            }
            .disposed(by: bag)
        
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: ReuseIdentifier.servicesCell)
        
        tableView.rx.modelSelected(NetService.self)
            .map { (service) -> ServiceViewModel in
                return ServiceViewModel(service: service)
            }
            .subscribe(onNext: { [weak self] (viewModel) in
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let identifier = String(describing: ServiceViewController.self)
                guard let viewController = storyboard.instantiateViewController(withIdentifier: identifier) as? ServiceViewController else { return }
                
                viewController.viewModel = viewModel
                
                self?.navigationController?.pushViewController(viewController, animated: true)
            })
            .disposed(by: bag)

        viewModel.refreshEvent.onNext(())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
