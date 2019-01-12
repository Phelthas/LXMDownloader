//
//  LXMDownloader.swift
//  LXMDownloader
//
//  Created by luxiaoming on 2019/1/3.
//

import UIKit
import AFNetworking

private let kLXMDownloaderDefaultSessionIdentifier = "com.lxm.downloader"
private let kLXMDownloaderDefaultSaveDirectoryPath = "LXMDownloads"
private let kLXMDownlaoderAllowsCellularAccessKey = "kLXMDownlaoderAllowsCellularAccessKey"

private let kOJSUserDefaults = UserDefaults.standard
private let kOJSFileManager = FileManager.default
private let kOJSUserDocumentDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
private let kOJSUserCacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]


public typealias LXMDownloadSimpleCallback = () -> Void
public typealias LXMDownloadCompletion = (LXMDownloaderModelProtocol?) -> Void

@objcMembers
public class LXMDownloader: NSObject {
    
    
    /// 设置是否允许使用蜂窝网络下载，如果在设置false的时候是蜂窝网络的话，会暂停正在下载的任务
    /// 注意：不能用self.downloadSession.requestSerializer.allowsCellularAccess或者URLSessionConfiguration的allowsCellularAccess属性，这些对已经开始的任务都是无效的，还是得自己定义属性，在设置的时候手动暂停下载
    public var allowsCellularAccess: Bool = false {
        didSet {
            if allowsCellularAccess == false && self.downloadSession.reachabilityManager.isReachableViaWiFi == false {
                for model in self.downloadingArray {
                    if model.lxm_downloadItem.downloadStatus == .downloading || model.lxm_downloadItem.downloadStatus == .waiting {
                        self.pauseDownload(item: model, completion: nil)
                    }
                }
            }
            kOJSUserDefaults.set(allowsCellularAccess, forKey: self.sessionIdentifier + kLXMDownlaoderAllowsCellularAccessKey)
            kOJSUserDefaults.synchronize()
        }
    }
    
    
    /// 设置允许的最大并发数，如果设置的数小于正在进行的任务，会暂停某些任务以满足这个限制
    public var maxConcurrentTaskCount: Int = 2 {
        didSet {
            self.lock.lock()
            let downloadingArray = self.allArray.filter { (model) -> Bool in
                return model.lxm_downloadItem.downloadStatus == .downloading
            }
            self.lock.unlock()
            if downloadingArray.count > self.maxConcurrentTaskCount {
                for i in 0 ..< downloadingArray.count {
                    let model = downloadingArray[i]
                    if i >= maxConcurrentTaskCount {
                        self.pauseDownload(item: model, completion: nil)
                        model.lxm_downloadItem.downloadStatus = .waiting
                    }
                }
                self.shouldSaveDownloadModelBlock?()
            }
        }
    }
    
    
    /// 这个是仿照AFNetworking的实现写的，在读取或修改allArray时，都需要用锁来保证线程安全。
    /// 在下载视频这个场景应该是用不到的，用户点击下载这个操作应该都是在主线程的，以防万一还是写上吧
    fileprivate var lock = NSLock()

    public fileprivate(set) var allArray = [LXMDownloaderModelProtocol]()
    
    public fileprivate(set) var downloadFolderName: String
    
    public var downloadingArray: [LXMDownloaderModelProtocol] {
        self.lock.lock()
        let downloadingArray = allArray.filter({ (model) -> Bool in
            return model.lxm_downloadItem.downloadStatus == .paused
                || model.lxm_downloadItem.downloadStatus == .downloading
                || model.lxm_downloadItem.downloadStatus == .waiting
                || model.lxm_downloadItem.downloadStatus == .failed
        })
        self.lock.unlock()
        return downloadingArray
    }
    
