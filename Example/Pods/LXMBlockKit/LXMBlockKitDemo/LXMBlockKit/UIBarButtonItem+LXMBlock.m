//
//  UIBarButtonItem+LXMBlock.m
//  LXMBlockKitDemo
//
//  Created by luxiaoming on 16/6/21.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//

#import "UIBarButtonItem+LXMBlock.h"
#import <objc/runtime.h>

@interface UIBarButtonItem ()

@property (nonatomic, copy, readwrite) LXMBarButtonItemCallback itemCallback;


@end

@implementation UIBarButtonItem (LXMBlock)

#pragma mark - Public

+ (instancetype)itemWithImage:(UIImage *)image callback:(LXMBarButtonItemCallback)callback {
    return [UIBarButtonItem itemWithTitle:nil image:image landscapeImagePhone:nil style:UIBarButtonItemStylePlain callback:callback];
}

+ (instancetype)itemWithImage:(UIImage *)image landscapeImagePhone:(UIImage *)landscapeImagePhone callback:(LXMBarButtonItemCallback)callback {
    return [UIBarButtonItem itemWithTitle:nil image:image landscapeImagePhone:landscapeImagePhone style:UIBarButtonItemStylePlain callback:callback];
}

+ (instancetype)itemWithTitle:(NSString *)title callback:(LXMBarButtonItemCallback)callback {
    return [UIBarButtonItem itemWithTitle:title image:nil landscapeImagePhone:nil style:UIBarButtonItemStylePlain callback:callback];
}



+ (instancetype)itemWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style callback:(LXMBarButtonItemCallback)callback {
    return [UIBarButtonItem itemWithTitle:nil image:image landscapeImagePhone:nil style:style callback:callback];
}

+ (instancetype)itemWithImage:(UIImage *)image landscapeImagePhone:(UIImage *)landscapeImagePhone style:(UIBarButtonItemStyle)style callback:(LXMBarButtonItemCallback)callback {
    return [UIBarButtonItem itemWithTitle:nil image:image landscapeImagePhone:landscapeImagePhone style:style callback:callback];
}

+ (instancetype)itemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style callback:(LXMBarButtonItemCallback)callback {
    return [UIBarButtonItem itemWithTitle:title image:nil landscapeImagePhone:nil style:style callback:callback];
}

+ (instancetype)itemWithBarButtonSystemItem:(UIBarButtonSystemItem)systemItem callback:(LXMBarButtonItemCallback)callback {
    UIBarButtonItem *item = nil;
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:item action:@selector(handleLXMBarButtonItemCallback:)];
    item.itemCallback = callback;
    item.target = item;//如果没有这一句，item的target其实是nil，有时候依然可以正常调用selector，貌似是因为响应链的传递；但有时候又不能正常调用（viewController不是firstResponese的时候）；所以统一加这么一句修复下
    return item;
}







#pragma mark - Private

+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image landscapeImagePhone:(UIImage *)landscapeImagePhone style:(UIBarButtonItemStyle)style callback:(LXMBarButtonItemCallback)callback {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] init];
    item.title = title;
    item.image = image;
    item.landscapeImagePhone = landscapeImagePhone;
    item.style = style;
    item.target = item;
    item.itemCallback = callback;
    item.action = @selector(handleLXMBarButtonItemCallback:);
    return item;
}

- (void)handleLXMBarButtonItemCallback:(UIBarButtonItem *)sender {
    if (self.itemCallback) {
        self.itemCallback(sender);
    }
}

#pragma mark - Property

- (LXMBarButtonItemCallback)itemCallback {
    return objc_getAssociatedObject(self, @selector(itemCallback));
}

- (void)setItemCallback:(LXMBarButtonItemCallback)itemCallback {
    objc_setAssociatedObject(self, @selector(itemCallback), itemCallback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


@end
