//
//  DoubanPlayView.h
//  douban.FM
//
//  Created by qinglun.duan on 14-5-29.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSControl (target_action)

- (void)setTarget:(id)anObject action:(SEL)aSelector;

@end

@interface DoubanPlayView : NSView <NSTextFieldDelegate>

@end