    public var finishedArray: [LXMDownloaderModelProtocol] {
        self.lock.lock()
        let finishedArray = allArray.filter({ (model) -> Bool in
            return model.lxm_downloadItem.downloadStatus == .finished
        })
        self.lock.unlock()
        return finishedArray
    }
    
    
    public var sessionIdentifier: String {
        return self.downloadSession.session.configuration.identifier ?? kLXMDownloaderDefaultSessionIdentifier
    }
    
    public fileprivate(set) var downloadSession: AFURLSessionManager
    
    public var shouldSaveDownloadModelBlock: LXMDownloadSimpleCallback?
    
    public var downloadDidFailBlock: LXMDownloadCompletion?
    
    public var downloadDidFinishBlock: LXMDownloadCompletion?
    
    public init(sessionConfiguration: URLSessionConfiguration, downloadFolderName: String, modelArray: [LXMDownloaderModelProtocol]) {
        //注意设置顺序，没有allArray之前没办法getDownloadModel，没有downloadFolderName之前没办法createDownloadFolderIfNeeded，
        self.allArray = modelArray
        self.downloadFolderName = downloadFolderName
        let key = (sessionConfiguration.identifier ?? kLXMDownloaderDefaultSessionIdentifier) + kLXMDownlaoderAllowsCellularAccessKey
        self.allowsCellularAccess = kOJSUserDefaults.bool(forKey: key)
        self.downloadSession = AFURLSessionManager(sessionConfiguration: sessionConfiguration)
        super.init()
        //注意！这里必须要在创建downloadSession后立刻设置回调，因为如果有APP被kill时取消的任务，会在session创建且设置delegate后立刻调用回调，如果那时候还没设置回调，那APP重启时的resumeData就拿不到了
        // 注意这个方法与setDownloadTaskDidFinishDownloadingBlock不同，是执行了download方法的completionBlock之后，在执行这个block
        self.downloadSession.setTaskDidComplete { [weak self] (session, sessionTask, error) in
            
            DispatchQueue.main.async {
                guard let downloadTask = sessionTask as? URLSessionDownloadTask,
                    let model = self?.getDownloadModel(forDownloadTask: downloadTask) else {
                        self?.downloadDidFailBlock?(nil)
                        return
                }
                if let response = downloadTask.response as? HTTPURLResponse, response.statusCode >= 400 {
                    model.lxm_downloadItem.downloadStatus = .failed
                    self?.clearResumeData(forItem: model.lxm_downloadItem)
                    self?.downloadDidFailBlock?(model)
                    return
                }
                if let error = error as NSError? {
                    if error.code == NSURLErrorCancelled {
                        //取消的时候也会调用到这个回调，errorCode是-999
                        if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                            self?.saveResumeData(data: resumeData, forItem: model.lxm_downloadItem)
                        }
                    } else {
                        self?.downloadDidFailBlock?(model)
                    }
                } else {
                    model.lxm_downloadItem.downloadStatus = .finished
                    model.lxm_downloadItem.completedUnitCount = model.lxm_downloadItem.totalUnitCount //这一句是为了修复在后台完成下载时，item的completedUnitCount没有更新的问题
                    self?.clearResumeData(forItem: model.lxm_downloadItem)
                    self?.startDownloadNextIfNeeded(forItem: model.lxm_downloadItem)
                    self?.downloadDidFinishBlock?(model)
                }
                
            }
            
        }
        
        //注意：直接用download方法的block不行，因为AFNetworking的文档说了，进入后台后APP可能被系统kill掉，而block可能会丢失，所以如果要支持后台下载，就必须用delegate的方式或者用setDownloadTaskDidFinishDownloadingBlock方法，这些方法在session重新创建的时候会重新调用，所以不存在丢失的问题
        //注意：setDownloadTaskDidFinishDownloadingBlock方法后，download方法中的destinationb的block就不会执行了，因为这里AFNetworking模拟了多个代理的模式，在session的delegate中，找到真正的delegate再执行方法。而如果执行了setDownloadTaskDidFinishDownloadingBlock后会直接return。
        self.downloadSession.setDownloadTaskDidFinishDownloadingBlock { [weak self] (session, downloadTask, localURL) -> URL? in
            if let model = self?.getDownloadModel(forDownloadTask: downloadTask) {
                return self?.localPath(forItem: model.lxm_downloadItem, isResumeData: false)
            }
            return nil
        }
        
        
        self.createDownloadFolderIfNeeded()
        
