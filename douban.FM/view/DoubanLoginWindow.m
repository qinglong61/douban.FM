//
//  DoubanLoginWindow.m
//  douban.FM
//
//  Created by qinglun.duan on 14-5-8.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import "DoubanLoginWindow.h"
#import "DoubanService.h"

@implementation DoubanLoginWindow
{
    NSForm *form;
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]) {
        
        self.title = @"豆瓣登录";
        form = [[[NSForm alloc] initWithFrame:contentRect] autorelease];
        [form setEntryWidth:300];
        [form setInterlineSpacing:20];
        [form setBordered:YES];
        [form setBezeled:YES];
        [form setTitleAlignment:NSLeftTextAlignment];
        [form setTextAlignment:NSLeftTextAlignment];
        [form setTitleFont:[NSFont systemFontOfSize:24.f]];
        [form setTextFont:[NSFont systemFontOfSize:24.f]];
        [form addEntry:@"邮箱"];
        [form addEntry:@"密码"];
        [form setCellSize:NSMakeSize(300, 24)];
        [self.contentView addSubview:form];
        [form setTarget:self];
        [form setAction:@selector(login)];
        
        NSButton *loginBtn = [[[NSButton alloc] initWithFrame:CGRectMake(0, 0, 300, 30)] autorelease];
        [loginBtn setTitle:@"登录"];
        [self.contentView addSubview:loginBtn];
        [loginBtn setTarget:self];
        [loginBtn setAction:@selector(login)];
    }
    return self;
}

- (void)login
{
    NSString *email = [(NSFormCell *)form.cells[0] stringValue];
    NSString *passwd = [(NSFormCell *)form.cells[1] stringValue];
    [[DoubanService instance] loginWithEmail:email password:passwd SuccessHandler:^(NSDictionary *successInfo) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didLogin" object:nil];
        [self hide];
        [self release];
    } failHandler:^(NSDictionary *failInfo) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"登录失败！！！";
        [alert runModal];
    }];
}

@end