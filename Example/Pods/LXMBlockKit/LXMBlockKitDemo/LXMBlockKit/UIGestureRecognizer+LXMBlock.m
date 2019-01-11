//
//  UIGestureRecognizer+LXMBlock.m
//  LXMBlockKitDemo
//
//  Created by kook on 16/7/2.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//

#import "UIGestureRecognizer+LXMBlock.h"
#import <objc/runtime.h>

@interface UIGestureRecognizer ()

@property (nonatomic, copy, readwrite) LXMGestureCallback gestureCallback;

@end

@implementation UIGestureRecognizer (LXMBlock)

- (instancetype)initWithCallback:(LXMGestureCallback)callback {
    self = [self initWithTarget:self action:@selector(handleGesture:)];
    if (self) {
        self.gestureCallback = callback;
    }
    return self;
}

#pragma mark - Action

- (void)handleGesture:(UIGestureRecognizer *)sender {
    if (self.gestureCallback) {
        self.gestureCallback(sender);
    }
}

#pragma mark - Property

- (LXMGestureCallback)gestureCallback {
    return objc_getAssociatedObject(self, @selector(gestureCallback));
}

- (void)setGestureCallback:(LXMGestureCallback)gestureCallback {
    objc_setAssociatedObject(self, @selector(gestureCallback), gestureCallback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


@end



@implementation UIView (LXMTapGesture)

- (UITapGestureRecognizer *)addTapGestureWithCallback:(LXMTapGestureCallback)callback {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithCallback:callback];
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tapGesture];
    return tapGesture;
}


@end

