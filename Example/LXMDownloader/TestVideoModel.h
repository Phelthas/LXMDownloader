//
//  TestVideoModel.h
//  LXMDownloader_Example
//
//  Created by luxiaoming on 2019/1/8.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LXMDownloader/LXMDownloader-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestVideoModel : NSObject<LXMDownloaderModelProtocol, NSCoding>

@property (nonatomic, assign) NSInteger videoId;
@property (nonatomic, copy) NSString *videoUrl_low;
@property (nonatomic, copy) NSString *videoUrl_normal;
@property (nonatomic, copy) NSString *videoUrl_high;


@property (nonatomic, strong, nullable) LXMDownloaderItem *lxm_downloadItem;


@end

NS_ASSUME_NONNULL_END
