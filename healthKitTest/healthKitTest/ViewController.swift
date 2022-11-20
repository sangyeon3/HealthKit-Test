//
//  ViewController.swift
//  healthKitTest
//
//  Created by  sangyeon on 2022/11/20.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    let typesToShare: Set<HKSampleType> = [.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                           .workoutType(),
                                           .quantityType(forIdentifier: .activeEnergyBurned)!,]
    let typesToRead: Set<HKObjectType> = [.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                          .workoutType(),
                                          .quantityType(forIdentifier: .activeEnergyBurned)!,
                                          .quantityType(forIdentifier: .appleExerciseTime)!]    // share 불가능
    var workoutData: [HKWorkout] = []
    var walkingData: [HKQuantitySample] = []
    let dateFormatter = DateFormatter()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureUI()
        requestHealthAuthorization()
//        saveWalkingData()
    }

    private func configureUI() {
        title = "걷기 + 달리기 기록"

        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        tableView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
    
    private func requestHealthAuthorization() {
        healthStore.requestAuthorization(toShare: typesToShare,
                                         read: typesToRead,
                                         completion: { success, error in
            if error != nil {
                print(error.debugDescription)
            } else {
                if success {
                    print("HealthStore 권한 허용")
                }
                else { print("HealthStore 권한 허용되지 않음") }
            }
        })
    }
    
    private func fetchWalkingData() {
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                  predicate: predicate,
                                  limit: 30,
                                  sortDescriptors: [sortDescriptor],
                                  resultsHandler: { [weak self] query, result, error in
            if error != nil {
                print(error.debugDescription)
                return
            }
            
            if let result = result {
                DispatchQueue.main.async {
                    print(result)
                    self?.walkingData = result as? [HKQuantitySample] ?? []
                    self?.tableView.reloadData()
                }
            }
        })
        healthStore.execute(query)
    }
    
    private func fetchWorkoutData() {
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: HKSampleType.workoutType(),
                                  predicate: predicate,
                                  limit: 30,
                                  sortDescriptors: [sortDescriptor],
                                  resultsHandler: { [weak self] query, result, error in
            if error != nil {
                print(error.debugDescription)
                return
            }
            
            if let result = result {
                DispatchQueue.main.async {
                    print(result)
                    self?.workoutData = result as? [HKWorkout] ?? []
                    self?.tableView.reloadData()
                }
            }
        })
        healthStore.execute(query)
    }
    
    private func saveWalkingData() {
        let start = convertStringToDateWithTime(str: "2022-11-20 18:00")
        let end = convertStringToDateWithTime(str: "2022-11-20 18:10")
        let object = HKQuantitySample(type: .quantityType(forIdentifier: .distanceWalkingRunning)!,
                                      quantity: .init(unit: .meter(), doubleValue: 30.0),
                                      start: start, end: end)
        healthStore.save(object, withCompletion: { [weak self] success, error in
            if error != nil {
                print(error.debugDescription)
                return
            }
            if success {
                print("데이터 저장 성공")
                self?.fetchWalkingData()
            } else { print("데이터 저장 실패") }
        })
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return walkingData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        let data = walkingData[indexPath.row]
        let date = convertDateToString(date: data.startDate)
        let start = convertDateToStringOnlyTime(date: data.startDate)
        let end = convertDateToStringOnlyTime(date: data.endDate)
        let meterData = data.quantity.doubleValue(for: .meter())
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(date) \(start)~\(end) \(meterData)m"
        cell.contentConfiguration = content
        return cell
    }
}

extension ViewController {
    
    func convertDateToString(date: Date) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    
    func convertDateToStringOnlyTime(date: Date) -> String {
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
    
    func convertStringToDateWithTime(str: String) -> Date {
        dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "KST")
        return dateFormatter.date(from: str)!
    }
}
