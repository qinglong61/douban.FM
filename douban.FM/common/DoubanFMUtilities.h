//
//  DoubanFMUtilities.h
//  douban.FM
//
//  Created by qinglun.duan on 14-3-26.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DoubanFMUtilities : NSObject

+ (NSString *)storePath;
+ (void)setStorePath:(NSString *)path;
+ (id)readWithFileName:(NSString *)fileName;
+ (BOOL)write:(id)plist fileName:(NSString *)fileName;
+ (void)setCookieName:(NSString *)name value:(NSString *)value;
+ (NSString *)encodeURL:(NSString *)urlString;

@end
