//
//  LXMAVPlayerView.m
//  LXMPlayer
//
//  Created by luxiaoming on 2018/8/28.
//

#import "LXMAVPlayerView.h"
#import <KVOController/KVOController.h>
#import <LXMPlayer/LXMPlayerMacro.h>
#import <LXMBlockKit/LXMBlockKit.h>
#import "LXMPlayerMacro.h"
#import <AFNetworking/AFNetworking.h>


//static void * kLXMAVPlayerViewContext = &kLXMAVPlayerViewContext;
static NSString * const kAVPlayerItemStatus = @"status";
static NSString * const kAVPlayerItemPlaybackBufferEmpty = @"playbackBufferEmpty";
static NSString * const kAVPlayerItemPlaybackLikelyToKeepUp = @"playbackLikelyToKeepUp";

@interface  LXMAVPlayerView ()

//private

@property (nonatomic, strong) AVURLAsset *urlAsset;
@property (nonatomic, strong, readwrite) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, assign) BOOL isPlayerInited;


@property (nonatomic, assign, readwrite) LXMAVPlayerStatus playerStatus;


@property (nonatomic, assign) LXMAVPlayerStatus statusBeforeBackground;

@end


@implementation  LXMAVPlayerView


/**
 这里这么写是为了让这个view本身的layer成为AVPlayerLayer，这样的话系统会自动根据view的大小来调整layer
 */
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    }
    return self;
}



#pragma mark -


- (void)initializePlayer {
    self.urlAsset = [AVURLAsset assetWithURL:self.assetURL];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.urlAsset];
    self.avPlayer = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    self.playerLayer.player = self.avPlayer;
    self.playerLayer.videoGravity = self.videoGravity;
    if (@available(iOS 9.0, *)) {
        self.playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = NO;
    }
    if (@available(iOS 10.0, *)) {
        self.avPlayer.automaticallyWaitsToMinimizeStalling = NO;
    }
    [self addItemObserver];
}

