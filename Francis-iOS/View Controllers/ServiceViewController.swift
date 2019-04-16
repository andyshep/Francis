//
//  ServiceViewController.swift
//  Francis
//
//  Created by Andrew Shepard on 11/10/18.
//  Copyright © 2018 Andrew Shepard. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ServiceViewController: UIViewController {
    
    enum ReuseIdentifier {
        static let entryCell = "EntryCellIdentifier"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: ServiceViewModel!
    
    private let bag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.title
            .bind(to: rx.title)
            .disposed(by: bag)
        
        viewModel.entries
            .bind(to: tableView.rx.items) { tableView, row, entry in
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: ReuseIdentifier.entryCell)
                
                cell.textLabel?.text = entry.value
                cell.detailTextLabel?.text = entry.key
                
                return cell
            }
            .disposed(by: bag)
        
        viewModel.refreshEvent.onNext(())
    }
}
