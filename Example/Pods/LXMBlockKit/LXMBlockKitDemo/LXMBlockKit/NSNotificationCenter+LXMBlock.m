//
//  NSNotificationCenter+LXMBlock.m
//  LXMBlockKitDemo
//
//  Created by luxiaoming on 16/8/1.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//

#import "NSNotificationCenter+LXMBlock.h"
#import <objc/runtime.h>

static NSString * const kLXMNotificationObserverArrayKey = @"kLXMNotificationObserverArrayKey";

static NSMutableArray *LXMNotificationObserverArray(id object) {
    @synchronized(object) {
        NSMutableArray *observerArray = objc_getAssociatedObject(object, &kLXMNotificationObserverArrayKey);
        if (!observerArray) {
            observerArray = [NSMutableArray array];
            objc_setAssociatedObject(object, &kLXMNotificationObserverArrayKey, observerArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return observerArray;
    }
}




@interface LXMNotificationObserver : NSObject

@property (nonatomic, weak) NSObject *notificationObserver;
@property (nonatomic, copy) NSString *notificationName;
@property (nonatomic, weak) NSObject *notificationObject;
@property (nonatomic, strong) NSOperationQueue *notificationQueue;
@property (nonatomic, copy) LXMNotificationCallback notificationCallback;

@end


@implementation LXMNotificationObserver

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)handleNotification:(NSNotification *)sender {
    __strong id strongObserver = self.notificationObserver;
    if (self.notificationCallback && strongObserver) {
        if (!self.notificationQueue || [NSOperationQueue currentQueue] == self.notificationQueue) {
            self.notificationCallback(sender);
        } else {
            [self.notificationQueue addOperationWithBlock:^{
                self.notificationCallback(sender);
            }];
        }
    }
}


@end










@implementation NSNotificationCenter (LXMBlock)

- (void)addObserver:(id)observer name:(NSString *)name callback:(LXMNotificationCallback)callback {
    [self addObserver:observer name:name object:nil callback:callback];
}

- (void)addObserver:(id)observer name:(NSString *)name object:(id)object callback:(LXMNotificationCallback)callback {
    [self addObserver:observer name:name object:object queue:nil callback:callback];
}

- (void)addObserver:(id)observer name:(NSString *)name object:(id)object queue:(NSOperationQueue *)queue callback:(LXMNotificationCallback)callback {
    
    LXMNotificationObserver *target = [[LXMNotificationObserver alloc] init];
    target.notificationObserver = observer;
    target.notificationName = name;
    target.notificationObject = object;
    target.notificationQueue = queue;
    target.notificationCallback = callback;
    
    [LXMNotificationObserverArray(observer) addObject:target];
    [self addObserver:target selector:@selector(handleNotification:) name:name object:object];
}


- (void)lxm_removeObserver:(id)observer name:(NSString *)name object:(id)object {
    for (LXMNotificationObserver *target in [LXMNotificationObserverArray(observer) reverseObjectEnumerator]) {
        if ((!name || [target.notificationName isEqualToString:name]) &&
            (!object || target.notificationObject == object)) {
            [LXMNotificationObserverArray(observer) removeObject:target];
        }
    }
}

@end
