//
//  DoubanService.m
//  douban.FM
//
//  Created by qinglun.duan on 14-3-27.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import "DoubanService.h"
#import "DoubanFMUtilities.h"
#import "DoubanRequest.h"
#import "PWAppDelegate.h"
#import "Constants.h"
#import "DoubanDownloader.h"

typedef enum {
    Douban_playlist_type_new,
    Douban_playlist_type_switch,
    Douban_playlist_type_end,
    Douban_playlist_type_redHeart,
    Douban_playlist_type_unRedHeart,
} Douban_playlist_type;

@implementation DoubanService

@synthesize likedSongs, user, currentSong, currentChannel, playlist, player, timeObserverToken, currentTime, currentIndex;

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

- (id)init
{
    if (self = [super init]) {
        DoubanLiked *dl = [DoubanFMUtilities readWithFileName:LIKED_SONGS_FILE_NAME];
        self.likedSongs = [dl.songs mutableCopy];
        self.user = [[DoubanFMUtilities readWithFileName:USER_FILE_NAME] retain];
        self.player = [[AVPlayer alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playDidEnd) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

#pragma mark - login

- (void)setUser:(DoubanUser *)_user
{
    [user release];
    user = [_user retain];
    
    [DoubanFMUtilities write:user fileName:USER_FILE_NAME];
}

- (DoubanUser *)user
{
    return user;
}

- (BOOL)isLogin
{
    return user.token?YES:NO;
}

- (void)loginWithEmail:(NSString *)email password:(NSString *)passwd SuccessHandler:(void (^)(NSDictionary *))successHandler failHandler:(void (^)(NSDictionary *))failHandler
{
    NSDictionary *json = [DoubanRequest syncRequestWithURL:DOUBAN_LOGIN_URL httpMethod:@"POST" params:@{@"alt":@"json",
                                                                                                  @"apikey":CLIENT_ID,
                                                                                                  @"client_id":CLIENT_ID,
                                                                                                  @"client_secret":CLIENT_SECRET,
                                                                                                  @"grant_type":@"password",
                                                                                                  @"password":passwd,
                                                                                                  @"username":email
                                                                                                  }];
    if (json) {
        NSString *token = [json objectForKey:@"access_token"];
        NSString *uname = [json objectForKey:@"douban_user_name"];
        NSString *uid = [json objectForKey:@"douban_user_id"];
        if (token) {
            DLog(@"登录成功：%@", json);
            [DoubanRequest syncRequestWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:DOUBAN_LOGIN_HANDLE_URL]]];
            [self storeCookies];
            self.user = [[[DoubanUser alloc] initWithDictionary:@{@"uid":uid,
                                                                @"uname":uname,
                                                                @"token":token}] autorelease];
            successHandler(json);
            return;
        }
    }
    DLog(@"登录失败：%@", json);
    failHandler(json);
}

#pragma mark - play control

- (void)fetchPlaylist:(Douban_playlist_type)playlist_type
{
    NSString *type;
    switch (playlist_type) {
        case Douban_playlist_type_new:
            type = DOUBANFM_PLAYLIST_TYPE_NEW;
            break;
            
        case Douban_playlist_type_switch:
            type = DOUBANFM_PLAYLIST_TYPE_SWITCH;
            break;
            
        case Douban_playlist_type_end:
            type = DOUBANFM_PLAYLIST_TYPE_END;
            break;
            
        case Douban_playlist_type_redHeart:
            type = DOUBANFM_PLAYLIST_TYPE_RED_HEART;
            break;
            
        case Douban_playlist_type_unRedHeart:
            type = DOUBANFM_PLAYLIST_TYPE_UNRED_HEART;
            break;
            
        default:
            break;
    }
    
    NSString *sid = self.currentSong.songId?self.currentSong.songId:@"";
    double pt = self.currentTime;
    NSString *channel = self.currentChannel?self.currentChannel.channelId:DOUBANFM_LIKED_CHANNEL;
    self.currentChannel = self.currentChannel;
    NSString *url = [NSString stringWithFormat:DOUBANFM_PLAYLIST_URL, type, sid, channel, pt];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
    NSDictionary *response = [DoubanRequest syncRequestWithRequest:request];
    if ([response isKindOfClass:[NSDictionary class]]) {
        if ([response objectForKey:@"logout"]) {
            DLog(@"退出了！！！");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"didLogout" object:nil];
            return;
        }
        if (playlist_type == Douban_playlist_type_new || playlist_type == Douban_playlist_type_switch) {
            self.playlist = [response objectForKey:@"song"];
        }
    }
}

