# LXMBlockKit
Some category adding block API for UIKit    

UIButton 的target-action方法不能把回调方法跟配置方法写在一起，不利于代码阅读；而且target也基本都是所属的viewController，每次都addTarget：self也比较麻烦；就平常使用来说，button用的最多的也就是响应一下touchUpInside事件，所以封装一个用block回调点击事件的方法就能很好的应对日常的使用~    
类似的情况还有UIBarButtonItem，UIGestureRecognizer，NSNotification等    
所以就有了这个库    

原来button事件的典型写法：     
```
[testButton addTarget:self action:@selector(handleButtonTapped:) forControlEvents:UIControlEventTouchUpInside]; 

- (void)handleButtonTapped:(UIButton *)sender {    
    NSLog(@"handleButtonTapped");        
}
```
使用Block的写法：
```
   [testButton addButtonCallback:^(UIButton *sender) {
        NSLog(@"handleButtonTapped");
   }];
```
可以看出来还是省了很多代码的，而且事件的回调就写在button的配置处，不用来回找~~   

需要注意的是：
`__weak typeof(self) weakSelf = self;`    
block回调中，务必使用weakSelf！直接使用self必定会导致循环引用！！！    
block回调中，务必使用weakSelf！直接使用self必定会导致循环引用！！！    
block回调中，务必使用weakSelf！直接使用self必定会导致循环引用！！！    
重要的事情说三遍！！！   
这是所有block都需要注意的问题，没办法，只能自己在脑中时刻提醒自己注意，要不就跑Instruments测试吧~   

其中NSNotificationCenter的部分，基本是照搬大神nicklockwood的[FXNotifications](https://github.com/nicklockwood/FXNotifications);    
研究了几个类似的可以autoRemove的notification的库，感觉还是FXNotifications最符合平时的场景，所以就按自己的代码习惯重新敲了一遍 

有什么问题，欢迎讨论~


## How to use    

1, cocoaPods    
在你的podfile中添加    
`pod 'LXMBlockKit', '~> 0.0.6'`    
run `pod install` or `pod update`   
然后在需要的地方 `#import "LXMBlockKit.h"`就可以了

## Update    

0.0.6   加入NSTimer的block方法    
0.0.5   加入nullable和nonnull等字段，方便swift调用    
0.0.4   更新UIBarButtonItem方法    
0.0.3   修复target为nil的bug

## License
LXMBlockKit is provided under the MIT license. See LICENSE file for details.




