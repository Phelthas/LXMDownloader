//
//  TestPlayerViewController.swift
//  LXMDownloader_Example
//
//  Created by luxiaoming on 2019/1/10.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import LXMPlayer


class TestPlayerViewController: UIViewController {
    
    var playerView: LXMAVPlayerView = LXMAVPlayerView(frame: CGRect.zero)
    
    lazy var backButton: UIButton = {
        let backButton = UIButton()
        backButton.setTitle("back", for: .normal)
        backButton.addCallback({ [weak self] (sender) in
            self?.playerView.stop()
            self?.dismiss(animated: true, completion: nil)
        })
        return backButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.view.addSubview(playerView)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        
        
        self.view.addConstraint(NSLayoutConstraint(item: playerView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: playerView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: playerView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: playerView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0))
        
        
        backButton.frame = CGRect(x: 20, y: 0, width: 44, height: 44)
        self.view.addSubview(backButton)
    }

}

// MARK: - PublicMethod
extension TestPlayerViewController {
    
    class func play(localModel: TestVideoModel, inNav nav: UINavigationController?) {
        let playerViewController = TestPlayerViewController()
        nav?.present(playerViewController, animated: true, completion: {
            playerViewController.playerView.assetURL = LXMVideoDownloadManager.localPath(forModel: localModel)
            playerViewController.playerView.play()
        })
    }
    
}

// MARK: - 竖屏、横屏设置
extension TestPlayerViewController {
    override var shouldAutorotate : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask{
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return .landscapeRight
    }
    
}