- (void)startPlay
{
    [self fetchPlaylist:Douban_playlist_type_new];
    self.currentIndex = 0;
    [self loadAndPlayNext];
}

- (void)switchPlaylist
{
    [self fetchPlaylist:Douban_playlist_type_switch];
    self.currentIndex = 0;
    [self loadAndPlayNext];
}

- (void)redHeart
{
    [self fetchPlaylist:Douban_playlist_type_redHeart];
    self.currentSong.liked = YES;
    DLog(@"%@ 的 %@--加了红心", self.currentSong.artist, self.currentSong.title);
    [[DoubanService instance].likedSongs addObject:self.currentSong];
    self.likedSongs = self.likedSongs;
    [self cacheSong];
}

- (void)unRedHeart
{
    [self fetchPlaylist:Douban_playlist_type_unRedHeart];
    self.currentSong.liked = NO;
    DLog(@"%@ 的 %@--取消了红心", self.currentSong.artist, self.currentSong.title);
    [self removeCachedSong:self.currentSong.songId];
}

- (void)playDidEnd
{
    if (self.player.rate == 0.f) {
        [self fetchPlaylist:Douban_playlist_type_end];
        DLog(@"%@ 的 %@--播放结束", self.currentSong.artist, self.currentSong.title);
        [self loadAndPlayNext];
    }
}

#pragma mark - play

- (void)playSongAtIndex:(NSInteger)index
{
    self.currentIndex = index;
    [self loadAndPlayNext];
}

- (void)playLocalSongBySid:(NSString *)sid
{
    self.currentSong = [self selectBySongId:sid];
    
    NSURL *assetURL = [NSURL fileURLWithPath:[DoubanFMUtilities filePathWithSid:sid]];
    AVURLAsset *asset = [AVAsset assetWithURL:assetURL];
    NSArray *assetKeysToLoadAndTest = [NSArray arrayWithObjects:@"playable", @"hasProtectedContent", @"tracks", @"duration", nil];
    [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
        });
    }];
}

- (void)loadAndPlayNext
{
    if (self.currentIndex > playlist.count - 1) {
        [self switchPlaylist];
        return;
    }
    
    NSDictionary *songDic = playlist[self.currentIndex];
    self.currentSong = [[[DoubanSong alloc] init] autorelease];
    self.currentSong.remotePath = [songDic objectForKey:@"url"];
    self.currentSong.songId = [songDic objectForKey:@"sid"];
    self.currentSong.artist = [songDic objectForKey:@"artist"];
    self.currentSong.title = [songDic objectForKey:@"title"];
    self.currentSong.liked = [[songDic objectForKey:@"like"] boolValue];
    self.currentSong.picture = [songDic objectForKey:@"picture"];
    self.currentIndex++;
    
    DLog(@"播放地址：%@", self.currentSong.remotePath);
    
    DoubanSong *song = [self selectBySongId:self.currentSong.songId];
    if (song) {
        song.remotePath = self.currentSong.remotePath;
    }
    
    NSURL *assetURL;
    if ([self isCachedSong:self.currentSong.songId]) {
        assetURL = [NSURL fileURLWithPath:[DoubanFMUtilities filePathWithSid:self.currentSong.songId]];
    } else {
        assetURL = [NSURL URLWithString:self.currentSong.remotePath];
        if (self.currentSong.liked) {
            [self cacheSong];
        }
    }
    AVURLAsset *asset = [AVAsset assetWithURL:assetURL];
	NSArray *assetKeysToLoadAndTest = [NSArray arrayWithObjects:@"playable", @"hasProtectedContent", @"tracks", @"duration", nil];
	[asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
		});
	}];
}

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys
{
	for (NSString *key in keys) {
		NSError *error = nil;
		if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
            [self handleCannotPlay];
            return;
        }
	}
	if (![asset isPlayable] || [asset hasProtectedContent]) {
        [self handleCannotPlay];
        return;
    }
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
	[self.player replaceCurrentItemWithPlayerItem:playerItem];
	[self setTimeObserverToken:[player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        self.currentTime = CMTimeGetSeconds([self.player currentTime]);
	}]];
}

