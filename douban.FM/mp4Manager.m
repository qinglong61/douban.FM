//
//  Mp4Manager.m
//  immt
//
//  Created by qinglun.duan on 13-3-25.
//  Copyright (c) 2013年 laohu.com. All rights reserved.
//

#import "Mp4Manager.h"
#import "MyUtil.h"

#define QIYI_VIDEO_URL_PREFIX @"http://cache.m.iqiyi.com/mt/%@/"
#define analysisTimeoutSeconds 5

@implementation Mp4Manager
{
    @private
    NSMutableDictionary *infoData;
    UIWebView *fetchMp4UrlWebView;
    NSMutableArray *queue;
    BOOL isQueuing;
    BOOL isPlay;
    BOOL isTiming;
}

static Mp4Manager *sharedMp4Manager = nil;

+ (id)sharedMp4Manager {
    @synchronized(self) {
        if (sharedMp4Manager == nil) {
            sharedMp4Manager = [[self alloc] init];
        }
    }
    return sharedMp4Manager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedMp4Manager == nil) {
            sharedMp4Manager = [super allocWithZone:zone];
            return sharedMp4Manager;
        }
    }
    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        infoData = [[NSMutableDictionary alloc] init];
        fetchMp4UrlWebView = [[UIWebView alloc] init];
        fetchMp4UrlWebView.delegate = self;
        queue = [[NSMutableArray alloc] init];
        isQueuing = NO;
    }
    return self;
}

- (void)dealloc
{
    [infoData release], infoData = nil;
    [fetchMp4UrlWebView release], fetchMp4UrlWebView = nil;
    [queue release], queue = nil;
    [super dealloc];
}

- (void)analysisMP4src:(NSDictionary *)dic play:(BOOL)_isPlay
{
    isPlay = _isPlay;
    
    NSString *url = [dic objectForKey:@"url"];
    NSString *extension = [url substringFromIndex:url.length-4];
    if ([extension isEqualToString:@".mp4"]) {
        [self analysisFinish:url];
        return;
    }
    
    [queue addObject:dic];
    if (!isQueuing) {
        [self start];
        isQueuing = YES;
    }
}

- (void)start
{
    if ([queue count] != 0) {
        
        isTiming = YES;
        NSLog(@"timing...");
        [self performSelector:@selector(timeout) withObject:nil afterDelay:analysisTimeoutSeconds];
        
        NSDictionary *dic = [queue objectAtIndex:0];
        if (dic) {
            infoData = [dic mutableCopy];
            NSString *playSrc = [dic objectForKey:@"url"];
            if ([[dic objectForKey:@"source_company"] intValue] == 1) {//youku
                [NSThread detachNewThreadSelector:@selector(analysisMP4youku:) toTarget:self withObject:playSrc];
            } else if ([[dic objectForKey:@"source_company"] intValue] == 0) {//qiyi
                [NSThread detachNewThreadSelector:@selector(analysisMP4qiyi:) toTarget:self withObject:playSrc];
            }
        }
    } else {
        isQueuing = NO;
    }
}

- (void)analysisMP4qiyi:(NSString *)playSrc
{
    @autoreleasepool {
        if (playSrc) {
            NSString *tvid = [self getTvid:playSrc];
            NSString *qiyi_video_url_prefix = [infoData objectForKey:@"qiyi_video_url_prefix"];
            if ((NSNull *)qiyi_video_url_prefix == [NSNull null] || [qiyi_video_url_prefix isEqualToString:@""]) {
                qiyi_video_url_prefix = QIYI_VIDEO_URL_PREFIX;
            }
            NSString *fetch_qiyi_video_url1 = [NSString stringWithFormat:qiyi_video_url_prefix, tvid];
            NSDictionary *videoInfo = [MyUtil requestWithUrl:fetch_qiyi_video_url1 gz:NO];
            NSString *fetch_qiyi_video_url2 = [[[[videoInfo objectForKey:@"data"] objectForKey:@"mpl"] objectAtIndex:0] objectForKey:@"m4u"];
            NSData *real_video_url_info_data = [MyUtil loadDataFromUrl:fetch_qiyi_video_url2 Method:@"GET" Data:nil];
            NSString *real_video_url_info_str = [[[NSString alloc] initWithData:real_video_url_info_data encoding:NSUTF8StringEncoding] autorelease];;
            NSString *real_video_url = [self getRealVideoUrl:real_video_url_info_str];
            
            NSString *extension = [real_video_url substringFromIndex:real_video_url.length-4];
            if ([extension isEqualToString:@".mp4"]) {
                [self performSelectorOnMainThread:@selector(analysisFinish:) withObject:real_video_url waitUntilDone:YES];
            } else {
                [self performSelectorOnMainThread:@selector(analysisFinish:) withObject:@"" waitUntilDone:YES];
            }
        }
    }
}

