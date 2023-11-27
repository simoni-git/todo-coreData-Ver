//
//  ViewModel.swift
//  coredata+todo2
//
//  Created by MAC on 11/27/23.
//
import UIKit
import Foundation
import CoreData

class ViewModel {
    
    var context:NSManagedObjectContext {
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }
        return app.persistentContainer.viewContext
    }
    
    var tasks: [TaskStruct] = []
    var VC: ViewController?
    
    func saveData(tasktitle: String , taskmemo: String , taskdone: Bool) {
        let newEntity = NSEntityDescription.insertNewObject(forEntityName: "TaskEntity", into: self.context)
        newEntity.setValue(tasktitle, forKey: "name")
        newEntity.setValue(taskmemo, forKey: "memo")
        newEntity.setValue(taskdone, forKey: "done")
       
        if self.context.hasChanges {
            do {
                try self.context.save()
                print("coredata에 저장완료")
            } catch {
                print(error)
            }
        }
    }
    
    func deleteData(task: TaskStruct) {
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
            VC?.tableView.reloadData()
        }
    }
    
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
            VC?.tableView.reloadData()
        } catch {
            print(error)
        }
    }
    
    func changeStatus(at index: Int) {
        var task = tasks[index]
        
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
        
    }
    
    
}