- (void)addItemObserver {
    /*
     1)打断点观察，当调用play方法的时候，首先会观察到kAVPlayerRate的变化，从0变到1;但这时候并没有画面，因为还没有任何数据；
     2)然后开始loading，稍后就会观察到kAVPlayerItemPlaybackBufferEmpty的变化，从1变为0，说有缓存到内容了，已经有loadedTimeRanges了，但这时候还不一定能播放，因为数据可能还不够播放；
     3)然后是kAVPlayerItemPlaybackLikelyToKeepUp的变化，新旧值都是0，这时候还没什么用，因为本来就还没开始播放；
     4)然后是kAVPlayerItemStatus的变化，从0变为1，即变为readyToPlay
     5)然后是kAVPlayerItemPlaybackLikelyToKeepUp，从0变到1，说明可以播放了，这时候会自动开始播放
     */
    
    /*
     所以player的rate是没有必要观察的，rate就是在player调用play的时候变为1，调用pause的时候变为0，它的值不根据卡不卡变化，
     它应该是用来决定当load到新数据是要不要继续播放。
     文档上还提到一种情况，playbackBufferFull是true但是isPlaybackLikelyToKeepUp还是false，即缓存已经满了，但是缓存的这些内容还不够用来播放，这种情况要自己处理。。。这种情况应该不多，我这儿没有处理。。。
     */
    
    /*
     测试的时候发现，有时候从APP从后台返回前台，会观察到playerItem的status变化，但新旧值都是readToPlay，这个需要注意，如果有监听状态变化的逻辑，要判断这时候能不能执行操作
     */
    
    @weakify(self)
    
    [self.KVOController observe:self.playerItem keyPath:kAVPlayerItemStatus options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld block:^(id  _Nullable observer, AVPlayerItem * _Nullable object, NSDictionary<NSString *,id> * _Nonnull change) {
//        NSLog(@"change: %@", change);
        @strongify(self)
        if (self.playerStatus == LXMAVPlayerStatusPaused) {
            // 这里这么写是因为：状态变化是异步的，有可能在播放器暂停时观察到状态变化，这时候不应该变动原来的状态
            return;
        }
        AVPlayerItemStatus status = object.status;
        switch (status) {
            case AVPlayerItemStatusUnknown:
                if (self.playerStatus != LXMAVPlayerStatusUnknown) {
                    self.playerStatus = LXMAVPlayerStatusUnknown;
                    [self delegateStatusDidChangeBlock];
                }
                break;
            case AVPlayerItemStatusReadyToPlay:
                // 这里这么写是因为：从后台返回前台时，kvo居然会观察到playerItem的状态变为readToPlay,而我只想在playerItem第一次点击播放状态变为readToPlay的时候通知外部
                if (self.playerStatus == LXMAVPlayerStatusUnknown) {
                    self.playerStatus = LXMAVPlayerStatusReadyToPlay;
                    [self delegateStatusDidChangeBlock];
                }
                break;
            case AVPlayerItemStatusFailed:
                if (self.playerStatus != LXMAVPlayerStatusFailed) {
                    self.playerStatus = LXMAVPlayerStatusFailed;
                    [self delegateStatusDidChangeBlock];
                }
                break;
            default:
                break;
        }
    }];
    
    [self.KVOController observe:self.playerItem keyPath:kAVPlayerItemPlaybackBufferEmpty options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
//        NSLog(@"change: %@", change);
        @strongify(self)
        if (self.playerStatus == LXMAVPlayerStatusPaused) {
            // 这里这么写是因为：状态变化是异步的，有可能在播放器暂停时观察到状态变化，这时候不应该变动原来的状态
            return;
        }
        BOOL oldValue = [change[NSKeyValueChangeOldKey] boolValue];
        BOOL newValue = [change[NSKeyValueChangeNewKey] boolValue];
        if (oldValue == NO && newValue == YES) {
            //这里这么写是因为观察到会有old new都是0的情况
            self.playerStatus = LXMAVPlayerStatusStalling;
            [self delegateStatusDidChangeBlock];
        }
    }];
    
    [self.KVOController observe:self.playerItem keyPath:kAVPlayerItemPlaybackLikelyToKeepUp options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
//        NSLog(@"change: %@", change);
        @strongify(self)
        if (self.playerStatus == LXMAVPlayerStatusPaused) {
            // 这里这么写是因为：状态变化是异步的，有可能在播放器暂停时观察到状态变化，这时候不应该变动原来的状态
            return;
        }
        BOOL oldValue = [change[NSKeyValueChangeOldKey] boolValue];
        BOOL newValue = [change[NSKeyValueChangeNewKey] boolValue];
        if (oldValue == NO && newValue == YES) { //这里这么写是因为观察到会有old new都是0的情况
            self.playerStatus = LXMAVPlayerStatusPlaying;
            [self delegateStatusDidChangeBlock];
        }
        
    }];
    
    
    
    
    if (self.playerTimeDidChangeBlock) {
        CMTime interval = CMTimeMakeWithSeconds(1, 10);
        self.timeObserver = [self.avPlayer addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            @strongify(self)
            if (self.totalSeconds == 0) {
                return;
            }
            self.playerTimeDidChangeBlock(self.currentSeconds, self.totalSeconds);
        }];
    }
    
    [self removeNotificatiions];
    
    [kNSNotificationCenter addObserver:self name:AVPlayerItemDidPlayToEndTimeNotification callback:^(NSNotification * _Nullable sender) {
        @strongify(self)
        if (sender.object == self.avPlayer.currentItem) {
            if (self.playerDidPlayToEndBlock) {
                self.playerDidPlayToEndBlock(sender.object);
            }
            self.playerStatus = LXMAVPlayerStatusStopped;
            [self delegateStatusDidChangeBlock];
        }
    }];
    
    [kNSNotificationCenter addObserver:self name:UIApplicationWillResignActiveNotification callback:^(NSNotification * _Nullable sender) {
        @strongify(self)
        // 加这个判断是因为貌似，这个通知在拉下通知栏的时候会触发两次
        if (self.statusBeforeBackground == LXMAVPlayerStatusUnknown) {
            self.statusBeforeBackground = self.playerStatus;
            [self pause];
        }
        
    }];
    
    [kNSNotificationCenter addObserver:self name:UIApplicationDidBecomeActiveNotification callback:^(NSNotification * _Nullable sender) {
        @strongify(self)
        if (self.statusBeforeBackground == LXMAVPlayerStatusUnknown) {
            return;
        }
        if (self.statusBeforeBackground == LXMAVPlayerStatusPlaying ||
            self.statusBeforeBackground == LXMAVPlayerStatusStalling ||
            self.statusBeforeBackground == LXMAVPlayerStatusReadyToPlay) {
            [self play];
        }
        self.statusBeforeBackground = LXMAVPlayerStatusUnknown;
    }];
    
    [kNSNotificationCenter addObserver:self name:AFNetworkingReachabilityDidChangeNotification callback:^(NSNotification * _Nullable sender) {
        @strongify(self)
        if ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus != AFNetworkReachabilityStatusReachableViaWiFi) {
            self.statusBeforeBackground = LXMAVPlayerStatusPaused;
        }
        
    }];
}

