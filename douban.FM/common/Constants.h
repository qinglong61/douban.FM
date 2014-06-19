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

#define LIKED_SONGS_FILE_NAME   @"likedSongs"
#define COOKIES_FILE_NAME       @"doubanFMCookies"
#define MUSIC_CACHE_FOLDER      @"musics"
#define STORE_FOLDER            @"MyDoubanFM"

#define CLIENT_ID               @"02646d3fb69a52ff072d47bf23cef8fd"
#define CLIENT_SECRET           @"cde5d61429abcd7c"

#define DOUBANFM_LIKED_URL      @"http://douban.fm/j/play_record?ck=%@&spbid=%@&type=liked&start=%d"

#define DOUBAN_LOGIN_URL        @"https://www.douban.com/service/auth2/token"
#define DOUBAN_PLAYLIST_URL     @"https://api.douban.com/v2/fm/playlist?alt=json&apikey=%@&app_name=radio_iphone&channel=0&client=s%3Amobile%7Cy%3AiOS%207.1%7Cf%3A98%7Cd%3Aa23e8be448dce260b668fe0ddd595c472a808441%7Ce%3AiPod5%2C1&formats=aac&kbps=64&pt=0.0&type=n&udid=a23e8be448dce260b668fe0ddd595c472a808441&version=98"

#endif
