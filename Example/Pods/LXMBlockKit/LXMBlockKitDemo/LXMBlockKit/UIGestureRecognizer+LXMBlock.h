//
//  UIGestureRecognizer+LXMBlock.h
//  LXMBlockKitDemo
//
//  Created by kook on 16/7/2.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^LXMGestureCallback)(id _Nullable sender);

@interface UIGestureRecognizer (LXMBlock)

@property (nonatomic, copy, readonly, nullable) LXMGestureCallback gestureCallback;

- (nonnull instancetype)initWithCallback:(nonnull LXMGestureCallback)callback;

@end




typedef void(^LXMTapGestureCallback)(UITapGestureRecognizer * _Nullable sender);

@interface UIView (LXMTapGesture)

- (nonnull UITapGestureRecognizer *)addTapGestureWithCallback:(nonnull LXMTapGestureCallback)callback;

@end