- (void)removeNotificatiions {
    [kNSNotificationCenter lxm_removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [kNSNotificationCenter lxm_removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [kNSNotificationCenter lxm_removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [kNSNotificationCenter lxm_removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
}

- (void)delegateStatusDidChangeBlock {
    if (self.playerStatusDidChangeBlock) {
        self.playerStatusDidChangeBlock(self.playerStatus);
    }
}




#pragma mark - PublicMethod

- (void)play {
    if (!self.assetURL) {
        return;
    }
    if (self.playerStatus == LXMAVPlayerStatusPlaying) {
        return;
    }
    if (self.isPlayerInited == NO) {
        [self initializePlayer];
        self.isPlayerInited = YES;
    }
    [self.avPlayer play];
    if (self.playerStatus == LXMAVPlayerStatusPaused) {
        self.playerStatus = LXMAVPlayerStatusPlaying;
        [self delegateStatusDidChangeBlock];
    }
    
}

- (void)pause {
    [self.avPlayer pause];
    if (self.playerStatus != LXMAVPlayerStatusPaused) {
        self.playerStatus = LXMAVPlayerStatusPaused;
        [self delegateStatusDidChangeBlock];
    }
    
}

- (void)stop {
    [self.avPlayer seekToTime:kCMTimeZero];
    [self.avPlayer pause];
    [self.avPlayer cancelPendingPrerolls];
    if (self.playerStatus != LXMAVPlayerStatusStopped) {
        self.playerStatus = LXMAVPlayerStatusStopped;
        [self delegateStatusDidChangeBlock];
    }
}



- (void)reset {
    [self.avPlayer pause];
    [self.avPlayer cancelPendingPrerolls];
    [self.KVOController unobserveAll];
    if (self.timeObserver) {
        [self.avPlayer removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    [self removeNotificatiions];
    
    self.playerLayer.player = nil; //千万注意这一句，坑了我好久，AVPlayerLayer会retain它的player，如果这里不主动设置为nil，player就不会释放。
    self.assetURL = nil;
    self.urlAsset = nil;
    self.playerItem = nil;
    self.avPlayer = nil;
    self.isPlayerInited = NO;
    if (self.playerStatus != LXMAVPlayerStatusUnknown) {
        self.playerStatus = LXMAVPlayerStatusUnknown;
        [self delegateStatusDidChangeBlock];
    }
    
}

- (void)replay {
    [self seekToTimeAndPlay:kCMTimeZero];
}

- (void)seekToTimeAndPlay:(CMTime)time {
    [self seekToTime:time completion:nil];
}

- (void)seekToTime:(CMTime)time completion:(void (^)(BOOL finished))completion {
    if (self.isReadyToPlay == NO) { return; }
    if (self.playerItem == nil) {
        return;
    }
    //友盟统计到一个Seeking is not possible to time {INDEFINITE}的bug，这么修复一下
    if (CMTIME_IS_INDEFINITE(time) || CMTIME_IS_INVALID(time)) {
        return;
    }
    [self.avPlayer pause];//seek之前还是应该暂停住，且不应该让外界感知到；因为如果在刚readToPlay就seek的话，如果不暂停，会让视频第一帧先放出来，造成界面闪一下。（因为seek的回调是异步的，应该在seek完成的回调中再开始播放）
    CMTime tolerance = kCMTimeZero;
    @weakify(self)
    [self.avPlayer seekToTime:time toleranceBefore:tolerance toleranceAfter:tolerance completionHandler:^(BOOL finished) {
        @strongify(self)
        [self.avPlayer play];
        if (completion) {
            completion(finished);
        }
        // 这是是发现当stop以后，seek到前面开始播放player状态不会恢复，所以这么处理下
        // 发现readToPlay的时候直接seek，可能会导致状态一直停留在readToPlay不会变
        if (self.playerStatus == LXMAVPlayerStatusStopped || self.playerStatus == LXMAVPlayerStatusReadyToPlay) {
            self.playerStatus = LXMAVPlayerStatusPlaying;
            [self delegateStatusDidChangeBlock];
        }
    }];
    
}


- (nullable UIImage *)thumbnailAtCurrentTime {
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.urlAsset];
    CMTime expectedTime = self.playerItem.currentTime;
    CGImageRef cgImage = NULL;
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    cgImage = [imageGenerator copyCGImageAtTime:expectedTime actualTime:NULL error:NULL];
    if (!cgImage) {
        imageGenerator.requestedTimeToleranceBefore = kCMTimePositiveInfinity;
        imageGenerator.requestedTimeToleranceAfter = kCMTimePositiveInfinity;
        cgImage = [imageGenerator copyCGImageAtTime:expectedTime actualTime:NULL error:NULL];
    }
    return [UIImage imageWithCGImage:cgImage];
}


#pragma mark - Property


/**
 注意：设置新的url会重置playerView
 */
- (void)setAssetURL:(NSURL *)assetURL {
    if (assetURL == _assetURL) {
        return;
    }
    if (assetURL != nil) {
        [self reset];
    }
    _assetURL = assetURL;
}

- (NSTimeInterval)currentSeconds {
    if (self.playerItem != nil && self.isReadyToPlay) {
        NSTimeInterval time = CMTimeGetSeconds(self.playerItem.currentTime);
        if (isnan(time)) {
            return 0;
        }
        return time;
    }
    return 0;
}

- (NSTimeInterval)totalSeconds {
    if (self.playerItem != nil && self.isReadyToPlay) {
        NSTimeInterval time = CMTimeGetSeconds(self.playerItem.duration);
        if (isnan(time)) {
            return 0;
        }
        return time;
    }
    return 0;
}

- (BOOL)isReadyToPlay {
    return self.playerStatus >= LXMAVPlayerStatusReadyToPlay && self.playerStatus != LXMAVPlayerStatusFailed;
}

@end
