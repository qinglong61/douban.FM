//
//  DownloadManager.h
//  immt
//
//  Created by 段清伦 on 13-3-10.
//  Copyright (c) 2013年 laohu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ASIHTTPRequest;

@interface DownloadManager : NSObject {
    
    NSMutableArray *downloadedVideoInfoList;
    NSMutableArray *downloadingVideoInfoList;
    NSInteger complete;
}

@property (nonatomic, retain) NSMutableArray *downloadingVideoInfoList;
@property (nonatomic, retain) NSMutableArray *downloadedVideoInfoList;
@property (nonatomic, retain) NSMutableDictionary *requestQueue;

+ (id)sharedDownloadManager;
+ (NSString *)pathWithTitle:(NSString *)title;
+ (unsigned long long)sizeWithTitle:(NSString *)title;

- (void)addDownloadTask:(NSArray *)videoInfoList;
- (void)pause:(ASIHTTPRequest *)request;
- (void)resume:(NSDictionary *)info;
- (void)removeTask:(ASIHTTPRequest *)request;
- (void)removeVideo:(NSDictionary *)videoInfo;

@end
