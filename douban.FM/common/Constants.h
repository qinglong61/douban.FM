//
//  Constants.h
//  douban.FM
//
//  Created by qinglun.duan on 14-5-4.
//  Copyright (c) 2014年 com.pwrd. All rights reserved.
//

#ifndef douban_FM_Constants_h
#define douban_FM_Constants_h

#define CACHES_DIRECTORY [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define LIKED_SONGS_FILE_NAME                   @"likedSongs"
#define USER_FILE_NAME                          @"doubanUser"
#define COOKIES_FILE_NAME                       @"doubanFMCookies"
#define MUSIC_CACHE_FOLDER                      @"musics"
#define STORE_FOLDER                            @"MyDoubanFM"

#define CLIENT_ID                               @"02646d3fb69a52ff072d47bf23cef8fd"
#define CLIENT_SECRET                           @"cde5d61429abcd7c"

#define DOUBAN_LOGIN_URL                        @"https://www.douban.com/service/auth2/token"
#define DOUBAN_LOGIN_HANDLE_URL                 @"http://douban.fm/j/explore/get_login_chls"

#define DOUBANFM_CHANNELS_URL                   @"https://api.douban.com/v2/fm/app_channels?alt=json&apikey=02646d3fb69a52ff072d47bf23cef8fd"
#define DOUBANFM_LIKED_CHANNEL                  @"-3"

#define DOUBANFM_PLAYLIST_URL                   @"http://douban.fm/j/mine/playlist?type=%@&sid=%@&channel=%@&pt=%f&from=mainsite"
#define DOUBANFM_PLAYLIST_TYPE_NEW              @"n"
#define DOUBANFM_PLAYLIST_TYPE_SWITCH           @"s"
#define DOUBANFM_PLAYLIST_TYPE_END              @"e"
#define DOUBANFM_PLAYLIST_TYPE_RED_HEART        @"r"
#define DOUBANFM_PLAYLIST_TYPE_UNRED_HEART      @"u"

#define DOUBANFM_LIKED_URL                      @"http://douban.fm/j/play_record?ck=%@&spbid=%@&type=liked&start=%d"
#define DOUBANFM_LIKE_ACTION_URL                @"http://douban.fm/j/song/%@/interest"

#endif
