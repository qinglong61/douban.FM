//
//  DoubanSong.h
//  douban.FM
//
//  Created by qinglun.duan on 14-3-27.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import "DoubanBaseModel.h"

@interface DoubanSong : DoubanBaseModel

@property (nonatomic, retain) NSString *artist;
@property (nonatomic, retain) NSString *songId;
@property (nonatomic, assign) BOOL liked;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *picture;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, assign) BOOL cached;
@property (nonatomic, retain) NSString *remotePath;

@end
