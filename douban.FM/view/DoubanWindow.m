//
//  DoubanWindow.m
//  douban.FM
//
//  Created by qinglun.duan on 14-5-8.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import "DoubanWindow.h"

@implementation DoubanWindow

- (id)initWithFrame:(CGRect)frameRect
{
    if (self = [self initWithContentRect:frameRect styleMask:
                NSBorderlessWindowMask |
                NSTitledWindowMask |
                NSClosableWindowMask |
                NSMiniaturizableWindowMask |
                NSResizableWindowMask
                 backing:NSBackingStoreBuffered defer:NO]) {
        
    }
    return self;
}

- (void)show
{
    [NSApp runModalForWindow:self];
}

- (void)hide
{
    [NSApp stopModal];
}

@end