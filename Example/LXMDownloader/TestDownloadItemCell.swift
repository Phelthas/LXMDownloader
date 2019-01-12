//
//  TestDownloadItemCell.swift
//  LXMDownloader_Example
//
//  Created by luxiaoming on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class TestDownloadItemCell: UITableViewCell {

    static let kStaticHeight: CGFloat = 80
    
    static let kStaticIdentifier = "TestDownloadItemCell"
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.font = UIFont.systemFont(ofSize: 14)
        }
    }
    
    @IBOutlet weak var sizeLabel: UILabel! {
        didSet {
            sizeLabel.font = UIFont.systemFont(ofSize: 12)
        }
    }
    
    
    @IBOutlet weak var progressView: UIProgressView! {
        didSet {
            progressView.trackTintColor = UIColor.gray
            progressView.progressTintColor = UIColor.orange
            progressView.progress = 0
        }
    }
    
    
    @IBOutlet weak var statusLabel: UILabel! {
        didSet {
            statusLabel.font = UIFont.systemFont(ofSize: 12)
        }
    }
    
    var observation: NSKeyValueObservation?
    
    var videoModel = TestVideoModel() {
        willSet {
            self.observation = nil //注意这里的写法，必须在setVideoModel之前把observation移除掉，随时系统会自己移除observer，但如果移除的不及时，就可能会出现对象还在KVO中就释放的bug。自己移除比较保险
        }
        didSet {
            self.titleLabel.text = "\(videoModel.videoId)"
            self.statusLabel.text = "status \(videoModel.lxm_downloadItem?.downloadStatus ?? .none)"
            self.updateProgress()
            
            if videoModel.lxm_downloadItem != nil {
                self.observation = videoModel.observe(\.lxm_downloadItem?.completedUnitCount, options: [.new], changeHandler: { [weak self] (model, change) in
                    DispatchQueue.main.async {
                        self?.updateProgress()
                    }
                })
            }
        }
    }
    
    func updateProgress() {
        if let progress = self.videoModel.lxm_downloadItem?.progress {
            self.sizeLabel.text = "\(Int(progress * 100))%"
            self.progressView.progress = progress
        } else {
            self.progressView.progress = 0
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
