//
//  main.m
//  douban.FM
//
//  Created by qinglun.duan on 13-12-3.
//  Copyright (c) 2013年 com.pwrd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PWAppDelegate.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        PWAppDelegate *delegate = [[PWAppDelegate alloc] init];
        [[NSApplication sharedApplication] setDelegate:delegate];
        [NSApp run];
    }
    return EXIT_SUCCESS;
}
