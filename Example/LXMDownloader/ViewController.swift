//
//  ViewController.swift
//  LXMDownloader
//
//  Created by billthas@gmail.com on 01/03/2019.
//  Copyright (c) 2019 billthas@gmail.com. All rights reserved.
//

import UIKit

let kLXMDidStartDownloadNotification = "kLXMDidStartDownloadNotification";

class ViewController: UIViewController {
    
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
extension ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "target"
        
        self.view.addSubview(tableView)
        
        let one = TestVideoModel()
        one.videoId = 1
        one.videoUrl_normal = "https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4"
        
        let two = TestVideoModel()
        two.videoId = 2
        two.videoUrl_normal = "https://images.apple.com/media/cn/macbook-pro/2016/b4a9efaa_6fe5_4075_a9d0_8e4592d6146c/films/design/macbook-pro-design-tft-cn-20161026_1536x640h.mp4"
        
        let three = TestVideoModel()
        three.videoId = 3
        three.videoUrl_normal = "https://www.apple.com/105/media/cn/ipad-pro/how-to/2017/a0f629be_c30b_4333_942f_13a221fc44f3/films/dock/ipad-pro-dock-cn-20160907_1280x720h.mp4"
        
        let four = TestVideoModel()
        four.videoId = 4
        four.videoUrl_normal = "https://www.apple.com/105/media/cn/ipad/2018/08716702_0a2f_4b2c_9fdd_e08394ae72f1/films/use-two-apps/ipad-use-two-apps-tpl-cn-20180404_1280x720h.mp4"
        
        let five = TestVideoModel()
        five.videoId = 5
        five.videoUrl_normal = "https://www.apple.com/105/media/us/imac-pro/2018/d0b63f9b_f0de_4dea_a993_62b4cb35ca96/hero/large.mp4"
        
        self.dataArray = [one, two, three, four, five]
        self.updateDataArray()
        
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
private extension ViewController {
    
    func updateDataArray() {
        for model in self.dataArray {
            LXMVideoDownloadManager.shared.updateDownloadModel(targetModel: model)
        }
        self.tableView.reloadData()
    }
    
}



// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
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
extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TestDownloadItemCell.kStaticHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = self.dataArray[indexPath.row]
        LXMVideoDownloadManager.shared.downloadAction(forVideoModel: model, completion: { [weak self] in
            self?.dataArray.remove(at: indexPath.row)
            self?.tableView.reloadData()
            NotificationCenter.default.post(name: NSNotification.Name(kLXMDidStartDownloadNotification), object: nil)
        })
    }
    
}