- (void)handleCannotPlay
{
    DLog(@"%@ 的 %@--无法播放", self.currentSong.artist, self.currentSong.title);
    [self loadAndPlayNext];
}

- (double)duration
{
	AVPlayerItem *playerItem = [self.player currentItem];
	if ([playerItem status] == AVPlayerItemStatusReadyToPlay)
		return CMTimeGetSeconds([[playerItem asset] duration]);
	else
		return 0.f;
}

- (void)seekToTime:(double)time
{
	[self.player seekToTime:CMTimeMakeWithSeconds(time, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark - channels

- (NSArray *)fetchChannels
{
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:DOUBANFM_CHANNELS_URL]] autorelease];
    NSDictionary *response = [DoubanRequest syncRequestWithRequest:request];
    if ([response isKindOfClass:[NSDictionary class]]) {
        NSArray *groups = [response objectForKey:@"groups"];
        for (NSDictionary *group in groups) {
            NSMutableArray *channelModels = [[NSMutableArray alloc] init];
            NSArray *channels = [group objectForKey:@"chls"];
            for (NSDictionary *node in channels) {
                DoubanChannel *channel = [[DoubanChannel alloc] init];
                channel.channelId = [[node objectForKey:@"id"] stringValue];
                channel.name = [node objectForKey:@"name"];
                channel.cover = [node objectForKey:@"cover"];
                channel.intro = [node objectForKey:@"intro"];
                channel.songCount = [[node objectForKey:@"song_num"] intValue];
                channel.collected = [node objectForKey:@"collected"];
                [channelModels addObject:channel];
                if ([channel.channelId isEqualToString:DOUBANFM_LIKED_CHANNEL]) {
                    self.currentChannel = channel;
                }
                [channel release];
            }
            [group setValue:channelModels forKey:@"chls"];
            [channelModels release];
        }
        return groups;
    }
    return nil;
}

- (void)switchToChannel:(DoubanChannel *)channel
{
    self.currentChannel = channel;
    [self startPlay];
}

#pragma mark - like

- (void)fetchLikedSongs
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://douban.fm"]];
    NSString *ck = @"";
    NSString *spbid = @"";
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:@"ck"]) {
            ck = [self getStringFromCookieValue:cookie.value];
        }
        if ([cookie.name isEqualToString:@"bid"]) {
            spbid = [@"%3A%3A" stringByAppendingString:[self getStringFromCookieValue:cookie.value]];
        }
    }
    NSString *url = [NSString stringWithFormat:DOUBANFM_LIKED_URL, ck, spbid, 0];
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
    [request addValue:@"http://douban.fm/mine" forHTTPHeaderField:@"Referer"];
    
    NSDictionary *response = [DoubanRequest syncRequestWithRequest:request];
    
    DoubanLiked *dl = [[[DoubanLiked alloc] init] autorelease];
    
    NSUInteger total = [[response objectForKey:@"total"] unsignedIntegerValue];//douban的total不准，实际值小于这个
    NSMutableArray *songs = [[NSMutableArray alloc] initWithArray:[response objectForKey:@"songs"]];
    
    int i = (int)songs.count;
    while (i<total) {
        NSString *url = [NSString stringWithFormat:DOUBANFM_LIKED_URL, ck, spbid, i];
        [request setURL:[NSURL URLWithString:url]];
        NSDictionary *response = [DoubanRequest syncRequestWithRequest:request];
        int count = (int)[(NSArray *)[response objectForKey:@"songs"] count];
        if (count == 0) {
            break;
        }
        i += count;
        [songs addObjectsFromArray:[response objectForKey:@"songs"]];
    }
    
    DLog(@"\n获取到红心歌曲共---%d---\n", i);
    
    NSMutableArray *songModels = [[NSMutableArray alloc] init];
    for (NSDictionary *node in songs) {
        DoubanSong *song = [[DoubanSong alloc] init];
        song.artist = [node objectForKey:@"artist"];
        song.songId = [node objectForKey:@"id"];
        song.liked = [[node objectForKey:@"liked"] boolValue];
        song.path = [node objectForKey:@"path"];
        song.picture = [node objectForKey:@"picture"];
        song.title = [node objectForKey:@"title"];
        song.cached = [self isCachedSong:song.songId];
        [songModels addObject:song];
        [song release];
    }
    [songs release];
    dl.songs = songModels;
    [songModels release];
    
    if (total > 0) {
        self.likedSongs = songModels;
    }
}

