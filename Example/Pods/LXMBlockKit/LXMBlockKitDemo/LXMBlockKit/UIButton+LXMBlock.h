//
//  UIButton+LXMBlock.h
//  LXMBlockKitDemo
//
//  Created by luxiaoming on 16/6/21.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef void(^LXMButtonCallback)(UIButton * _Nullable sender);

@interface UIButton (LXMBlock)

@property (nonatomic, copy, readonly, nullable) LXMButtonCallback buttonCallback;

- (void)addButtonCallback:(nonnull LXMButtonCallback)callback;

- (void)addButtonCallback:(nonnull LXMButtonCallback)callback forControlEvents:(UIControlEvents)controlEvents;

@end
