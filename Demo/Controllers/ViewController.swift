  //
  //  ViewController.swift
  //  Basic Chat
  //
  //  Created by Trevor Beaton on 2/3/21.
  //

  import UIKit
  import CoreBluetooth

  class ViewController: UIViewController {

      // UI
      @IBOutlet weak var tableView: UITableView!
      @IBOutlet weak var peripheralFoundLabel: UILabel!
      @IBOutlet weak var scanningLabel: UILabel!
      @IBOutlet weak var scanningButton: UIButton!

      @IBAction func scanningAction(_ sender: Any) {
      startScanning()
    }

      override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
        // Manager
         
      }

      override func viewDidAppear(_ animated: Bool) {
      }
      
      func startScanning() {
          
      }
  }

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

      let cell = tableView.dequeueReusableCell(withIdentifier: "BlueCell") as! TableViewCell
      cell.peripheralLabel.text = "Unknown"
        return cell
    }
}

  // MARK: - UITableViewDelegate
  // Methods for managing selections, deleting and reordering cells and performing other actions in a table view.
  extension ViewController: UITableViewDelegate {

      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      }
  }

