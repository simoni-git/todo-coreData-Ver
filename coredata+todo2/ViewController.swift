//
//  ViewController.swift
//  coredata+todo2
//
//  Created by MAC on 2023/09/17.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    var context:NSManagedObjectContext {
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }
        return app.persistentContainer.viewContext
    }

    var tasks = [TaskStruct]()
    
    
    
    @IBOutlet var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        readData()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        // Do any additional setup after loading the view.
    }
    // MARK: - ⬇️추가버튼 눌렀을때 작동하는코드들
    @IBAction func tapAddButton(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "등록", message: nil, preferredStyle: .alert)
        let registerButton = UIAlertAction(title: "등록하기", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text else {return}
            guard let memo = alert.textFields?[1].text else {return}
            
            let task = TaskStruct(tasktitle: name, taskmemo: memo, taskdone: false)
            self?.tasks.append(task)
            self?.tableView.reloadData()
            
            //⬇️coredata 에도 저장하기
            let newEntity = NSEntityDescription.insertNewObject(forEntityName: "TaskEntity", into: self!.context)
            newEntity.setValue(name, forKey: "name")
            newEntity.setValue(memo, forKey: "memo")
            newEntity.setValue(task.taskdone, forKey: "done")
            //⬇️영구저장소에도 저장하는코드
            if self!.context.hasChanges {
                do {
                    try self!.context.save()
                    print("coredata에 저장완료")
                } catch {
                    print(error)
                }
            }
                    
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
    // MARK: - 저장된정보들을 가져오는 코드들
    //우선 coredata에 저장된정보를 [TaskStruct] 타입으로 변환시켜줄메서드구현
    func changeType(_ managedObject:NSManagedObject) -> TaskStruct {
        let name = managedObject.value(forKey: "name") as? String ?? ""
        let memo = managedObject.value(forKey: "memo") as? String ?? ""
        let done = managedObject.value(forKey: "done") as? Bool ?? false
        return TaskStruct(tasktitle: name, taskmemo: memo, taskdone: done)
    }
    
    func readData() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "TaskEntity")
        
        do {
            let data = try context.fetch(request)
            tasks = data.map {changeType($0)}
            self.tableView.reloadData()
        } catch {
            print(error)
        }
    }
    
    // MARK: - 배열과 coredata 에서 정보를 지우는 코드들
    //우선 Entity정보를 가져오는것부터 시작
    func deleteTask(task: TaskStruct) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "name == %@", task.tasktitle)
        
        do {
            let results = try context.fetch(request)
            for taskEntity in results as! [TaskEntity] {
                context.delete(taskEntity)
            }
            try context.save()
            print("coredata 에서 삭제완료.")
        } catch {
            print("coredata 에서 삭제실패 \(error)")
        }
        
        
        if let index = tasks.firstIndex(where: { $0.tasktitle == task.tasktitle
        }) {
            tasks.remove(at: index)
            tableView.reloadData()
        }
        
        // 여기 과정까지하고 이 메서드를 commit부분에 업데이트시켜줘야함.
    }
    
    
    
    


}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ListCell else {
            return UITableViewCell()
        }
        let task = tasks[indexPath.row]
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
            let taskToDelete = tasks[indexPath.row] // 삭제할 데이터를 가져옴
            deleteTask(task: taskToDelete) // 데이터를 삭제하는 함수 호출
           
//            self.tasks.remove(at: indexPath.row)
//            self.tableView.reloadData()      << 원래 이 두줄이 처음작성한코드지만 삭제코드를 구현해주고나서 위와같이 수정해줌.
           
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
            var task = tasks[indexPath.row]
            task.taskdone = !task.taskdone
            self.tasks[indexPath.row] = task
            
            //⬇️ 위에까진 변경사항을 배열에 저장한거고 이제는 coredata 에도 적용시켜주는코드
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "name == %@", task.tasktitle)
            do {
                if var taskManegedObject = try context.fetch(request).first as? TaskEntity { 
                    taskManegedObject.done = task.taskdone
                    
                    if context.hasChanges {
                        try context.save()
                        print("coredata 완료여부변경저장성공")
                    }
                }
            } catch {
                 print("coredata 완료여부변경저장 실패\(error)")
            }
            
            
            
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

