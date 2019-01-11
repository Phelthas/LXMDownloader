//
//  LXMDownloaderItemProtocol.swift
//  LXMDownloader
//
//  Created by luxiaoming on 2019/1/3.
//

import Foundation


public enum LXMDownloaderStatus: Int {
    case none = 0
    case downloading
    case paused
    case waiting
    case finished
    case failed
}

@objcMembers
open class LXMDownloaderItem: NSObject, NSCoding {
    //注意：swift的类必须继承NSObject并且明确声明为dynamic才可以使用KVO
    open dynamic var downloadStatus: LXMDownloaderStatus = .none
    open dynamic var totalUnitCount: Int64 = 0
    open dynamic var completedUnitCount: Int64 = 0
    open weak var downloadTask: URLSessionDownloadTask? //这里要用weak，让task完成后能正确的结束
    
    open dynamic var progress: Float {
        if totalUnitCount == 0 {
            return 0
        } else {
            return Float(completedUnitCount) / Float(totalUnitCount)
        }
    }
    
    open var itemId: String //itemId是唯一标示符，内部使用itemId是否相等来判断是否是同一个对象的
    open var urlString: String
    public init(itemId: String, urlString: String) {
        self.itemId = itemId
        self.urlString = urlString
        super.init()
    }
    
    
    /// 注意，encode过程中downloadTask会被忽略，因为URLSessionDownloadTask不能序列化,progress是只读属性，不用序列化
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(downloadStatus.rawValue, forKey: "downloadStatus")
        aCoder.encode(totalUnitCount, forKey: "totalUnitCount")
        aCoder.encode(completedUnitCount, forKey: "completedUnitCount")
        aCoder.encode(urlString, forKey: "urlString")
        aCoder.encode(itemId, forKey: "itemId")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        downloadStatus = LXMDownloaderStatus(rawValue: aDecoder.decodeInteger(forKey: "downloadStatus")) ?? .none
        totalUnitCount = aDecoder.decodeInt64(forKey: "totalUnitCount")
        completedUnitCount = aDecoder.decodeInt64(forKey: "completedUnitCount")
        urlString = aDecoder.decodeObject(forKey: "urlString") as? String ?? ""
        itemId = aDecoder.decodeObject(forKey: "itemId") as? String ?? ""
    }
    
}

@objc public protocol LXMDownloaderModelProtocol {
    @objc var lxm_downloadItem: LXMDownloaderItem { set get }
}

