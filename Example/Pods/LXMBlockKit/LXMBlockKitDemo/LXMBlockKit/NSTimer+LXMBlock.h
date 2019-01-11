//
//  NSTimer+LXMBlock.h
//  LXMBlockKitDemo
//
//  Created by luxiaoming on 2017/6/9.
//  Copyright © 2017年 luxiaoming. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef void(^LXMTimerCallback)(NSTimer * _Nullable sender);


/**
 注意，NSTimer被添加到runloop时，runloop会持有timer的target，所以即使timer被释放掉了，只要timer没有调用invalidate()方法，target就不会释放;
 所以用这个block的API，也一定要手动调用invalidate()方法，不过方便的是，可以将invalidate()写到viewController的dealloc里面了
 */
@interface NSTimer (LXMBlock)


@property (nonatomic, copy, readonly, nullable) LXMTimerCallback timerCallback;



+ (nonnull NSTimer *)lxm_timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(nonnull LXMTimerCallback)block;


+ (nonnull NSTimer *)lxm_scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(nonnull LXMTimerCallback)block;


@end
