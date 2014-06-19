//
//  DownloadManager.m
//  immt
//
//  Created by 段清伦 on 13-3-10.
//  Copyright (c) 2013年 laohu.com. All rights reserved.
//

#import "DownloadManager.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import <CommonCrypto/CommonDigest.h>
#import "MyUtil.h"
#import "MessageView.h"
#import "PlayViewController.h"
#import "Mp4Manager.h"

#define downloadPath [CachesDirectory stringByAppendingPathComponent:@"videos"]
#define downloadFileExpirationDay 7 //过期时间一周
#define MaxConcurrentOperationCount 5
#define RequestTimeOutSeconds 5.0f
#define RequestNumberOfTimesToRetryOnTimeout 2
#define DownloadedListPath [CachesDirectory stringByAppendingPathComponent:@"downloadedList.plist"]
#define DownloadingListPath [CachesDirectory stringByAppendingPathComponent:@"downloadingList.plist"]

@interface DownloadManager ()

- (void)initRequestQueue;
- (void)updateRequestQueue:(NSArray *)videoInfoList;

@end

@implementation DownloadManager {
@private
    ASINetworkQueue *networkQueue;
}

@synthesize downloadedVideoInfoList, downloadingVideoInfoList, requestQueue;

static DownloadManager *sharedDownloadManager = nil;

+ (id)sharedDownloadManager {
    
    if (sharedDownloadManager == nil) {
        sharedDownloadManager = [[self alloc] init];
    }
    return sharedDownloadManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        [self initDownloadList];
        if (!requestQueue) {
            requestQueue = [[NSMutableDictionary alloc] init];
        }
        
        for (NSDictionary *infoData in self.downloadingVideoInfoList) {
            [[Mp4Manager sharedMp4Manager] analysisMP4src:infoData play:NO];
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:downloadPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:downloadPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveDownloadList:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveDownloadList:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveDownloadList:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(analysisFinish:) name:@"analysisFinish" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [downloadedVideoInfoList release], downloadedVideoInfoList = nil;
    [downloadingVideoInfoList release], downloadingVideoInfoList = nil;
    [networkQueue reset];
	[networkQueue release];
    [requestQueue release];
    [super dealloc];
}

- (void)addDownloadTask:(NSArray *)videoInfoList
{
    for (NSDictionary *infoData in videoInfoList) {
        if ([downloadingVideoInfoList containsObject:infoData]) {
            NSLog(@"已经在下载了");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"isDownloading" object:nil];
            MessageView *messageView = [[[MessageView alloc] initWithMessage:@"已经在下载了"] autorelease];
            [messageView show];
        } else if ([downloadedVideoInfoList containsObject:infoData]) {
            NSLog(@"下载过了");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"didDownloaded" object:nil];
            MessageView *messageView = [[[MessageView alloc] initWithMessage:@"下载过了"] autorelease];
            [messageView show];
        } else {
            MessageView *messageView = [[[MessageView alloc] initWithMessage:@"已加入下载列表"] autorelease];
            [messageView show];
            if ([self.downloadingVideoInfoList count] == 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"taskState" object:[NSNumber numberWithBool:NO]];
            }
            [self.downloadingVideoInfoList addObject:infoData];
            [[Mp4Manager sharedMp4Manager] analysisMP4src:infoData play:NO];
        }
    }
}

- (void)analysisFinish:(NSNotification *)notification
{
    NSMutableDictionary *_infoData = notification.object;
    BOOL isPlay = [[notification.userInfo objectForKey:@"isPlay"] boolValue];
    if (!isPlay) {
        NSString *mp4Src = [_infoData objectForKey:@"url"];
        if (![mp4Src isEqualToString:@""]) {
            NSLog(@"下载任务解析成功！ real_video_url = %@\n", mp4Src);
            [self updateRequestQueue:[NSArray arrayWithObject:_infoData]];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"oneDownloadBegin" object:_infoData];
        } else {
            NSLog(@"下载任务解析失败！");
        }
    }
}

