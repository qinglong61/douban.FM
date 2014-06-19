//
//  DoubanChannel.h
//  douban.FM
//
//  Created by qinglun.duan on 14-6-10.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DoubanChannel : NSObject

@property (nonatomic, retain) NSString *channelId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *cover;
@property (nonatomic, retain) NSString *intro;
@property (nonatomic, assign) NSInteger songCount;
@property (nonatomic, retain) NSString *collected;

@end
