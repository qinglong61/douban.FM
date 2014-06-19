//
//  DoubanService.h
//  douban.FM
//
//  Created by qinglun.duan on 14-3-27.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#import "DoubanUser.h"
#import <AVFoundation/AVFoundation.h>
#import "Douban.h"
#import "DoubanRequest.h"

@interface DoubanService : NSObject <DoubanRequestDelegate>

@property (nonatomic, retain) NSMutableArray *likedSongs;
@property (nonatomic, retain) DoubanUser *user;
@property (nonatomic, retain) DoubanSong *currentSong;
@property (nonatomic, retain) DoubanChannel *currentChannel;
@property (nonatomic, retain) NSArray *playlist;
@property (nonatomic, retain) AVPlayer *player;
@property (nonatomic, retain) id timeObserverToken;
@property (nonatomic, assign) double currentTime;
@property (nonatomic, assign) NSUInteger currentIndex;

+ (DoubanService *)instance;

- (NSArray *)fetchChannels;
- (void)switchToChannel:(DoubanChannel *)channel;

- (void)fetchLikedSongs;
- (void)syncLikedSongs;
- (void)removeCachedSong:(NSString *)sid;
- (void)revealInFinderBySongId:(NSString *)sid;

- (BOOL)isLogin;
- (void)loginWithEmail:(NSString *)email password:(NSString *)passwd SuccessHandler:(void (^)(NSDictionary *successInfo))successHandler failHandler:(void (^)(NSDictionary *failInfo))failHandler;

- (void)startPlay;
- (void)switchPlaylist;
- (void)redHeart;
- (void)unRedHeart;

- (void)like:(NSString *)sid Action:(BOOL)action;

- (void)playSongAtIndex:(NSInteger)index;
- (void)playLocalSongBySid:(NSString *)sid;
- (double)duration;
- (void)seekToTime:(double)time;

@end