        //这个通知是为了通知外部在APP被kill之前执行一次save操作，以保存下载进度和状态，因为下载进度不会实时保存
        NotificationCenter.default.addObserver(self, selector: #selector(delegateShouldSaveDownloadModel), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func delegateShouldSaveDownloadModel() {
        self.shouldSaveDownloadModelBlock?()
    }
    
}

// MARK: - PrivateMethod
private extension LXMDownloader {
    
    
    /// 根据downloadTask来找到对应的model
    /// 如果APP在前台或者在后台但是还没有被kill，那直接用lxm_downloadItem.downloadTask判断就可以了；如果是APP已经被kill又被系统自动relaunch，那获取到的downloadTask就跟原来不是同一个对象了，而且AFNetworking会在getTask方法中重新设置task的taskDescription，所以只能用url来判断
    func getDownloadModel(forDownloadTask downloadTask: URLSessionDownloadTask?) -> LXMDownloaderModelProtocol? {
        self.lock.lock()
        var resultModel: LXMDownloaderModelProtocol? = nil
        for model in self.allArray {
            if model.lxm_downloadItem.downloadTask == downloadTask {
                resultModel = model
                break
            }
            if let error = downloadTask?.error as NSError?,
                let urlString = error.userInfo[NSURLErrorFailingURLStringErrorKey] as? String {
                if model.lxm_downloadItem.urlString == urlString {
                    resultModel = model
                    break
                }
            }
            if let urlString = downloadTask?.currentRequest?.url?.absoluteString {
                if model.lxm_downloadItem.urlString == urlString {
                    resultModel = model
                    break
                }
            }
            if let urlString = downloadTask?.originalRequest?.url?.absoluteString {
                if model.lxm_downloadItem.urlString == urlString {
                    resultModel = model
                    break
                }
            }
        }
        self.lock.unlock()
        return resultModel
    }
    
    /// 创建缓存文件夹，并将其设置为备份忽略
    func createDownloadFolderIfNeeded() {
        let savePath = self.fullDownloadSavePathString(isCache: false)
        let cachePath = self.fullDownloadSavePathString(isCache: true)
        debugPrint("下载地址：\(savePath)")
        
        try? kOJSFileManager.createDirectory(atPath: cachePath, withIntermediateDirectories: false, attributes: nil)
        do {
            //一个try报错以后，后面的代码就不会执行了
            try kOJSFileManager.createDirectory(atPath: savePath, withIntermediateDirectories: false, attributes: nil)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var url = URL(fileURLWithPath: savePath)
            try url.setResourceValues(resourceValues)
        } catch {
            debugPrint(error, Date().description,  #file, #line, #function)
        }
    }
    
    func startDownloadNextIfNeeded(forItem item: LXMDownloaderItem) {
        for model in self.downloadingArray {
            if model.lxm_downloadItem.downloadStatus == .waiting && model.lxm_downloadItem.itemId != item.itemId {
                self.download(item: model, completion: nil)
                break
            }
        }
    }
    
    func saveResumeData(data: Data?, forItem item: LXMDownloaderItem) {
        guard let data = data else { return }
        let filePath = self.localPath(forItem: item, isResumeData: true)
        do {
            try data.write(to: filePath)
        } catch {
            print(error)
        }
    }

    func getSavedResumeData(forItem item: LXMDownloaderItem) -> Data? {
        let urlPath = self.localPath(forItem: item, isResumeData: true)
        return try? Data.init(contentsOf: urlPath)
    }

    func clearResumeData(forItem item: LXMDownloaderItem) {
        let filePath = self.localPath(forItem: item, isResumeData: true)
        try? kOJSFileManager.removeItem(at: filePath)
    }
    
    /// 这个方法只判断了当前正在进行的任务数是否大于最大并发数
    func canStartDownload() -> Bool {
        //使用 self.downloadSession.downloadTasks.count可能会造成死锁,所以用判断downloadStatus的方法，但这个方法就要注意，需要先修改原来item的状态再判断
        let downloadingArray = self.allArray.filter { (model) -> Bool in
            return model.lxm_downloadItem.downloadStatus == .downloading
        }
        if downloadingArray.count >= self.maxConcurrentTaskCount {
            return false
        } else {
            return true
        }
    }
}


// MARK: - PublicMethod 文件路径相关方法
public extension LXMDownloader {
    
