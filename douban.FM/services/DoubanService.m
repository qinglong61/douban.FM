//
//  DoubanService.m
//  douban.FM
//
//  Created by qinglun.duan on 14-3-27.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import "DoubanService.h"
#import "DoubanFMUtilities.h"
#import "PWRequest.h"
#import "PWAppDelegate.h"
#import "Douban.h"
#import "Constants.h"

@implementation DoubanService

@synthesize likedSongs, user;

static DoubanService *instance;

+ (DoubanService *)instance
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

#pragma mark - instance methods

- (NSArray *)likedSongs
{
    if (!likedSongs) {
        DoubanLiked *dl = [DoubanFMUtilities readWithFileName:LIKED_SONGS_FILE_NAME];
        if (!dl) {
            [self requestAndStoreLikedSongs];
            dl = [DoubanFMUtilities readWithFileName:LIKED_SONGS_FILE_NAME];
        }
//    [dl.songs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//         NSLog(@"%@\n", [(DoubanSong *)obj title]);
//    }];
        likedSongs = dl.songs;
    }
    return likedSongs;
}

- (BOOL)isLogin
{
    return user.token?YES:NO;
}

- (BOOL)login
{
    NSDictionary *json = [PWRequest syncRequestWithURL:DOUBAN_LOGIN_URL httpMethod:@"POST" params:@{@"alt":@"json",
                                                                                                  @"apikey":CLIENT_ID,
                                                                                                  @"client_id":CLIENT_ID,
                                                                                                  @"client_secret":CLIENT_SECRET,
                                                                                                  @"grant_type":@"password",
                                                                                                  @"password":@"19900318",
                                                                                                  @"username":@"qinglong61@163.com"
                                                                                                  }];
    if (json) {
        NSString *token = [json objectForKey:@"access_token"];
        NSString *uname = [json objectForKey:@"douban_user_name"];
        NSString *uid = [json objectForKey:@"douban_user_id"];
        if (token) {
            NSLog(@"登录成功：%@", json);
            self.user = [[[DoubanUser alloc] initWithDictionary:@{@"uid":uid,
                                                                        @"uname":uname,
                                                                        @"token":token}] autorelease];
            return YES;
        }
    }
    NSLog(@"登录失败：%@", json);
    return NO;
}

#pragma mark - helper

- (void)requestAndStoreLikedSongs
{
//    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://douban.fm"]];
//    NSString *ck = @"";
//    NSString *spbid = @"";
//    for (NSHTTPCookie *cookie in cookies) {
//        if ([cookie.name isEqualToString:@"ck"]) {
//            ck = [self getStringFromCookieValue:cookie.value];
//        }
//        if ([cookie.name isEqualToString:@"bid"]) {
//            spbid = [@"%3A%3A" stringByAppendingString:[self getStringFromCookieValue:cookie.value]];
//        }
//    }
    NSString *url = [NSString stringWithFormat:doubanFMLikedURL, ck, spbid, 0];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
//    [request addValue:@"http://douban.fm/mine" forHTTPHeaderField:@"Referer"];
    
    [request addValue:[@"Bearer " stringByAppendingString:self.user.token] forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *response = [PWRequest syncRequestWithRequest:request];
//    DLog(@"\n%@\n++++++++\n%@", url, response);
    
    DoubanLiked *dl = [[[DoubanLiked alloc] init] autorelease];
    
    NSUInteger total = [[response objectForKey:@"total"] integerValue];
    dl.total = total;
    NSMutableArray *songs = [[NSMutableArray alloc] initWithArray:[response objectForKey:@"songs"]];
    
    for (int i = 15; i<total; i+=15) {
        NSString *url = [NSString stringWithFormat:doubanFMLikedURL, ck, spbid, i];
        [request setURL:[NSURL URLWithString:url]];
        NSDictionary *response = [PWRequest syncRequestWithRequest:request];
        [songs addObjectsFromArray:[response objectForKey:@"songs"]];
    }
    
    DLog(@"\n获取到红心歌曲共---%ld---\n", total);
    
    NSMutableArray *songModels = [[NSMutableArray alloc] init];
    for (NSDictionary *node in songs) {
        DoubanSong *song = [[DoubanSong alloc] init];
        song.artist = [node objectForKey:@"artist"];
        song.songId = [node objectForKey:@"id"];
        song.liked = [[node objectForKey:@"liked"] boolValue];
        song.path = [node objectForKey:@"path"];
        song.picture = [node objectForKey:@"picture"];
        song.subject_title = [node objectForKey:@"\"subject_title\""];
        song.title = [node objectForKey:@"title"];
        [songModels addObject:song];
        [song release];
    }
    [songs release];
    dl.songs = songModels;
    [songModels release];
    
    if ([DoubanFMUtilities write:dl fileName:LIKED_SONGS_FILE_NAME]) {
        DLog(@"红心歌曲列表保存成功！！！\n");
    }
}

//- (NSString *)getStringFromCookieValue:(NSString *)cookieValue
//{
//    return [cookieValue substringWithRange:NSMakeRange(1, cookieValue.length-2)];
//}
//
//- (void)storeCookies
//{
//    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://douban.fm"]];
//    DLog(@"%@", cookies);
//    [DoubanFMUtilities write:cookies fileName:COOKIES_FILE_NAME];
//}

@end