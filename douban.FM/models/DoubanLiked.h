//
//  DoubanLiked.h
//  douban.FM
//
//  Created by qinglun.duan on 14-3-26.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import "DoubanBaseModel.h"

@interface DoubanLiked : DoubanBaseModel

@property (nonatomic, assign) NSUInteger total;
@property (nonatomic, retain) NSArray *songs;

@end
