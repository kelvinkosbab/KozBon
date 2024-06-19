//
//  EditTxtRecordsViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 7/10/21.
//  Copyright © 2021 Kozinga. All rights reserved.
//

import UIKit

// MARK: - EditTxtRecordsViewController

protocol EditTxtRecordsDelegate: AnyObject {
    func didUpdate(txtRecords: [String: String])
}

class EditTxtRecordsViewController: MyTableViewController {

    // MARK: - Static

    static func newViewController(txtRecords: [String: String], delegate: EditTxtRecordsDelegate) -> EditTxtRecordsViewController {
//        let viewController = self.newStoryboardController(fromStoryboardWithName: "Services", withIdentifier: "EditTxtRecordsViewController") as! EditTxtRecordsViewController
//        viewController.dataSource.txtRecords = txtRecords
//        viewController.delegate = delegate
//        return viewController
        EditTxtRecordsViewController()
    }

    // MARK: - Properties

    private let dataSource = DataSource()
    weak var delegate: EditTxtRecordsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "TXT Records"

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                target: self,
                                                                action: #selector(self.cancelButtonSelected))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                                target: self,
                                                                action: #selector(self.doneButtonSelected))
    }

    // MARK: - Actions

    @objc func cancelButtonSelected() {
        self.dismissController()
    }

    @objc func doneButtonSelected() {
        self.delegate?.didUpdate(txtRecords: self.dataSource.txtRecords)
        self.dismissController()
    }

    // MARK: - TableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.dataSource.txtRecords.count > 0 {
            return 2
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.getTxtSection() ?? 0) + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == self.getTxtSection() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TxtRecordCell", for: indexPath) as! TxtRecordCell
            return cell
        } else if indexPath.section == self.getAddTxtSection() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddTxtRecordCell", for: indexPath) as! AddTxtRecordCell
            return cell
        }

        // Invalid section
        fatalError()
    }

    private func getTxtSection() -> Int? {
        return self.dataSource.txtRecords.count > 0 ? 0 : nil
    }

    private func getAddTxtSection() -> Int {
        return self.dataSource.txtRecords.count > 0 ? 1 : 0
    }

    // MARK: - DataSource

    private class DataSource {

        var txtRecords: [String: String] = [:]

        func getCurrentTxtRecords() -> [String: String] {
            return self.txtRecords
        }

        func addTxtRecord(value: String, forKey key: String) {
            self.txtRecords[key] = value
        }

        func removeTxtRecord(forKey key: String) {
            self.txtRecords.removeValue(forKey: key)
        }
    }
}
