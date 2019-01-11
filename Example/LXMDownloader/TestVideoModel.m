//
//  TestVideoModel.m
//  LXMDownloader_Example
//
//  Created by luxiaoming on 2019/1/8.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

#import "TestVideoModel.h"

@implementation TestVideoModel

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.videoId forKey:@"videoId"];
    [aCoder encodeObject:self.videoUrl_low forKey:@"videoUrl_low"];
    [aCoder encodeObject:self.videoUrl_normal forKey:@"videoUrl_normal"];
    [aCoder encodeObject:self.videoUrl_high forKey:@"videoUrl_high"];
    [aCoder encodeObject:self.lxm_downloadItem forKey:@"lxm_downloadItem"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.videoId = [aDecoder decodeIntegerForKey:@"videoId"];
        self.videoUrl_low = [aDecoder decodeObjectForKey:@"videoUrl_low"];
        self.videoUrl_normal = [aDecoder decodeObjectForKey:@"videoUrl_normal"];
        self.videoUrl_high = [aDecoder decodeObjectForKey:@"videoUrl_high"];
        self.lxm_downloadItem = [aDecoder decodeObjectForKey:@"lxm_downloadItem"];
    }
    return self;
}

@end
