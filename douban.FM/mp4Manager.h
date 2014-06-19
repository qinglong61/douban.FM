//
//  Mp4Manager.h
//  immt
//
//  Created by qinglun.duan on 13-3-25.
//  Copyright (c) 2013年 laohu.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Mp4Manager : NSObject <UIWebViewDelegate>

+ (id)sharedMp4Manager;
- (void)analysisMP4src:(NSDictionary *)dic play:(BOOL)isPlay;

@end
