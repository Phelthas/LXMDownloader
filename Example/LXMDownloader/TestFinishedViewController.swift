//
//  TestFinishedViewController.swift
//  LXMDownloader_Example
//
//  Created by luxiaoming on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class TestFinishedViewController: UIViewController {

    lazy var tableView: UITableView = {
        
        let tableView = UITableView(frame: UIScreen.main.bounds, style: .plain)
        tableView.backgroundColor = UIColor.white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UINib.init(nibName: TestDownloadItemCell.kStaticIdentifier, bundle: nil), forCellReuseIdentifier: TestDownloadItemCell.kStaticIdentifier)
        tableView.tableFooterView = UIView()
        //下面这三句代码是为了防止ios11上估算高度，导致cellForRow在cellHight之前走
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        
        return tableView
    }()
    
    var dataArray = [TestVideoModel]()
    

}

// MARK: - Lifecycle
extension TestFinishedViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "finished"
        
        self.view.addSubview(tableView)
        
        updateDataArray()
        
        
        NotificationCenter.default.addObserver(self, name: kLXMDidStartDownloadNotification) { [weak self] (sender) in
            self?.updateDataArray()
        }
        
        NotificationCenter.default.addObserver(self, name: kLXMDidFinishDownloadNotification) { [weak self] (sender) in
            self?.updateDataArray()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}



// MARK: - PrivateMethod
private extension TestFinishedViewController {
    
    func updateDataArray() {
        self.dataArray = LXMVideoDownloadManager.shared.finishedArray
        self.tableView.reloadData()
    }
}



// MARK: - UITableViewDataSource
extension TestFinishedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TestDownloadItemCell.kStaticIdentifier) as! TestDownloadItemCell
        cell.videoModel = self.dataArray[indexPath.row]
        return cell
    }
    
}


// MARK: - UITableViewDelegate
extension TestFinishedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TestDownloadItemCell.kStaticHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = self.dataArray[indexPath.row]
        TestPlayerViewController.play(localModel: model, inNav: self.navigationController)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let model = self.dataArray[indexPath.row]
        LXMVideoDownloadManager.shared.deleteDownload(videoModel: model)
        self.updateDataArray()
    }
}
