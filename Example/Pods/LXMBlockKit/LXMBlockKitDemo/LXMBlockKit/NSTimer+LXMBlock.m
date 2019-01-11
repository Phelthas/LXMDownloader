//
//  NSTimer+LXMBlock.m
//  LXMBlockKitDemo
//
//  Created by luxiaoming on 2017/6/9.
//  Copyright © 2017年 luxiaoming. All rights reserved.
//

#import "NSTimer+LXMBlock.h"
#import <objc/runtime.h>



/**
 这里是自定义了一个target类；
 网上还看到一种将NSTimer这个类作为target，给NSTimer加个类方法来作为selector，用userInfo传递block的方式，貌似也可以
 */
@interface LXMTimerTarget : NSObject

@property (nonatomic, copy, readwrite, nullable) LXMTimerCallback timerCallback;

@end


@implementation LXMTimerTarget

- (void)dealloc {
    //注意，NSTimer被添加到runloop时，runloop会持有timer的target，所以即使timer被释放掉了，只要timer没有调用invalidate()方法，target就不会释放
    NSLog(@"LXMTimerTarget dealloc");
}

- (void)handleLXMTimerCallback:(NSTimer *)sender {
    if (self.timerCallback) {
        self.timerCallback(sender);
    }
}

@end

















@interface NSTimer ()

@property (nonatomic, copy, readwrite, nullable) LXMTimerCallback timerCallback;

@end


@implementation NSTimer (LXMBlock)

- (LXMTimerCallback)timerCallback {
    return self.timerTarget.timerCallback;
}


+ (nonnull NSTimer *)lxm_timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(nonnull LXMTimerCallback)block {
    LXMTimerTarget *target = [[LXMTimerTarget alloc] init];
    target.timerCallback = block;
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval target:target selector:@selector(handleLXMTimerCallback:) userInfo:nil repeats:repeats];
    timer.timerTarget = target;
    return timer;
}


+ (nonnull NSTimer *)lxm_scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(nonnull LXMTimerCallback)block {
    LXMTimerTarget *target = [[LXMTimerTarget alloc] init];
    target.timerCallback = block;
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:interval target:target selector:@selector(handleLXMTimerCallback:) userInfo:nil repeats:repeats];
    timer.timerTarget = target;
    return timer;
    
    
}


#pragma mark - Property

- (LXMTimerTarget *)timerTarget {
    return objc_getAssociatedObject(self, @selector(timerTarget));
}

- (void)setTimerTarget:(LXMTimerTarget *)timerTarget {
    objc_setAssociatedObject(self, @selector(timerTarget), timerTarget, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
