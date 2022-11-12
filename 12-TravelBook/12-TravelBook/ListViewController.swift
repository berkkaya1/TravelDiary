//
//  ListViewController.swift
//  12-TravelBook
//
//  Created by Berk Kaya on 12.11.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate,UITableViewDataSource {
    var titleNamesArray = [String]()
    var subTitleNamesArray = [String]()
    var idArray = [UUID]()
    
    var chosenID : UUID?
    var chosenTitle = ""
    

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target:self, action: #selector(addButtonClicked)
        )
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        getData()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    
    
    @objc func addButtonClicked(){
        chosenTitle = ""
        
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content = cell.defaultContentConfiguration()
        content.text = titleNamesArray[indexPath.row]
        content.secondaryText = subTitleNamesArray[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleNamesArray.count;
    }
    
   @objc func getData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetchRequest)
            
            if(results.count > 0){
                
                titleNamesArray.removeAll(keepingCapacity: false)
                subTitleNamesArray.removeAll(keepingCapacity: false)
                idArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject]{
                    if let title = result.value(forKey: "title") as? String{
                        self.titleNamesArray.append(title)
                    }
                    if let subtitle = result.value(forKey: "subtitle") as? String {
                        self.subTitleNamesArray.append(subtitle)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                }
                tableView.reloadData()
            }
        } catch {
            print( error.localizedDescription)
         }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenID = idArray[indexPath.row]
        chosenTitle = titleNamesArray[indexPath.row]
        self.performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destination = segue.destination as! ViewController
            destination.selectedTitle = chosenTitle
            destination.selectedTitleID = chosenID
        }
    }


}