    func fullDownloadSavePathString(isCache: Bool) -> String {
        if isCache {
            return kOJSUserCacheDirectory + "/" + self.downloadFolderName
        } else {
            return kOJSUserDocumentDirectory + "/" + self.downloadFolderName
        }
    }
    
    /// 注意返回的是URL路径，不是string
    func localPath(forItem item: LXMDownloaderItem, isResumeData: Bool) -> URL {
        var pathExtension = URL(string: item.urlString)?.pathExtension ?? ""
        if isResumeData {
            pathExtension = "resumeData"
        }
        let pathString = self.fullDownloadSavePathString(isCache: isResumeData) + "/" + item.itemId + ".\(pathExtension)"
        return URL(fileURLWithPath: pathString)
    }
    
    func hasLocalFile(forItem item: LXMDownloaderItem) -> Bool {
        let pathString = self.localPath(forItem: item, isResumeData: false).path
        return kOJSFileManager.fileExists(atPath: pathString)
    }
    
    /// 这个方法会删除实际下载的文件和记录中的下载不匹配的
    func checkDownloadFiles() {
        let savePath = self.fullDownloadSavePathString(isCache: false)
        do {
            let array = try kOJSFileManager.contentsOfDirectory(atPath: savePath)
            var savedSizeDict = [String : Int64]()
            for subPath in array {
                let filePath = savePath + "/\(subPath)"
                let dict = try kOJSFileManager.attributesOfItem(atPath: filePath)
                if let fileSize = dict[FileAttributeKey.size] as? Int64 {
                    savedSizeDict[filePath] = fileSize
                }
            }
            
            for (index, item) in self.allArray.enumerated().reversed() {
                
                let key = self.localPath(forItem: item.lxm_downloadItem, isResumeData: false).path
                if let savedSize = savedSizeDict[key] {
                    if savedSize != item.lxm_downloadItem.totalUnitCount {
                        self.allArray.remove(at: index)
                    } else {
                        savedSizeDict.removeValue(forKey: key)
                    }
                }
            }
            for key in savedSizeDict.keys {
                try kOJSFileManager.removeItem(atPath: savePath + "/\(key)")
            }
            self.shouldSaveDownloadModelBlock?()
        } catch {
            debugPrint(error)
        }
    }
    
    
    
}

// MARK: - PublicMethod
public extension LXMDownloader {
    