- (NSMutableArray *)likedSongs
{
    if (!likedSongs) {
        [self fetchLikedSongs];
    }
    return [[likedSongs retain] autorelease];
}

- (void)setLikedSongs:(NSMutableArray *)_likedSongs
{
    [likedSongs release];
    likedSongs = [_likedSongs retain];
    
    [self syncLikedSongs];
}

- (void)syncLikedSongs
{
    DoubanLiked *dl = [[DoubanLiked alloc] init];
    dl.songs = self.likedSongs;
    [DoubanFMUtilities write:dl fileName:LIKED_SONGS_FILE_NAME];
    [dl release];
}

- (void)like:(NSString *)sid Action:(BOOL)action
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://douban.fm"]];
    NSString *ck = @"";
    for (NSHTTPCookie *cookie in cookies) {
        if ([cookie.name isEqualToString:@"ck"]) {
            ck = [self getStringFromCookieValue:cookie.value];
        }
    }
    NSString *url = [NSString stringWithFormat:DOUBANFM_LIKE_ACTION_URL, sid];
    [[DoubanRequest requestWithURL:url httpMethod:@"POST" params:@{@"action":action?@"y":@"n", @"ck":ck} delegate:self] connect];
}

#pragma mark - cache

- (void)cacheSong
{
    if ([self isCachedSong:self.currentSong.songId]) {
        return;
    }
    
    NSURL *assetURL = [NSURL URLWithString:self.currentSong.remotePath];
    [[DoubanDownloader instance] downloadURL:assetURL completionHandler:^(BOOL failed) {
        if (failed) {
            [self removeCachedSong:self.currentSong.songId];
        } else {
            DoubanSong *song = [self selectBySongId:self.currentSong.songId];
            if (song) {
                song.cached = YES;
                self.likedSongs = self.likedSongs;
            }
        }
    }];
}

- (BOOL)isCachedSong:(NSString *)sid
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[DoubanFMUtilities filePathWithSid:sid] isDirectory:NULL];
}

- (void)removeCachedSong:(NSString *)sid
{
    if ([self isCachedSong:sid]) {
        [[NSFileManager defaultManager] removeItemAtPath:[DoubanFMUtilities filePathWithSid:sid] error:NULL];
    }
}

- (void)revealInFinderBySongId:(NSString *)sid
{
    NSString *path = [DoubanFMUtilities filePathWithSid:sid];
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:nil];
}

#pragma mark - helper

- (NSString *)getStringFromCookieValue:(NSString *)cookieValue
{
    return [cookieValue substringWithRange:NSMakeRange(1, cookieValue.length-2)];
}

- (void)storeCookies
{
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://douban.fm"]];
    DLog(@"%@", cookies);
    [DoubanFMUtilities write:cookies fileName:COOKIES_FILE_NAME];
}

- (DoubanSong *)selectBySongId:(NSString *)sid
{
    for (DoubanSong *song in self.likedSongs) {
        if ([song.songId isEqualToString:sid]) {
            return song;
        }
    }
    return nil;
}

- (NSString *)getSidFromUrl:(NSString *)url
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+" options:0 error:NULL];
    if (regex) {
        NSTextCheckingResult *firstMatch = [regex firstMatchInString:url options:0 range:NSMakeRange(0, [url length])];
        if (firstMatch) {
            NSRange resultRange = [firstMatch rangeAtIndex:0];
            return [url substringWithRange:resultRange];
        }
    }
    return nil;
}

#pragma mark - DoubanRequest delegate

- (void)request:(DoubanRequest *)request didFailWithError:(NSError *)error
{
    DLog(@"红心操作失败！！！");
}

- (void)request:(DoubanRequest *)request didFinishLoadingWithResult:(id)result
{
    if ([result isEqualToString:@"y"]) {
        DLog(@"红心操作成功！！！");
        NSString *sid = [self getSidFromUrl:request.url];
        if ([[request.params objectForKey:@"action"] isEqualToString:@"y"]) {
            DoubanSong *song = [self selectBySongId:sid];
            song.liked = YES;
        } else if ([[request.params objectForKey:@"action"] isEqualToString:@"n"]) {
            DoubanSong *song = [self selectBySongId:sid];
            song.liked = NO;
        }
        self.likedSongs = self.likedSongs;
    } else {
        DLog(@"红心操作失败！！！");
    }
}

@end