- (void)initDownloadList
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:DownloadingListPath]) {
        self.downloadingVideoInfoList = [NSMutableArray arrayWithContentsOfFile:DownloadingListPath];
    } else {
        NSMutableArray *_tmpArr = [[NSMutableArray alloc] init];
        self.downloadingVideoInfoList = _tmpArr;
        [_tmpArr release];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:DownloadedListPath]) {
        self.downloadedVideoInfoList = [NSMutableArray arrayWithContentsOfFile:DownloadedListPath];
    } else {
        NSMutableArray *_tmpArr = [[NSMutableArray alloc] init];
        self.downloadedVideoInfoList = _tmpArr;
        [_tmpArr release];
    }
}

- (void)saveDownloadList:(NSNotification *)notification
{   
    [self.downloadingVideoInfoList writeToFile:DownloadingListPath atomically:YES];
    [self.downloadedVideoInfoList writeToFile:DownloadedListPath atomically:YES];
}

- (void)initRequestQueue
{
    networkQueue = [[ASINetworkQueue alloc] init];
    [networkQueue reset];

    [networkQueue setRequestDidReceiveResponseHeadersSelector:@selector(request:didReceiveResponseHeaders:)];
    [networkQueue setRequestDidFinishSelector:@selector(requestDidFinish:)];
    [networkQueue setRequestDidFailSelector:@selector(requestDidFail:)];
    [networkQueue setQueueDidFinishSelector:@selector(queueDidFinish:)];

    [networkQueue setShowAccurateProgress:YES];
    [networkQueue setDelegate:self];
    [networkQueue setDownloadProgressDelegate:nil];
    [networkQueue setMaxConcurrentOperationCount:MaxConcurrentOperationCount];
    [networkQueue setShouldCancelAllRequestsOnFailure:NO];
    [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
}

- (void)updateRequestQueue:(NSArray *)videoInfoList
{
    if (!networkQueue) {
        [self initRequestQueue];
    }
    
	for (NSDictionary *info in videoInfoList)
    {
        NSString *urlString = [info objectForKey:@"url"];
        
//        ASIHTTPRequest *request = [requestQueue objectForKey:[info objectForKey:@"id"]];
//        if (!request) {
//            request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
//        } else {
//            [[request retain] autorelease];
//        }
        ASIHTTPRequest *request = [[[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
        
        NSString *fileName = [[MyUtil encodeURL:[info objectForKey:@"title"]] stringByAppendingString:@".mp4"];
        
        [request setDownloadDestinationPath:[downloadPath stringByAppendingPathComponent:fileName]];
        [request setTemporaryFileDownloadPath:[downloadPath stringByAppendingPathComponent:[fileName stringByAppendingString:@".tmp"]]];
        [request setAllowResumeForFileDownloads:YES];
        [request setTimeOutSeconds:RequestTimeOutSeconds];
        [request setNumberOfTimesToRetryOnTimeout:RequestNumberOfTimesToRetryOnTimeout];
        
        [request setUserInfo:[NSDictionary dictionaryWithObject:info forKey:@"info"]];
        [networkQueue addOperation:request];
        [requestQueue setObject:request forKey:[info objectForKey:@"id"]];
    }
    
    [networkQueue go];
}

- (void)request:(ASIHTTPRequest *)_request didReceiveResponseHeaders:(NSDictionary *)responseHeaders
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"oneDownloadBegin" object:_request userInfo:responseHeaders];
}

- (void)requestDidFinish:(ASIHTTPRequest *)request
{
    NSInteger index = [self.downloadingVideoInfoList indexOfObject:[self infoInList:request]];
    [self.downloadedVideoInfoList addObject:[[request userInfo] objectForKey:@"info"]];
    
    [self removeTask:request];
    
    NSLog(@"任务（%d）完成", index);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"oneDownloadComplete" object:[NSDictionary dictionaryWithObjectsAndKeys:request, @"request", [NSNumber numberWithInteger:index], @"index", nil]];
}

- (void)requestDidFail:(ASIHTTPRequest *)request
{
    if ([[request error] domain] == NetworkRequestErrorDomain) {

    }
    
    switch ([[request error] code]) {
        case ASIRequestTimedOutErrorType:
            NSLog(@"请求超时");
            //自动暂停 发通知给cell
            break;
            
        case ASIRequestCancelledErrorType:
            NSLog(@"请求取消");
            break;
            
        default:
            NSLog(@"请求失败");
            break;
    }
    
    [self pause:request];
}

- (void)queueDidFinish:(ASINetworkQueue *)queue
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"taskState" object:[NSNumber numberWithBool:YES]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"allDownloadComplete" object:nil];
    [self saveDownloadList:nil];
}

