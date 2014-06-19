//
//  DoubanService.h
//  douban.FM
//
//  Created by qinglun.duan on 14-3-27.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import "DoubanUser.h"

@interface DoubanService : NSObject

@property (nonatomic, retain, readonly) NSArray *likedSongs;
@property (nonatomic, retain) DoubanUser *user;

+ (DoubanService *)instance;
- (BOOL)isLogin;
- (BOOL)login;

@end
