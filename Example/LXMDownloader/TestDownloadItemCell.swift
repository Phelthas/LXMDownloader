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
        didSet {
            self.titleLabel.text = "\(videoModel.videoId)"
            self.statusLabel.text = "status \(videoModel.lxm_downloadItem?.downloadStatus ?? .none)"
            self.updateProgress()
            
            if videoModel.lxm_downloadItem != nil {
                self.observation = self.videoModel.observe(\.lxm_downloadItem?.completedUnitCount) { [weak self] (model, change) in
                    DispatchQueue.main.async {
                        self?.updateProgress()
                        
//                        print("\(change)")
                    }
                    
                }
            }
        }
    }
    
    func updateProgress() {
        if let progress = self.videoModel.lxm_downloadItem?.progress {
            self.sizeLabel.text = "\(Int(progress * 100))%"
            self.progressView.progress = progress
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