- (void)pause:(ASIHTTPRequest *)request
{
    if (request) {
        [request clearDelegatesAndCancel];
//        [requestQueue setObject:nil forKey:[[[request userInfo] objectForKey:@"info"] objectForKey:@"id"]];
    }
}

- (void)resume:(NSDictionary *)info
{
    [[Mp4Manager sharedMp4Manager] analysisMP4src:info play:NO];
}

- (void)removeTask:(ASIHTTPRequest *)request
{
    if (request) {
        [request clearDelegatesAndCancel];
        
        [self.downloadingVideoInfoList removeObject:[self infoInList:request]];
        if ([self.downloadingVideoInfoList count] == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"taskState" object:[NSNumber numberWithBool:YES]];
        }
//        [requestQueue removeObjectForKey:[[[request userInfo] objectForKey:@"info"] objectForKey:@"id"]];
    }
}

- (void)removeVideo:(NSDictionary *)videoInfo
{
    if (videoInfo)
    {
        [self.downloadedVideoInfoList removeObject:videoInfo];
        [self saveDownloadList:nil];
        NSString *fileName = [DownloadManager pathWithTitle:[videoInfo objectForKey:@"title"]];
        [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
    }
}

- (void)clearDisk
{
    [networkQueue cancelAllOperations];
    [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:downloadPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
}

- (void)cleanDownLoadedFiles
{
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:(-60*60*24) * downloadFileExpirationDay];
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:downloadPath];
    for (NSString *path in directoryEnumerator) {
        NSDictionary *attributes = [directoryEnumerator fileAttributes];
        NSDate *lastModificationDate = [attributes objectForKey:NSFileModificationDate];
        NSString *filePath = [downloadPath stringByAppendingPathComponent:path];
        if ([expirationDate earlierDate:lastModificationDate] == lastModificationDate) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

- (NSDictionary *)infoInList:(ASIHTTPRequest *)request
{
    NSDictionary *info = [[request userInfo] objectForKey:@"info"];
    for (NSDictionary *dic in self.downloadingVideoInfoList) {
        if ([[dic objectForKey:@"id"] intValue] == [[info objectForKey:@"id"] intValue]) {
            return dic;
        }
    }
    return nil;
}

+ (NSString *)pathWithTitle:(NSString *)title
{
    NSString *fileName = [[MyUtil encodeURL:title] stringByAppendingString:@".mp4"];
    return [downloadPath stringByAppendingPathComponent:fileName];
}

+ (unsigned long long)sizeWithTitle:(NSString *)title
{
    unsigned long long fileSize = 0;
    
    NSString *filePath = [[MyUtil encodeURL:title] stringByAppendingString:@".mp4"];
    
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:downloadPath];
    for (NSString *path in directoryEnumerator) {
        if ([path isEqualToString:filePath]) {
            NSDictionary *attributes = [directoryEnumerator fileAttributes];
            fileSize += [[attributes objectForKey:NSFileSize] unsignedLongLongValue];
            break;
        }
    }
    return fileSize;
}

@end