- (void)analysisMP4youku:(NSString *)swfSrc
{
    @autoreleasepool {
        if (swfSrc) {
            NSString *homePath = [[NSBundle mainBundle] executablePath];
            NSArray *strings = [homePath componentsSeparatedByString:@"/"];
            NSString *executableName  = [strings objectAtIndex:[strings count]-1];
            NSString *rawDirectory = [homePath substringToIndex:[homePath length]-[executableName length]-1];
            NSString *baseDirectory = [rawDirectory stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
            NSString *urlString = [NSString stringWithFormat:@"file://%@/fetchMp4Url.html#%@", baseDirectory, swfSrc];

            [fetchMp4UrlWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5]];
            [fetchMp4UrlWebView performSelectorOnMainThread:@selector(reload) withObject:nil waitUntilDone:YES];
        }
    }
}

- (void)analysisFinish:(NSString *)mp4Src
{
    isTiming = NO;
    [infoData setObject:mp4Src forKey:@"url"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"analysisFinish" object:infoData userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:isPlay], @"isPlay", nil]];
    if ([queue count] != 0) {
        [queue removeObjectAtIndex:0];
    }
    [self start];
}

#pragma mark - UIWebViewDelegate methods

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self analysisFinish:@""];
}

- (void)webViewDidFinishLoad:(UIWebView *)_webView
{
    NSString *hash = [[[_webView request] URL] fragment];
    NSString *extension = [hash substringFromIndex:hash.length-4];
    if ([extension isEqualToString:@".mp4"]) {
        NSArray *arr = [hash componentsSeparatedByString:@"&"];
        NSString *mp4Src = [arr objectAtIndex:1];
        [self analysisFinish:mp4Src];
    } else {
        [_webView stringByEvaluatingJavaScriptFromString:@"fetchMp4Url()"];
    }
}

#pragma mark - util methods

- (NSDictionary *)getParameterFromUrl:(NSString *)url
{
    NSString *parameterStr = nil;
    NSMutableDictionary *parameters = [[[NSMutableDictionary alloc] init] autorelease];
    
    if ([url rangeOfString:@"?"].location != NSNotFound) {
        parameterStr = [url substringFromIndex:([url rangeOfString:@"?"].location + 1)];
    }
    NSArray *parameterArr = [parameterStr componentsSeparatedByString:@"&"];
    for (NSString *item in parameterArr) {
        NSString *key = [item substringToIndex:[item rangeOfString:@"="].location];
        NSString *value = [item substringFromIndex:([item rangeOfString:@"="].location + 1)];
        [parameters setObject:value forKey:key];
    }
    
    return parameters;
}

- (NSString *)getTvid:(NSString *)url
{
    return [[self getParameterFromUrl:url] objectForKey:@"tvid"];
}

- (NSString *)getRealVideoUrl:(NSString *)js
{
    NSInteger fromIndex = [js rangeOfString:@"http://"].location;
    if (fromIndex != NSNotFound) {
        NSString *tmpStr = [js substringFromIndex:fromIndex];
        NSInteger toIndex = [tmpStr rangeOfString:@"?key="].location;
        if (toIndex != NSNotFound) {
            return [tmpStr substringToIndex:toIndex];
        }
    }
    return nil;
}

- (void)timeout
{
    if (isTiming) {
        NSLog(@"timeout");
        [self analysisFinish:@""];
    }
}

@end