    func download(item: LXMDownloaderModelProtocol, completion: ((Bool) -> Void)?) {
        var isExist = false
        self.lock.lock()
        for model in self.allArray {
            if model.lxm_downloadItem.itemId == item.lxm_downloadItem.itemId {
                isExist = true
                break
            }
        }
        if isExist == false {
            self.allArray.append(item)
        }
        self.lock.unlock()
        
        if self.canStartDownload() == false {
            item.lxm_downloadItem.downloadStatus = .waiting
            completion?(false)
            self.shouldSaveDownloadModelBlock?()
            return
        }
        
        item.lxm_downloadItem.downloadStatus = .downloading

        let progressBlock: (Progress) -> Void = { progress in
            item.lxm_downloadItem.totalUnitCount = progress.totalUnitCount
            item.lxm_downloadItem.completedUnitCount = progress.completedUnitCount
            debugPrint("\(progress)")
        }

        if let resumeData = self.getSavedResumeData(forItem: item.lxm_downloadItem) {
            self.clearResumeData(forItem: item.lxm_downloadItem)
            item.lxm_downloadItem.downloadTask = downloadSession.correctedDownloadTask(withResumeData: resumeData, progress: progressBlock, destination: nil, completionHandler: nil)
        } else {
            if let url = URL(string: item.lxm_downloadItem.urlString) {
                let request = URLRequest(url: url)
                item.lxm_downloadItem.downloadTask = downloadSession.downloadTask(with: request, progress: progressBlock, destination: nil, completionHandler: nil)
            } else {
                completion?(false)
                return
            }
        }
        
        item.lxm_downloadItem.downloadTask?.resume()
        completion?(true)
        
        self.shouldSaveDownloadModelBlock?()
        
    }

    func pauseDownload(item: LXMDownloaderModelProtocol, completion:(()->Void)?) {
        item.lxm_downloadItem.downloadStatus = .paused
        self.shouldSaveDownloadModelBlock?()
        item.lxm_downloadItem.downloadTask?.cancel(byProducingResumeData: { [weak self] (data) in
            // 暂停时产生的resumeData并不是下载的内容，而是存储下载内容放在那里的一个config文件
            self?.startDownloadNextIfNeeded(forItem: item.lxm_downloadItem)
            completion?()
        })
        
    }

    func deleteDownload(item: LXMDownloaderModelProtocol) {
        item.lxm_downloadItem.downloadTask?.cancel()
        item.lxm_downloadItem.downloadStatus = .none
        self.lock.lock()
        for (index, model) in self.allArray.enumerated() {
            if model.lxm_downloadItem.itemId == item.lxm_downloadItem.itemId {
                self.allArray.remove(at: index)
                break
            }
        }
        self.lock.unlock()
        self.shouldSaveDownloadModelBlock?()
        self.startDownloadNextIfNeeded(forItem: item.lxm_downloadItem)
        self.deleteLocalFile(forItem: item)
    }

    /// 删除本地缓存的文件，包括resumeData
    /// TODO - 怎么删除真正的缓存的临时文件呢？
    func deleteLocalFile(forItem item: LXMDownloaderModelProtocol) {
        do {
            let filePath = self.localPath(forItem: item.lxm_downloadItem, isResumeData: false)
            try kOJSFileManager.removeItem(at: filePath)
            let cachePath = self.localPath(forItem: item.lxm_downloadItem, isResumeData: true)
            try? kOJSFileManager.removeItem(at: cachePath) //一个try报错以后，后面的代码就不会执行了， try?不会触发catch的Block，所以这里用try？
        } catch {
            debugPrint("删除失败：\(error)")
        }    
    }
}

// MARK: - PublicMethod
public extension LXMDownloader {
    
    /// AFNetworking支持后台下载需要的方法
    func setDidFinishEventsForBackgroundURLSessionBlock(block: ((URLSession) -> Void)?) {
        self.downloadSession.setDidFinishEventsForBackgroundURLSessionBlock(block)
    }
}


/*
 1，使用 self.downloadSession.downloadTasks.count可能会造成死锁
 
 2，如果本地保存的文件没有后缀，会报错，打不开：Error Domain=AVFoundationErrorDomain Code=-11828 "Cannot Open" UserInfo={NSLocalizedFailureReason=This media format is not supported., NSLocalizedDescription=Cannot Open, NSUnderlyingError=0x6000012a2730 {Error Domain=NSOSStatusErrorDomain Code=-12847 "(null)"}}
 
 */
