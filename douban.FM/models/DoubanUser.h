//
//  DoubanUser.h
//  douban.FM
//
//  Created by qinglun.duan on 14-5-7.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import "DoubanBaseModel.h"

@interface DoubanUser : DoubanBaseModel

@property (nonatomic, retain) NSString *uid;
@property (nonatomic, retain) NSString *uname;
@property (nonatomic, retain) NSString *token;

@end
