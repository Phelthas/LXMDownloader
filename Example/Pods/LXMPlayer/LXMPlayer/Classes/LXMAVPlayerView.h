//
//  LXMAVPlayerView.h
//  LXMPlayer
//
//  Created by luxiaoming on 2018/8/28.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, LXMAVPlayerContentMode) {
    LXMAVPlayerContentModeScaleAspectFit = 0,    //AVLayerVideoGravityResizeAspect;
    LXMAVPlayerContentModeScaleAspectFill = 1,   //AVLayerVideoGravityResizeAspectFill;
    LXMAVPlayerContentModeScaleToFill = 2,       //AVLayerVideoGravityResize;
};


typedef NS_ENUM(NSInteger, LXMAVPlayerStatus) {
    LXMAVPlayerStatusUnknown = 0,
    LXMAVPlayerStatusReadyToPlay,
    LXMAVPlayerStatusStalling,
    LXMAVPlayerStatusPlaying,
    LXMAVPlayerStatusPaused,
    LXMAVPlayerStatusStopped,
    LXMAVPlayerStatusFailed,
    
};


typedef void(^LXMAVPlayerTimeDidChangeBlock)(NSTimeInterval currentTime, NSTimeInterval totalTime);
typedef void(^LXMAVPlayerDidPlayToEndBlock)(AVPlayerItem *item);
typedef void(^LXMAVPlayerStatusDidChangeBlock)(LXMAVPlayerStatus status);

@interface  LXMAVPlayerView : UIView

@property (nonatomic, strong, nullable) NSURL *assetURL;
@property (nonatomic, copy) AVLayerVideoGravity videoGravity;

//readonly的属性，方便外部调用
@property (nonatomic, strong, readonly, nullable) AVPlayerItem *playerItem;
@property (nonatomic, assign, readonly) LXMAVPlayerStatus playerStatus;
@property (nonatomic, assign, readonly) NSTimeInterval currentSeconds;//当前播放到的时间，以秒为单位，如果取不到会返回0
@property (nonatomic, assign, readonly) NSTimeInterval totalSeconds;//当前PlayerItem的总时长，以秒为单位，如果取不到会返回0
@property (nonatomic, assign, readonly) BOOL isReadyToPlay; //playerItem的状态是否已经到了readyToPlay，没到之前执行seek操作会crash,内部已经做了判断，如果是false时，不会响应seek操作

//callback
@property (nonatomic, copy, nullable) LXMAVPlayerTimeDidChangeBlock playerTimeDidChangeBlock;
@property (nonatomic, copy, nullable) LXMAVPlayerDidPlayToEndBlock playerDidPlayToEndBlock;
@property (nonatomic, copy, nullable) LXMAVPlayerStatusDidChangeBlock playerStatusDidChangeBlock;


#pragma mark - PublicMethod

- (void)play;

- (void)pause;

- (void)stop;

- (void)reset;

- (void)replay;

- (void)seekToTimeAndPlay:(CMTime)time;

- (void)seekToTime:(CMTime)time completion:(void(^)(BOOL finished))completion;

- (nullable UIImage *)thumbnailAtCurrentTime;


@end



/* 遇到的问题
 1，AVPlayerItem cannot service a seek request with a completion handler until its status is AVPlayerItemStatusReadyToPlay.
 所以在seek之前需要判断一下，如果还没有readyToPlay就直接return。
 2，Seeking is not possible to time {INDEFINITE}。
 
 */
