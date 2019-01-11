//
//  UIBarButtonItem+LXMBlock.h
//  LXMBlockKitDemo
//
//  Created by luxiaoming on 16/6/21.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^LXMBarButtonItemCallback)(UIBarButtonItem * _Nullable sender);

@interface UIBarButtonItem (LXMBlock)

@property (nonatomic, copy, readonly, nullable) LXMBarButtonItemCallback itemCallback;

+ (nonnull instancetype)itemWithImage:(nullable UIImage *)image callback:(nonnull LXMBarButtonItemCallback)callback;

+ (nonnull instancetype)itemWithImage:(nullable UIImage *)image landscapeImagePhone:(nullable UIImage *)landscapeImagePhone callback:(nonnull LXMBarButtonItemCallback)callback;

+ (nonnull instancetype)itemWithTitle:(nullable NSString *)title callback:(nonnull LXMBarButtonItemCallback)callback;


+ (nonnull instancetype)itemWithImage:(nullable UIImage *)image style:(UIBarButtonItemStyle)style callback:(nonnull LXMBarButtonItemCallback)callback;

+ (nonnull instancetype)itemWithImage:(nullable UIImage *)image landscapeImagePhone:(nullable UIImage *)landscapeImagePhone style:(UIBarButtonItemStyle)style callback:(nonnull LXMBarButtonItemCallback)callback;

+ (nonnull instancetype)itemWithTitle:(nullable NSString *)title style:(UIBarButtonItemStyle)style callback:(nonnull LXMBarButtonItemCallback)callback;

+ (nonnull instancetype)itemWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem callback:(nonnull LXMBarButtonItemCallback)callback;


@end
