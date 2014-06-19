//
//  DoubanDownloader.h
//  douban.FM
//
//  Created by qinglun.duan on 14-5-27.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DoubanDownloader : NSObject <NSURLDownloadDelegate>

@property BOOL downloading;

@property long long expectedContentLength;
@property long long downloadedSoFar;
@property CGFloat downloadProgress;
@property BOOL downloadIsIndeterminate;

@property (nonatomic, retain) NSURLDownload *download;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSURL *originalURL;

@property (nonatomic, copy) void (^completionHandler)(BOOL failed);

+ (DoubanDownloader *)instance;
- (void)downloadURL:(NSURL *)url completionHandler:(void (^)(BOOL failed))handler;

@end
