//
//  OJADownloadManager.swift
//  LXMDownloader_Example
//
//  Created by luxiaoming on 2019/1/4.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import LXMDownloader

let kLXMDidFinishDownloadNotification = "kLXMDidFinishDownloadNotification"

private let kLXMdownloadFolder = "LXMDownloads"
private let kLXMDownloadSavedModelKey = "kLXMDownloadSavedModelKey"

let kOJSUserDefaults = UserDefaults.standard
let kOJSFileManager = FileManager.default
let kOJSUserDocumentDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
let kOJSUserCacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]


class LXMVideoDownloadManager: NSObject {
    
    static let shared = LXMVideoDownloadManager()
    
    static let sessionIdentifier = "com.test.download"

    var selectedDefinition: String = "标清"
    
    fileprivate(set) var downloader: LXMDownloader = {
        var modelArray = [TestVideoModel]()
        if let data = kOJSUserDefaults.data(forKey: kLXMDownloadSavedModelKey),
            let array = NSKeyedUnarchiver.unarchiveObject(with: data) as? [TestVideoModel] {
            for model in array {
                if let downloadItem = model.lxm_downloadItem {
                    if downloadItem.downloadStatus == .downloading || downloadItem.downloadStatus == .waiting {
                        downloadItem.downloadStatus = .paused
                    }
                    modelArray.append(model)
                }
            }
        }
        let config = URLSessionConfiguration.background(withIdentifier: LXMVideoDownloadManager.sessionIdentifier)
        let downloader = LXMDownloader(sessionConfiguration: config, downloadFolderName: kLXMdownloadFolder, modelArray: modelArray)
        downloader.maxConcurrentTaskCount = 2
        return downloader
        
    }()
    
    var allArray: [TestVideoModel] {
        return self.downloader.allArray as! [TestVideoModel]
    }
    
    var downloadingArray: [TestVideoModel] {
        return self.downloader.downloadingArray as! [TestVideoModel]
    }
    
    var finishedArray: [TestVideoModel] {
        return self.downloader.finishedArray as! [TestVideoModel]
    }
    
    
    
    fileprivate override init() {
        super.init()
        downloader.shouldSaveDownloadModelBlock = { [weak self] in
            self?.saveToUserDefaults()
        }
        downloader.downloadDidFailBlock = { [weak self] (model) in
            self?.saveToUserDefaults()
        }
        downloader.downloadDidFinishBlock = { [weak self] (model) in
            self?.saveToUserDefaults()
            if let model = model as? TestVideoModel {
                NotificationCenter.default.post(name: Notification.Name(kLXMDidFinishDownloadNotification), object: model)
            }
        }
    }
}

// MARK: - PrivateMethod
private extension LXMVideoDownloadManager {
    
    func saveToUserDefaults() {
        // 持久化有多重方案可选，数据库，CoreData都可以，我这里就直接用UserDefaults了，只要目标model是可以序列化的就行。
        let data = NSKeyedArchiver.archivedData(withRootObject: self.downloader.allArray)
        kOJSUserDefaults.set(data, forKey: kLXMDownloadSavedModelKey)
        kOJSUserDefaults.synchronize()
    }
    
}

// MARK: - PublicMethod
extension LXMVideoDownloadManager {
    
    func downloadAction(forVideoModel videoModel: TestVideoModel, completion:@escaping ()->Void) {
        guard let allArray = self.downloader.allArray as? [TestVideoModel] else { return }
        for model in allArray {
            //注意，如果存在，要修改model的状态，而不是videoModel的
            if model.videoId == videoModel.videoId {
                guard let item = model.lxm_downloadItem else { return }
                switch item.downloadStatus {
                case .none:
                    self.download(videoModel: model)//理论上不会出现存在数组里又为none的状态
                case .downloading:
                    self.pauseDownload(videoModel: model, completion: nil)
                case .paused:
                    self.download(videoModel: model) //判断是否要转为waiting在内部已经做了
                case .waiting:
                    self.pauseDownload(videoModel: model, completion: nil) //理论上不存在需要手动从waiting转换为downloading的任务
                case .finished:
                    print("您已经下载过该视频了")
                case .failed:
                    print("下载失败")
                    
                }
                completion()
                return //如果已经存在了，执行完上面的操作就能return了
            }
        }
        self.download(videoModel: videoModel)
        completion()
    }
    
    func download(videoModel: TestVideoModel) {
        var urlString: String = videoModel.videoUrl_normal
        if self.selectedDefinition == "流畅" {
            urlString = videoModel.videoUrl_low
        } else if self.selectedDefinition == "标准" {
            urlString = videoModel.videoUrl_normal
        } else if self.selectedDefinition == "高清" {
            urlString = videoModel.videoUrl_high
        }
        guard let url = URL(string: urlString) else {
            return
        }
        // 注意！在调用downloader的download方法之前，一定要设置好lxm_downloadItem，不然会匹配不到数据
        if videoModel.lxm_downloadItem == nil {
            videoModel.lxm_downloadItem = LXMDownloaderItem(itemId: "\(videoModel.videoId)", urlString: url.absoluteString)
        }
        
        self.downloader.download(item: videoModel, completion: { (success) in
            if success {
                print("已经开始下载")
            }
        })
        
        
    }
    
    func pauseDownload(videoModel: TestVideoModel, completion:(()->Void)?) {
        self.downloader.pauseDownload(item: videoModel, completion: completion)
    }
    
    func deleteDownload(videoModel: TestVideoModel) {
        self.downloader.deleteDownload(item: videoModel)
    }
    
    
    
    /// 这个方法需要的时候主动调用，注意！！！
    func updateDownloadModel(targetModel: TestVideoModel) {
        let targetItemId = "\(targetModel.videoId)"
        for model in self.downloader.allArray {
            if model.lxm_downloadItem.itemId == targetItemId {
                targetModel.lxm_downloadItem = model.lxm_downloadItem
                return
            }
        }
        targetModel.lxm_downloadItem = nil
    }
}


// MARK - 路径相关方法
extension LXMVideoDownloadManager {
    /// 注意返回的是URL路径，不是string
    @objc class func localPath(forModel model: TestVideoModel) -> URL? {
        guard let item = model.lxm_downloadItem else { return nil }
        let path = LXMVideoDownloadManager.shared.downloader.localPath(forItem: item, isResumeData: false)
        return path
    }
    
    @objc class func hasLocalFile(forModel model: TestVideoModel) -> Bool {
        guard let item = model.lxm_downloadItem else { return false }
        return LXMVideoDownloadManager.shared.downloader.hasLocalFile(forItem: item)
    }
}
