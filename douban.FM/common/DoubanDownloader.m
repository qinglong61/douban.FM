//
//  DoubanDownloader.m
//  douban.FM
//
//  Created by qinglun.duan on 14-5-27.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import "DoubanDownloader.h"
#import "DoubanFMUtilities.h"
#import "DoubanService.h"

@implementation DoubanDownloader

@synthesize downloading, downloadIsIndeterminate, downloadProgress, download, downloadedSoFar, expectedContentLength, fileURL, originalURL, completionHandler;

static DoubanDownloader *instance;

+ (DoubanDownloader *)instance
{
    @synchronized(self){
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    return instance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if (instance == nil)
        {
            instance = [super allocWithZone:zone];
            return instance;
        }
    }
    return nil;
}

- (id)init
{
    if (self = [super init]) {

    }
    return self;
}

- (void)downloadURL:(NSURL *)url completionHandler:(void (^)(BOOL))handler
{
    self.completionHandler = handler;
    
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:60.0];
    self.download = [[[NSURLDownload alloc] initWithRequest:theRequest delegate:self] autorelease];
    NSString *downloadPath = [DoubanFMUtilities filePathWithSid:[DoubanService instance].currentSong.songId];
    [self.download setDestination:downloadPath allowOverwrite:NO];
    self.fileURL = [NSURL fileURLWithPath:downloadPath];
    self.downloading = YES;
}

#pragma mark - NSURLDownloadDelegate methods

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
    self.expectedContentLength = [response expectedContentLength];
    if (self.expectedContentLength > 0.0) {
        self.downloadIsIndeterminate = NO;
        self.downloadedSoFar = 0;
    }
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
    self.downloadedSoFar += length;
    if (self.downloadedSoFar >= self.expectedContentLength) {
        // the expected content length was wrong as we downloaded more than expected
        self.downloadIsIndeterminate = YES;
    } else {
        self.downloadProgress = (float)self.downloadedSoFar / (float)self.expectedContentLength;
    }
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
    self.downloading = NO;
    if (self.completionHandler) {
        self.completionHandler(NO);
    }
}

- (void)download:(NSURLDownload *)aDownload didFailWithError:(NSError *)error
{
    self.downloading = NO;
    if (self.completionHandler) {
        self.completionHandler(YES);
    }
}

@end