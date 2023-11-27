//
//  ViewController.swift
//  coredata+todo2
//
//  Created by MAC on 2023/09/17.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    var viewmodel = ViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewmodel.readData()
        self.tableView.dataSource = self
        self.tableView.delegate = self
       
    }
   
    @IBAction func tapAddButton(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "등록", message: nil, preferredStyle: .alert)
        let registerButton = UIAlertAction(title: "등록하기", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text else {return}
            guard let memo = alert.textFields?[1].text else {return}
           
            let task = TaskStruct(tasktitle: name, taskmemo: memo, taskdone: false)
            self!.viewmodel.tasks.append(task)
            self?.tableView.reloadData()
            self!.viewmodel.saveData(tasktitle: name, taskmemo: memo, taskdone: task.taskdone)
        }
        let cancelButton = UIAlertAction(title: "취소", style: .cancel , handler: nil)
        
        alert.addAction(registerButton)
        alert.addAction(cancelButton)
        
        alert.addTextField { textField1 in
            textField1.placeholder = "할일을 입력해주세요"
        }
        alert.addTextField { textField2 in
            textField2.placeholder = "메모를 입력해주세요"
        }
        
        self.present(alert, animated: true)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewmodel.tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ListCell else {
            return UITableViewCell()
        }
        
        let task = viewmodel.tasks[indexPath.row]
        cell.taskLabel.text = task.tasktitle
        cell.memoLabel.text = task.taskmemo
        
        if task.taskdone {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let taskToDelete = viewmodel.tasks[indexPath.row]
            viewmodel.deleteData(task: taskToDelete)
        }
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "상태를 변경하시겠습니까?", message: nil, preferredStyle: .alert)
        let okButton = UIAlertAction(title: "상태변경", style: .default) { [weak self] _ in
            guard let self = self else {return}
            var task = viewmodel.tasks[indexPath.row]
            task.taskdone = !task.taskdone
            viewmodel.tasks[indexPath.row] = task
            viewmodel.changeStatus(at: indexPath.row)

            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        let noButton = UIAlertAction(title: "취소", style: .cancel , handler:  nil)
        
        alert.addAction(okButton)
        alert.addAction(noButton)
        self.present(alert, animated: true)
        
    }
}

class ListCell:UITableViewCell {
    
    @IBOutlet var 할일: UILabel!
    @IBOutlet var 메모: UILabel!
    
    @IBOutlet var taskLabel: UILabel!
    @IBOutlet var memoLabel: UILabel!
}

