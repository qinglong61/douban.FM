//
//  PWAppDelegate.m
//  douban.FM
//
//  Created by qinglun.duan on 13-12-3.
//  Copyright (c) 2013年 com.pwrd. All rights reserved.
//

#import "PWAppDelegate.h"
#import "DoubanPlayView.h"
#import "DoubanPlayListView.h"
#import "DoubanSongListView.h"
#import "DoubanChannelListView.h"
#import "DoubanLoginWindow.h"

#import "Constants.h"
#import "DoubanService.h"
#import "DoubanFMUtilities.h"

@implementation PWAppDelegate

- (id)init
{
    if (self = [super init]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogin) name:@"didLogin" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogout) name:@"didLogout" object:nil];
        
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];
        
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
        [DoubanFMUtilities creatPathIfNeed:[DoubanFMUtilities storePath]];
        [DoubanFMUtilities creatPathIfNeed:[DoubanFMUtilities musicsCachePath]];
        
        NSArray *cookies;
//        cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://douban.fm"]];
//        for (NSHTTPCookie *cookie in cookies) {
//            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
//        }
        
        cookies = [DoubanFMUtilities readWithFileName:COOKIES_FILE_NAME];
        if (cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:[NSURL URLWithString:@"http://douban.fm"] mainDocumentURL:[NSURL URLWithString:@"http://douban.fm"]];
        }
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    [NSApp setMainMenu:[NSMenu new]];
    
    NSMenuItem *appMenuItem = [NSMenuItem new];
    [[NSApp mainMenu] addItem:appMenuItem];
    
    NSMenu *appMenu = [NSMenu new];
    [appMenuItem setSubmenu:appMenu];
    
    NSString *appName = [[NSProcessInfo processInfo] processName];
    NSString *quitTitle = [@"Quit " stringByAppendingString:appName];
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1200, 600) styleMask:NSTitledWindowMask | NSBorderlessWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO];
    [window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
    [window setTitle:[[NSProcessInfo processInfo] processName]];
    [window makeKeyAndOrderFront:self];
    [window makeMainWindow];
    self.window = window;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (![[DoubanService instance] isLogin]) {
        [self didLogout];
    } else {
        [self didLogin];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [[DoubanService instance] syncLikedSongs];
}

- (void)didLogin
{
    DoubanSongListView *songListView = [[[DoubanSongListView alloc] initWithFrame:CGRectMake(0, 200, 800, 400)] autorelease];
    [self.window.contentView addSubview:songListView];
    
    DoubanPlayListView *playListView = [[[DoubanPlayListView alloc] initWithFrame:CGRectMake(800, 200, 200, 400)] autorelease];
    [self.window.contentView addSubview:playListView];
    
    DoubanChannelListView *channelListView = [[[DoubanChannelListView alloc] initWithFrame:CGRectMake(1000, 200, 200, 400)] autorelease];
    [self.window.contentView addSubview:channelListView];
    
    DoubanPlayView *view = [[DoubanPlayView alloc] initWithFrame:NSMakeRect(0, 0, 1200, 200)];
    [self.window.contentView addSubview:view];
}

- (void)didLogout
{
    DoubanLoginWindow *loginWindow = [[DoubanLoginWindow alloc] initWithFrame:CGRectMake(0, 0, 300, 120)];
    [loginWindow show];
}

@end